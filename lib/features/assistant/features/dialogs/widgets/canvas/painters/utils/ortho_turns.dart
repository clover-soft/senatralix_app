import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Унифицированный поворот между ортогональными отрезками `a -> b`.
///
/// Описание параметров:
/// - [path] — целевой путь, в который добавляются линии/дуги поворота (модифицируется).
/// - [a] — начальная точка поворота (конец предыдущего сегмента), в пикселях.
/// - [b] — конечная точка следующего сегмента после поворота, в пикселях.
/// - [radius] — радиус скругления угла:
///   - `> 0` — строится дуга четверти окружности между осями (скруглённый поворот);
///   - `== 0` — строится строгий прямой угол 90° (две ортогональные линии, без дуги).
/// - [minSegment] — минимальная допустимая длина прямого сегмента. Если рассчитанный
///   участок меньше, он принудительно удлиняется до [minSegment] для визуальной устойчивости
///   (предотвращение артефактов при очень коротких отрезках).
///
/// Поведение:
/// - Если отрезок `a->b` уже ортогонален (совпадает по X или Y), рисуется прямая
///   с учётом [minSegment].
/// - Если требуется смена направления по X и Y, используется строгий угол или дуга
///   по правилам [radius].
void addOrthoTurn(
  Path path,
  Offset a,
  Offset b, {
  required double radius,
  required double minSegment,
  bool enableLog = true,
  bool? verticalFirst, // если задан, принудительно задаёт порядок: true => V→H, false => H→V
}) {
  final ax = a.dx, ay = a.dy;
  final bx = b.dx, by = b.dy;
  final dx = bx - ax;
  final dy = by - ay;
  final sx = dx >= 0 ? 1.0 : -1.0;
  final sy = dy >= 0 ? 1.0 : -1.0;
  bool useHFirst = dx.abs() >= dy.abs();
  if (verticalFirst != null) {
    useHFirst = !verticalFirst;
  }
  if (kDebugMode) {
    // Для скругления это всегда внутренний филет относительно угла
    final turnZ = (useHFirst ? sx * sy : -sx * sy);
    final turnDir = turnZ > 0 ? 'left' : 'right';
    debugPrint('[OrthoFillet] type=fillet-inner  order=${useHFirst ? 'H→V' : 'V→H'}  turn=$turnDir');
  }
  if (useHFirst) {
    final pH = Offset(ax + sx * math.min(radius, dx.abs()), ay);
    path.lineTo(pH.dx, pH.dy);
    final rect = Rect.fromCircle(
      center: Offset(pH.dx, pH.dy + sy * radius),
      radius: radius,
    );
    final startAngle = sy > 0 ? -math.pi / 2 : math.pi / 2;
    final sweepAngle = sx > 0 ? math.pi / 2 : -math.pi / 2;
    path.addArc(rect, startAngle, sweepAngle);
    path.lineTo(bx, by);
  } else {
    final pV = Offset(ax, ay + sy * math.min(radius, dy.abs()));
    path.lineTo(pV.dx, pV.dy);
    final rect = Rect.fromCircle(
      center: Offset(pV.dx + sx * radius, pV.dy),
      radius: radius,
    );
    final startAngle = sx > 0 ? math.pi : 0.0;
    final sweepAngle = sy > 0 ? math.pi / 2 : -math.pi / 2;
    path.addArc(rect, startAngle, sweepAngle);
    path.lineTo(bx, by);
  }
}

/// Скругление между двумя ортогональными отрезками, заданными четырьмя точками
/// A1->A2 (входящий), B1->B2 (исходящий). Предполагается, что A2 и B1 — угол (совпадают).
/// Функция сама определяет порядок (V→H / H→V) и поворот (left/right), строит точки a/b
/// на расстоянии радиуса от угла и рисует четверть окружности вокруг угла.
void addOrthoFilletFromSegments(
  Path path, {
  required Offset inStart, // A1
  required Offset inEnd, // A2 = corner
  required Offset outStart, // B1 = corner
  required Offset outEnd, // B2
  required double radius,
  required double minSegment,
  bool enableLog = true,
}) {
  final corner = inEnd; // предполагаем inEnd == outStart
  // Единичные направления (по осям)
  final inVec = Offset(
    (inEnd.dx - inStart.dx).sign,
    (inEnd.dy - inStart.dy).sign,
  );
  final outVec = Offset(
    (outEnd.dx - outStart.dx).sign,
    (outEnd.dy - outStart.dy).sign,
  );
  final incomingVertical = inVec.dx == 0 && inVec.dy != 0;
  final incomingHorizontal = inVec.dy == 0 && inVec.dx != 0;
  final outgoingVertical = outVec.dx == 0 && outVec.dy != 0;
  final outgoingHorizontal = outVec.dy == 0 && outVec.dx != 0;

  if (!(incomingVertical || incomingHorizontal) ||
      !(outgoingVertical || outgoingHorizontal) ||
      (incomingVertical == outgoingVertical)) {
    // Неортогонально — доводим до угла и выходим
    path.lineTo(corner.dx, corner.dy);
    return;
  }

  // Доступные длины и локальный радиус
  final availableIn = incomingVertical
      ? (corner.dy - inStart.dy).abs()
      : (corner.dx - inStart.dx).abs();
  final availableOut = outgoingVertical
      ? (outEnd.dy - corner.dy).abs()
      : (outEnd.dx - corner.dx).abs();
  final localR = [radius, availableIn, availableOut]
      .reduce((a, b) => a < b ? a : b);
  if (localR <= 0) {
    path.lineTo(corner.dx, corner.dy);
    return;
  }

  // Точки a/b на расстоянии localR от угла
  late final Offset a;
  late final Offset b;
  if (incomingVertical && outgoingHorizontal) {
    a = Offset(corner.dx, corner.dy - inVec.dy * localR);
    b = Offset(corner.dx + outVec.dx * localR, corner.dy);
  } else {
    // incomingHorizontal && outgoingVertical
    a = Offset(corner.dx - inVec.dx * localR, corner.dy);
    b = Offset(corner.dx, corner.dy + outVec.dy * localR);
  }

  // Доводим прямую до a
  path.lineTo(a.dx, a.dy);

  // Поворот (лево/право) через cross z
  final crossZ = inVec.dx * outVec.dy - inVec.dy * outVec.dx;
  final turnLeft = crossZ > 0;

  // Определяем начальный угол по позиции a относительно центра corner
  double startAngle;
  if ((a.dx - corner.dx).abs() < 1e-6 && a.dy < corner.dy) {
    startAngle = -math.pi / 2; // вверх
  } else if ((a.dx - corner.dx).abs() < 1e-6 && a.dy > corner.dy) {
    startAngle = math.pi / 2; // вниз
  } else if (a.dx > corner.dx && (a.dy - corner.dy).abs() < 1e-6) {
    startAngle = 0.0; // вправо
  } else {
    startAngle = math.pi; // влево
  }

  // В Flutter положительный sweep — по часовой
  final sweep = turnLeft ? -math.pi / 2 : math.pi / 2;
  final rect = Rect.fromCircle(center: corner, radius: localR);
  path.arcTo(rect, startAngle, sweep, false);
  // Фиксируем окончание дуги строго в b
  path.lineTo(b.dx, b.dy);

  if (enableLog && kDebugMode) {
    final side = (outgoingHorizontal
            ? (outVec.dx > 0 ? 'R' : 'L')
            : (inVec.dx > 0 ? 'R' : 'L'));
    debugPrint('[Fillet] side=$side turn=${turnLeft ? 'left' : 'right'} R=${localR.toStringAsFixed(1)}');
  }
}
// Прямая с проверкой минимальной длины (для устойчивости)
void _lineOrSegment(
  Path path,
  Offset a,
  Offset b, {
  required bool isVertical,
  required double minSegment,
}) {
  final dx = (b.dx - a.dx).abs();
  final dy = (b.dy - a.dy).abs();
  if (isVertical) {
    final l = dy < minSegment
        ? (b.dy > a.dy ? a.dy + minSegment : a.dy - minSegment)
        : b.dy;
    path.lineTo(a.dx, l);
  } else {
    final l = dx < minSegment
        ? (b.dx > a.dx ? a.dx + minSegment : a.dx - minSegment)
        : b.dx;
    path.lineTo(l, a.dy);
  }
}

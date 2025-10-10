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
}) {
  final ax = a.dx, ay = a.dy;
  final bx = b.dx, by = b.dy;
  final dx = bx - ax;
  final dy = by - ay;
  // Предварительный лог: базовые координаты и параметры
  if (enableLog && kDebugMode) {
    debugPrint(
      '[OrthoTurn] A=(${ax.toStringAsFixed(1)}, ${ay.toStringAsFixed(1)})  B=(${bx.toStringAsFixed(1)}, ${by.toStringAsFixed(1)})  radius=${radius.toStringAsFixed(1)}  minSeg=${minSegment.toStringAsFixed(1)}',
    );
  }

  // Если отрезок уже ортогонален (по X или по Y) — просто провести прямую с доп. устойчивостью
  if (ax == bx || ay == by) {
    _lineOrSegment(path, a, b, isVertical: ax == bx, minSegment: minSegment);
    if (enableLog && kDebugMode) {
      debugPrint('[OrthoTurn] type=linear (без поворота, ортогонально)');
    }
    return;
  }

  // Нужен поворот на 90° (смена направления по обеим осям)
  if (radius <= 0) {
    // Строгий угол: порядок зависит от преобладающей компоненты
    final useHFirst = dx.abs() >= dy.abs();
    if (enableLog && kDebugMode) {
      // Направления для определения влево/вправо через псевдоскаляр (2D cross z)
      final sx = dx >= 0 ? 1.0 : -1.0;
      final sy = dy >= 0 ? 1.0 : -1.0;
      final turnZ = (useHFirst ? sx * sy : -sx * sy); // знак поворота
      final turnDir = turnZ > 0 ? 'left' : 'right';
      debugPrint('[OrthoTurn] type=hard-90  order=${useHFirst ? 'H→V' : 'V→H'}  turn=$turnDir');
    }
    if (useHFirst) {
      // Сначала горизонталь до (bx, ay), затем вертикаль до (bx, by)
      _lineOrSegment(
        path,
        a,
        Offset(bx, ay),
        isVertical: false,
        minSegment: minSegment,
      );
      _lineOrSegment(
        path,
        Offset(bx, ay),
        b,
        isVertical: true,
        minSegment: minSegment,
      );
    } else {
      // Сначала вертикаль до (ax, by), затем горизонталь до (bx, by)
      _lineOrSegment(
        path,
        a,
        Offset(ax, by),
        isVertical: true,
        minSegment: minSegment,
      );
      _lineOrSegment(
        path,
        Offset(ax, by),
        b,
        isVertical: false,
        minSegment: minSegment,
      );
    }
    return;
  }

  // Скруглённый угол (четверть окружности)
  final sx = dx >= 0 ? 1.0 : -1.0;
  final sy = dy >= 0 ? 1.0 : -1.0;
  final useHFirst = dx.abs() >= dy.abs();
  if (kDebugMode) {
    // Для скругления это всегда внутренний филет относительно угла
    final turnZ = (useHFirst ? sx * sy : -sx * sy);
    final turnDir = turnZ > 0 ? 'left' : 'right';
    debugPrint('[OrthoTurn] type=fillet-inner  order=${useHFirst ? 'H→V' : 'V→H'}  turn=$turnDir');
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

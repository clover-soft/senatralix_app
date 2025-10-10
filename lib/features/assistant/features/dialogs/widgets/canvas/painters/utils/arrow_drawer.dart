import 'package:flutter/material.dart';

/// Рисует треугольную стрелку, ориентированную по вектору касательной.
/// tipPoint — кончик стрелки (острие),
/// tangent — вектор касательной в направлении «вперёд» (от основания к кончику),
/// base — ширина основания, height — высота треугольника.
void drawTriangleArrowAlong({
  required Canvas canvas,
  required Offset tipPoint,
  required Offset tangent,
  required double base,
  required double height,
  required bool filled,
  required Paint stroke,
  required Paint fill,
}) {
  // Нормализуем направление, берём обратное (от кончика к основанию)
  final len = tangent.distance == 0 ? 1.0 : tangent.distance;
  final ux = tangent.dx / len;
  final uy = tangent.dy / len;
  final back = Offset(-ux, -uy);

  // Центр основания отстоит от кончика на height по вектору back
  final baseCenter = Offset(
    tipPoint.dx + back.dx * height,
    tipPoint.dy + back.dy * height,
  );
  // Перпендикуляр (влево относительно направления вперёд)
  final perp = Offset(-uy, ux);
  final half = base / 2;
  final baseLeft = Offset(
    baseCenter.dx + perp.dx * half,
    baseCenter.dy + perp.dy * half,
  );
  final baseRight = Offset(
    baseCenter.dx - perp.dx * half,
    baseCenter.dy - perp.dy * half,
  );

  final path = Path()
    ..moveTo(tipPoint.dx, tipPoint.dy)
    ..lineTo(baseRight.dx, baseRight.dy)
    ..lineTo(baseLeft.dx, baseLeft.dy)
    ..close();

  // Всегда рисуем залитый треугольник
  canvas.drawPath(path, fill);
}

/// Возвращает координату середины основания треугольной стрелки вниз.
Offset computeArrowBaseMidDown({
  required Offset tipPoint,
  required double height,
}) {
  final baseY = tipPoint.dy - height;
  return Offset(tipPoint.dx, baseY);
}

/// Возвращает координату середины основания треугольной стрелки,
/// ориентированной по касательной (tipPoint, tangent, height).
Offset computeArrowBaseMidAlong({
  required Offset tipPoint,
  required Offset tangent,
  required double height,
}) {
  final len = tangent.distance == 0 ? 1.0 : tangent.distance;
  final ux = tangent.dx / len;
  final uy = tangent.dy / len;
  final back = Offset(-ux, -uy);
  return Offset(
    tipPoint.dx + back.dx * height,
    tipPoint.dy + back.dy * height,
  );
}

/// Рисует треугольную стрелку, ориентированную строго вниз (как в ортогональных рёбрах).
/// tipPoint — кончик стрелки (на входе сверху),
/// base — ширина основания, height — высота треугольника.
/// Если attachAtEdgeMid=true, дорисовывает короткую линию стыковки по центру основания.
void drawTriangleArrowDown({
  required Canvas canvas,
  required Offset tipPoint,
  required double base,
  required double height,
  required bool filled,
  required Paint stroke,
  required Paint fill,
}) {
  final baseHalf = base / 2;
  final tip = tipPoint;
  final baseY = tip.dy - height;
  final baseLeft = Offset(tip.dx - baseHalf, baseY);
  final baseRight = Offset(tip.dx + baseHalf, baseY);

  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(baseRight.dx, baseRight.dy)
    ..lineTo(baseLeft.dx, baseLeft.dy)
    ..close();

  // Всегда рисуем залитый треугольник
  canvas.drawPath(path, fill);
}

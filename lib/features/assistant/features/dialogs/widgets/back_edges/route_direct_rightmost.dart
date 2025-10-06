import 'dart:math' as math;
import 'dart:ui';

import 'back_edge_painter_utils.dart';

/// Прямое подключение к правой грани самой правой ноды (без обхода сверху).
/// Строит путь до основания стрелки по вертикальной оси [axisX], затем рисует стрелку в правую грань [toRect].
void drawBackEdgeDirectRightmost({
  required Canvas canvas,
  required Paint edgePaint,
  required Rect fromRect,
  required Rect toRect,
  required double axisX,
  required Color color,
}) {
  const double r = 6.0; // радиус скругления

  // Геометрия конца стрелки: входим в правую грань цели
  final arrowEnd = Offset(toRect.right - 1.0, toRect.center.dy);
  final p0 = Offset(fromRect.right, fromRect.center.dy);

  // Направление стрелки — к правой грани (слева направо)
  final prevForArrow = Offset(arrowEnd.dx + 6.0, arrowEnd.dy);
  final vx = arrowEnd.dx - prevForArrow.dx;
  final vy = arrowEnd.dy - prevForArrow.dy;
  final angle = math.atan2(vy, vx);

  // Траектория до основания стрелки
  final path = Path()
    ..moveTo(p0.dx, p0.dy)
    ..lineTo(axisX - r, p0.dy)
    ..quadraticBezierTo(axisX, p0.dy, axisX, p0.dy + r * (toRect.center.dy >= p0.dy ? 1.0 : -1.0))
    ..lineTo(axisX, toRect.center.dy - r * (toRect.center.dy >= p0.dy ? 1.0 : -1.0))
    ..quadraticBezierTo(axisX, toRect.center.dy, axisX - r, toRect.center.dy);

  // Доводим путь только до основания стрелки и рисуем
  lineToArrowBase(path: path, arrowEnd: arrowEnd, angle: angle, headLen: 12.0);
  canvas.drawPath(path, edgePaint);

  // Рисуем треугольный наконечник
  drawArrowHead(
    canvas: canvas,
    color: color,
    arrowEnd: arrowEnd,
    angle: angle,
    headLen: 12.0,
    headWidth: 10.0,
  );
}

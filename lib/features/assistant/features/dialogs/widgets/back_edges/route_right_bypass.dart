import 'dart:math' as math;
import 'dart:ui';

import 'back_edge_painter_utils.dart';

/// Обход справа: вынос на ось route/axisX, полка сверху на yUp, затем подход к правой грани цели.
void drawBackEdgeRightBypass({
  required Canvas canvas,
  required Paint edgePaint,
  required Rect fromRect,
  required Rect toRect,
  required double axisX,
  required double yUp,
  required Color color,
}) {
  const double r = 6.0;

  final p0 = Offset(fromRect.right, fromRect.center.dy);
  final arrowEnd = Offset(toRect.right - 1.0, toRect.center.dy);

  // Направление стрелки — к правой грани (слева направо)
  final prevForArrow = Offset(arrowEnd.dx + 6.0, arrowEnd.dy);
  final vx = arrowEnd.dx - prevForArrow.dx;
  final vy = arrowEnd.dy - prevForArrow.dy;
  final angle = math.atan2(vy, vx);

  final sUp = yUp >= p0.dy ? 1.0 : -1.0;
  final sDown = arrowEnd.dy >= yUp ? 1.0 : -1.0;
  final xApproach = toRect.right + 20.0;

  final path = Path()
    ..moveTo(p0.dx, p0.dy)
    // вправо до axisX
    ..lineTo(axisX - r, p0.dy)
    ..quadraticBezierTo(axisX, p0.dy, axisX, p0.dy + sUp * r)
    // вертикально к полке yUp
    ..lineTo(axisX, yUp - sUp * r)
    ..quadraticBezierTo(axisX, yUp, axisX - r, yUp)
    // влево к точке подхода у цели
    ..lineTo(xApproach + r, yUp)
    ..quadraticBezierTo(xApproach, yUp, xApproach, yUp + sDown * r)
    // вертикально к уровню цели
    ..lineTo(xApproach, arrowEnd.dy - sDown * r)
    ..quadraticBezierTo(xApproach, arrowEnd.dy, xApproach - r, arrowEnd.dy);

  // Доводим путь до основания стрелки и рисуем
  lineToArrowBase(path: path, arrowEnd: arrowEnd, angle: angle, headLen: 12.0);
  canvas.drawPath(path, edgePaint);

  drawArrowHead(
    canvas: canvas,
    color: color,
    arrowEnd: arrowEnd,
    angle: angle,
    headLen: 12.0,
    headWidth: 10.0,
  );
}

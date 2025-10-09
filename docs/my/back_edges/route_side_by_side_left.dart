import 'dart:math' as math;
import 'dart:ui';

import 'back_edge_painter_utils.dart';

/// Соединение «бок-о-бок слева»:
/// линия из центра левой грани источника в центр правой грани приёмника,
/// наконечник стрелки входит в правую грань приёмника.
void drawBackEdgeSideBySideLeft({
  required Canvas canvas,
  required Paint edgePaint,
  required Rect fromRect,
  required Rect toRect,
  required Color color,
}) {
  // Точки соединения по центрам граней
  final p0 = Offset(fromRect.left, fromRect.center.dy);
  final arrowEnd = Offset(toRect.right - 1.0, toRect.center.dy);

  // Направление стрелки — влево->вправо к правой грани приёмника
  final prevForArrow = Offset(arrowEnd.dx + 6.0, arrowEnd.dy);
  final vx = arrowEnd.dx - prevForArrow.dx;
  final vy = arrowEnd.dy - prevForArrow.dy;
  final angle = math.atan2(vy, vx);

  // Прямая линия до основания стрелки
  final path = Path()..moveTo(p0.dx, p0.dy);
  lineToArrowBase(path: path, arrowEnd: arrowEnd, angle: angle, headLen: 12.0);
  canvas.drawPath(path, edgePaint);

  // Наконечник
  drawArrowHead(
    canvas: canvas,
    color: color,
    arrowEnd: arrowEnd,
    angle: angle,
    headLen: 12.0,
    headWidth: 10.0,
  );
}

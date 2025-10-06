import 'dart:math' as math;
import 'dart:ui';

/// Рисует треугольный наконечник стрелки, направленный под углом [angle] (рад).
/// [angle] — направление вектора от основания к вершине (т.е. куда «смотрит» стрелка).
void drawArrowHead({
  required Canvas canvas,
  required Color color,
  required Offset arrowEnd,
  required double angle,
  double headLen = 12.0,
  double headWidth = 10.0,
}) {
  // Единичный вектор направления
  final ux = math.cos(angle);
  final uy = math.sin(angle);
  // Основание треугольника
  final baseX = arrowEnd.dx - headLen * ux;
  final baseY = arrowEnd.dy - headLen * uy;
  // Перпендикуляр к направлению (влево от направления)
  final px = -uy;
  final py = ux;

  final left = Offset(
    baseX + (headWidth / 2) * px,
    baseY + (headWidth / 2) * py,
  );
  final right = Offset(
    baseX - (headWidth / 2) * px,
    baseY - (headWidth / 2) * py,
  );

  final path = Path()
    ..moveTo(arrowEnd.dx, arrowEnd.dy)
    ..lineTo(left.dx, left.dy)
    ..lineTo(right.dx, right.dy)
    ..close();

  final fillPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, fillPaint);
}

/// Доводит [path] только до основания стрелки (вдоль направления [angle]).
/// Возвращает точку основания (baseX, baseY), чтобы стык был аккуратным.
Offset lineToArrowBase({
  required Path path,
  required Offset arrowEnd,
  required double angle,
  double headLen = 12.0,
}) {
  final ux = math.cos(angle);
  final uy = math.sin(angle);
  final base = Offset(
    arrowEnd.dx - headLen * ux,
    arrowEnd.dy - headLen * uy,
  );
  path.lineTo(base.dx, base.dy);
  return base;
}

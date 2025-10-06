import 'dart:math' as math;
import 'dart:ui';

import 'back_edge_painter_utils.dart';

/// Обход сверху-вправо:
/// 1) Выход из верхней грани источника в точке x = left + 0.75*width, вверх на 20px
/// 2) Поворот вправо и движение до максимально правой оси (правая грань самой правой ноды или правее существующих осей) + 20
/// 3) Подъём/спуск до уровня цели (центр Y цели), учитывая обход других нод по пути (+80 вправо при пересечении)
/// 4) Поворот влево и подход к правой грани цели; вход стрелкой в центр правой грани
void drawBackEdgeTopRightBypass({
  required Canvas canvas,
  required Paint edgePaint,
  required Rect fromRect,
  required Rect toRect,
  required Color color,
  required Rect? allBounds,
  Iterable<Rect> nodeRects = const [],
  double shelfUp = 20.0,
}) {
  const double r = 6.0;

  // Точки выхода
  final exitX = fromRect.left + fromRect.width * 0.75;
  final p0 = Offset(exitX, fromRect.top); // выход с верхней грани
  // Горизонтальная полка для этого маршрута:
  // (строго по ТЗ) поворот направо через 20px от ИСТОЧНИКА
  final double shelfY = fromRect.top - shelfUp; // fromRect.top - 20

  // Вертикальная ось для правого обхода: берём максимум правых граней
  double xAxis = toRect.right + 20.0;
  for (final rct in nodeRects) {
    xAxis = math.max(xAxis, rct.right + 0.0);
  }

  // Целевые уровни по Y
  final double y1 = shelfY;            // полка после выхода из источника (источник.top - 20)
  final double y2 = toRect.top - 25.0; // уровень над приёмником

  // Геометрия стрелки: вход в верхнюю грань приёмника
  final double arrowX = toRect.right - 20.0;
  final Offset arrowEnd = Offset(arrowX, toRect.top + 0.5);
  final double angle = math.pi / 2; // стрелка вниз

  // Строим путь:
  // 1) p0 -> вверх до y1 и поворот вправо r=6
  final path = Path()
    ..moveTo(p0.dx, p0.dy)
    ..lineTo(p0.dx, y1 + r)
    ..quadraticBezierTo(p0.dx, y1, p0.dx + r, y1)
    // 2) вправо до xAxis и поворот вверх r=6
    ..lineTo(xAxis - r, y1)
    ..arcToPoint(Offset(xAxis, y1 - r), radius: const Radius.circular(r), clockwise: false)
    // 3) вверх до y2 и поворот влево r=6
    ..lineTo(xAxis, y2 + r)
    ..arcToPoint(Offset(xAxis - r, y2), radius: const Radius.circular(r), clockwise: false)
    // 4) влево до (arrowX) и поворот вниз r=6
    ..lineTo(arrowX - r, y2)
    ..arcToPoint(Offset(arrowX, y2 + r), radius: const Radius.circular(r), clockwise: true)
    // 5) вниз до верхней грани приёмника - 10
    ..lineTo(arrowX, toRect.top - 10.0);

  // Доводим до основания стрелки и рисуем
  lineToArrowBase(path: path, arrowEnd: arrowEnd, angle: angle, headLen: 12.0);
  canvas.drawPath(path, edgePaint);

  // Наконечник стрелки
  drawArrowHead(
    canvas: canvas,
    color: color,
    arrowEnd: arrowEnd,
    angle: angle,
    headLen: 12.0,
    headWidth: 10.0,
  );
}

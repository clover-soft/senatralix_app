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
  // Горизонтальная полка для этого маршрута — ровно через 20px от источника
  // (по требованию: «поворачивать направо через 20px»)
  final double shelfY = fromRect.top - shelfUp;

  // Базовая правая ось: правая грань самого правого прямоугольника + 20
  double xMax = (allBounds?.right ?? toRect.right) + 20.0;

  // Если по пути справа налево к цели встречаются ноды на уровне цели — расширяем вправо на 80
  bool hasObstacleAtY(double y, double fromX, double toX) {
    for (final rct in nodeRects) {
      if (rct.top <= y && rct.bottom >= y) {
        final overlapsX = rct.left < fromX && rct.right > toX;
        if (overlapsX) return true;
      }
    }
    return false;
  }

  if (hasObstacleAtY(toRect.center.dy, xMax, toRect.right)) {
    xMax += 80.0;
  }

  // Геометрия стрелки: входим в правую грань цели
  final arrowEnd = Offset(toRect.right - 1.0, toRect.center.dy);
  final prevForArrow = Offset(arrowEnd.dx + 6.0, arrowEnd.dy);
  final vx = arrowEnd.dx - prevForArrow.dx;
  final vy = arrowEnd.dy - prevForArrow.dy;
  final angle = math.atan2(vy, vx);

  // Строим путь до основания стрелки:
  // 1) Выход вверх из p0 на 20px до shelfY с мягким скруглением (r=6)
  // 2) Поворот вправо на полку shelfY (r=6)
  // 3) Идём по полке вправо до xMax, затем поворот на вертикаль у xMax (r=6)
  // 4) Вертикально к уровню центра цели и подход к правой грани
  final path = Path()
    ..moveTo(p0.dx, p0.dy)
    // 1) Подъём: p0 -> почти до shelfY
    ..lineTo(p0.dx, shelfY + r)
    // скругление на повороте вправо к полке (четверть окружности r=6)
    ..quadraticBezierTo(p0.dx, shelfY, p0.dx + r, shelfY)
    // 2) Полка: вправо до xMax с дугой r=6 на повороте к вертикали (направление зависит от положения цели)
    ..lineTo(xMax - r, shelfY)
    ..arcToPoint(
      Offset(xMax, shelfY + ((toRect.center.dy >= shelfY) ? r : -r)),
      radius: const Radius.circular(r),
      clockwise: (toRect.center.dy >= shelfY),
    )
    // 3) Вертикально к уровню цели с небольшим скруглением к горизонтали подхода
    ..lineTo(xMax, toRect.center.dy - ((toRect.center.dy >= shelfY) ? r : -r))
    ..quadraticBezierTo(xMax, toRect.center.dy, xMax - r, toRect.center.dy);

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

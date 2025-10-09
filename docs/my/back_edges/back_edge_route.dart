import 'dart:ui';

/// Тип маршрута для обратного ребра
enum BackEdgeRoute {
  /// Источник и приёмник стоят «бок-о-бок»: приёмник сразу справа от источника
  sideBySide,

  /// Источник и приёмник стоят «бок-о-бок», но приёмник слева от источника
  sideBySideLeft,

  /// Обход через верх и вправо (с полкой при наличии препятствий справа у источника или приёмника)
  topRightBypass,
}

/// Детектор способа построения ребра.
/// Возвращает directToRightmost, если целевая нода является крайней справа,
/// иначе — rightBypass.
BackEdgeRoute detectBackEdgeRoute({
  required Rect fromRect,
  required Rect toRect,
  required Rect? allBounds,
  Iterable<Rect> nodeRects = const [],
}) {
  // 1) Бок-о-бок: приёмник сразу справа от источника
  final double dx = toRect.left - fromRect.right;
  final bool verticalOverlap = !(toRect.bottom < fromRect.top || toRect.top > fromRect.bottom);
  // Небольшой зазор/нахлёст по X и есть вертикальное перекрытие
  if (dx >= -2.0 && dx <= 60.0 && verticalOverlap) {
    return BackEdgeRoute.sideBySide;
  }

  // 1b) Бок-о-бок слева: приёмник сразу слева от источника
  final double dxLeft = fromRect.left - toRect.right;
  if (dxLeft >= -2.0 && dxLeft <= 60.0 && verticalOverlap) {
    return BackEdgeRoute.sideBySideLeft;
  }

  // 2) Полка (topRightBypass), если справа от ИСТОЧНИКА или справа от ПРИЁМНИКА есть нода с вертикальным перекрытием
  bool rightOfSource = false;
  bool rightOfTarget = false;
  for (final r in nodeRects) {
    // справа от источника
    if (!rightOfSource && r.left >= fromRect.right - 1) {
      final overlapsYSrc = !(r.bottom < fromRect.top || r.top > fromRect.bottom);
      if (overlapsYSrc) rightOfSource = true;
    }
    // справа от приёмника
    if (!rightOfTarget && r.left >= toRect.right - 1) {
      final overlapsYTgt = !(r.bottom < toRect.top || r.top > toRect.bottom);
      if (overlapsYTgt) rightOfTarget = true;
    }
    if (rightOfSource || rightOfTarget) break;
  }
  if (rightOfSource || rightOfTarget) return BackEdgeRoute.topRightBypass;

  // 3) Иначе — общий случай: обход через верх и вправо
  return BackEdgeRoute.topRightBypass;
}

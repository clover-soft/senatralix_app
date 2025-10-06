import 'dart:ui';

/// Тип маршрута для обратного ребра
enum BackEdgeRoute {
  /// Обход справа с полкой сверху (right bypass)
  rightBypass,

  /// Прямое подключение к правой грани самой правой ноды (без обхода)
  directToRightmost,

  /// Источник и приёмник стоят «бок-о-бок»: приёмник сразу справа от источника
  sideBySide,

  /// Источник и приёмник стоят «бок-о-бок», но приёмник слева от источника
  sideBySideLeft,

  /// Выход сверху на 0.75 ширины, вправо к максимально правой оси,
  /// затем подъём и горизонтальный подход к правой грани приёмника
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

  // 2) Крайняя правая цель — подключаемся напрямую к её правой грани
  final double xRight = toRect.right;
  final bool isRightmostTarget = xRight >= ((allBounds?.right ?? xRight) - 0.5);
  if (isRightmostTarget) return BackEdgeRoute.directToRightmost;

  // 3) Если справа от источника есть нода (с перекрытием по Y), используем обход topRightBypass
  for (final r in nodeRects) {
    if (r.left >= fromRect.right - 1) {
      final overlapsY = !(r.bottom < fromRect.top || r.top > fromRect.bottom);
      if (overlapsY) {
        return BackEdgeRoute.topRightBypass;
      }
    }
  }
  return BackEdgeRoute.rightBypass;
}

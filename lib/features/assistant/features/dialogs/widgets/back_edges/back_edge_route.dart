/// Маршруты отрисовки обратных рёбер
enum BackEdgeRoute {
  /// Обход сверху-вправо (top right bypass)
  topRightBypass,

  /// Параллельный обход сбоку (справа)
  sideBySide,

  /// Параллельный обход сбоку (слева)
  sideBySideLeft,
}

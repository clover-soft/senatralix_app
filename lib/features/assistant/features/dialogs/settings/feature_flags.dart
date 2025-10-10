/// Фич-флаги для управления поведением рендера/раскладки
class FeatureFlags {
  /// Включение отрисовки обратных рёбер
  final bool showBackEdges;

  /// Включение барицентрической сортировки (если поддерживается слоем)
  final bool useBarycentricOrdering;

  /// Логирование работы раскладчика (уровни, ряды, и т.д.)
  final bool logLayout;

  /// Использовать планер обратных рёбер (для Ortho) вместо прямой отрисовки без плана
  final bool useBackEdgesPlanner;

  const FeatureFlags({
    this.showBackEdges = true,
    this.useBarycentricOrdering = true,
    this.logLayout = false,
    this.useBackEdgesPlanner = true,
  });
}

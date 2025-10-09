/// Фич-флаги для управления поведением рендера/раскладки
class FeatureFlags {
  /// Включение отрисовки обратных рёбер
  final bool showBackEdges;

  /// Включение барицентрической сортировки (если поддерживается слоем)
  final bool useBarycentricOrdering;

  const FeatureFlags({
    this.showBackEdges = true,
    this.useBarycentricOrdering = true,
  });
}

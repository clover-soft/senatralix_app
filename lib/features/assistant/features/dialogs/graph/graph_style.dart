import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// Тип раскладки графа
enum GraphLayoutType {
  sugiyamaTopBottom,
  buchheimTopBottom,
}

/// Стиль графа: конфигурация раскладки и стили рёбер
class GraphStyle {
  GraphStyle._({
    required this.layoutType,
    this.nodeSeparation = 20,
    this.levelSeparation = 80,
    this.siblingSeparation = 40,
    this.subtreeSeparation = 60,
    Paint? edgeNextPaint,
    Paint? edgeBranchPaint,
  })  : edgeNextPaint = edgeNextPaint ?? (Paint()..color = Colors.black..strokeWidth = 2),
        edgeBranchPaint = edgeBranchPaint ?? (Paint()..color = const Color(0xFFFF9800)..strokeWidth = 1.6);

  final GraphLayoutType layoutType;

  // Параметры для Sugiyama
  final double nodeSeparation;
  final double levelSeparation;

  // Параметры для Buchheim
  final double siblingSeparation;
  final double subtreeSeparation;

  // Стили рёбер
  final Paint edgeNextPaint;
  final Paint edgeBranchPaint;

  /// Фабрика: Sugiyama сверху-вниз
  factory GraphStyle.sugiyamaTopBottom({
    double nodeSeparation = 20,
    double levelSeparation = 80,
    Paint? edgeNext,
    Paint? edgeBranch,
  }) {
    return GraphStyle._(
      layoutType: GraphLayoutType.sugiyamaTopBottom,
      nodeSeparation: nodeSeparation,
      levelSeparation: levelSeparation,
      edgeNextPaint: edgeNext,
      edgeBranchPaint: edgeBranch,
    );
  }

  /// Фабрика: Buchheim сверху-вниз (rooted tree)
  factory GraphStyle.buchheimTopBottom({
    double siblingSeparation = 40,
    double levelSeparation = 120,
    double subtreeSeparation = 60,
    Paint? edgeNext,
    Paint? edgeBranch,
  }) {
    return GraphStyle._(
      layoutType: GraphLayoutType.buchheimTopBottom,
      siblingSeparation: siblingSeparation,
      levelSeparation: levelSeparation,
      subtreeSeparation: subtreeSeparation,
      edgeNextPaint: edgeNext,
      edgeBranchPaint: edgeBranch,
    );
  }

  /// Скомпонованный алгоритм для GraphView
  Algorithm buildAlgorithm() {
    switch (layoutType) {
      case GraphLayoutType.sugiyamaTopBottom:
        final cfg = SugiyamaConfiguration()
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..nodeSeparation = nodeSeparation.toInt()
          ..levelSeparation = levelSeparation.toInt();
        return SugiyamaAlgorithm(cfg);
      case GraphLayoutType.buchheimTopBottom:
        final cfg = BuchheimWalkerConfiguration()
          ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM
          ..siblingSeparation = siblingSeparation.toInt()
          ..levelSeparation = levelSeparation.toInt()
          ..subtreeSeparation = subtreeSeparation.toInt();
        return BuchheimWalkerAlgorithm(cfg, TreeEdgeRenderer(cfg));
    }
  }
}

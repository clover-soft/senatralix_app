import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// Холст для отображения дерева на базе GraphView.
/// Делает двойной скролл и ограничивает максимальный размер холста через BoxConstraints.loose.
class DialogsTreeCanvas extends StatelessWidget {
  const DialogsTreeCanvas({
    super.key,
    required this.graph,
    required this.algorithm,
    required this.nodeBuilder,
    this.canvasSize = const Size(2400, 1800),
  });

  /// Граф для отображения
  final Graph graph;

  /// Алгоритм раскладки (например, BuchheimWalkerAlgorithm или SugiyamaAlgorithm)
  final Algorithm algorithm;

  /// Фабрика виджета для ноды
  final Widget Function(Node) nodeBuilder;

  /// Размер «холста» (верхняя граница, не жёсткая) — подстраивается через loose-constraints
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(canvasSize),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(1000),
            clipBehavior: Clip.none,
            child: GraphView(
              graph: graph,
              algorithm: algorithm,
              builder: nodeBuilder,
            ),
          ),
        ),
      ),
    );
  }
}

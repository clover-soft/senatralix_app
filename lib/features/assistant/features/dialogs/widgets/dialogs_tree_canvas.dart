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
    this.transformationController,
    this.contentKey,
  });

  /// Граф для отображения
  final Graph graph;

  /// Алгоритм раскладки (например, BuchheimWalkerAlgorithm или SugiyamaAlgorithm)
  final Algorithm algorithm;

  /// Фабрика виджета для ноды
  final Widget Function(Node) nodeBuilder;

  /// Размер «холста» (верхняя граница, не жёсткая) — подстраивается через loose-constraints
  final Size canvasSize;

  /// Внешний контроллер трансформаций (для центрирования/вписывания)
  final TransformationController? transformationController;

  /// Ключ обёртки контента (для измерения размеров графа)
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    final hasNodes = graph.nodes.isNotEmpty;
    return SizedBox.expand(
      child: hasNodes
          ? InteractiveViewer(
              constrained: false,
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(1000),
              clipBehavior: Clip.hardEdge,
              transformationController: transformationController,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return RepaintBoundary(
                    key: contentKey,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: 0,
                        minHeight: 0,
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: GraphView(
                            graph: graph,
                            algorithm: algorithm,
                            builder: nodeBuilder,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Граф ещё не загружен'),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/centered_layered_layout.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/edges_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/back_edges_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/nodes_layer.dart';

class DialogsCenteredCanvas extends StatelessWidget {
  const DialogsCenteredCanvas({
    super.key,
    required this.layout,
    required this.nodeSize,
    required this.buildNode,
    this.transformationController,
    this.contentKey,
    this.showBackEdges = true,
    this.backEdgeColor = const Color(0xFFEA4335),
    this.backEdgeStrokeWidth = 1.8,
  });

  final CenteredLayoutResult layout;
  final Size nodeSize;
  final Widget Function(int stepId, Key? key) buildNode;
  final TransformationController? transformationController;
  final Key? contentKey;
  final bool showBackEdges;
  final Color backEdgeColor;
  final double backEdgeStrokeWidth;

  @override
  Widget build(BuildContext context) {
    final content = RepaintBoundary(
      key: contentKey,
      child: Stack(
        children: [
          // Полотно нужного размера
          SizedBox(
            width: layout.canvasSize.width,
            height: layout.canvasSize.height,
          ),
          // Рёбра next (чёрные)
          EdgesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            edges: layout.nextEdges,
            color: Colors.black,
            strokeWidth: 2,
          ),
          // Рёбра branch (оранжевые)
          EdgesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            edges: layout.branchEdges,
            color: const Color(0xFFFF9800),
            strokeWidth: 1.6,
          ),
          // Обратные рёбра (идущие вверх): рисуем отдельным слоем
          if (showBackEdges)
            BackEdgesLayer(
              positions: layout.positions,
              nodeSize: nodeSize,
              allEdges: [
                ...layout.nextEdges,
                ...layout.branchEdges,
              ],
              color: backEdgeColor,
              strokeWidth: backEdgeStrokeWidth,
            ),
          // Узлы
          NodesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            buildNode: buildNode,
          ),
        ],
      ),
    );

    return SizedBox.expand(
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(4000),
        clipBehavior: Clip.none,
        transformationController: transformationController,
        child: content,
      ),
    );
  }
}

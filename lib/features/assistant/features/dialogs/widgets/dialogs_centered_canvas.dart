import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/centered_layered_layout.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/edges_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/back_edges_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/nodes_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/settings/render_settings.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/settings/feature_flags.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/nodes/dialog_node_factory.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/nodes/node_styles.dart';

class DialogsCenteredCanvas extends StatelessWidget {
  const DialogsCenteredCanvas({
    super.key,
    required this.layout,
    required this.nodeSize,
    this.buildNode,
    this.transformationController,
    this.contentKey,
    this.renderSettings = const RenderSettings(),
    this.flags = const FeatureFlags(),
    this.steps,
    this.factory = const DialogNodeFactory(),
    this.nodeStyles = const NodeStyles(),
    this.onNodeTap,
    this.onNodeOpenMenu,
    this.onNodeAddNext,
    this.onNodeDelete,
  });

  /// Удобный конструктор: создаёт buildNode из списка шагов через DialogNodeFactory
  factory DialogsCenteredCanvas.withFactory({
    Key? key,
    required CenteredLayoutResult layout,
    required Size nodeSize,
    required List<DialogStep> steps,
    DialogNodeFactory factory = const DialogNodeFactory(),
    NodeStyles styles = const NodeStyles(),
    void Function(int id)? onTap,
    void Function(int id)? onOpenMenu,
    void Function(int id)? onAddNext,
    void Function(int id)? onDelete,
    TransformationController? transformationController,
    Key? contentKey,
    RenderSettings renderSettings = const RenderSettings(),
    FeatureFlags flags = const FeatureFlags(),
  }) {
    return DialogsCenteredCanvas(
      key: key,
      layout: layout,
      nodeSize: nodeSize,
      buildNode: (id, k) {
        final step = steps.firstWhere((s) => s.id == id);
        return KeyedSubtree(
          key: k,
          child: factory.buildNodeFromStep(
            step,
            styles: styles,
            onTap: onTap == null ? null : () => onTap(id),
            onOpenMenu: onOpenMenu == null ? null : () => onOpenMenu(id),
          ),
        );
      },
      transformationController: transformationController,
      contentKey: contentKey,
      renderSettings: renderSettings,
      flags: flags,
      onNodeTap: onTap,
      onNodeOpenMenu: onOpenMenu,
      onNodeAddNext: onAddNext,
      onNodeDelete: onDelete,
    );
  }

  final CenteredLayoutResult layout;
  final Size nodeSize;
  final Widget Function(int stepId, Key? key)? buildNode;
  final TransformationController? transformationController;
  final Key? contentKey;
  final RenderSettings renderSettings;
  final FeatureFlags flags;
  final List<DialogStep>? steps;
  final DialogNodeFactory factory;
  final NodeStyles nodeStyles;
  final void Function(int id)? onNodeTap;
  final void Function(int id)? onNodeOpenMenu;
  final void Function(int id)? onNodeAddNext;
  final void Function(int id)? onNodeDelete;

  @override
  Widget build(BuildContext context) {
    // Готовим билдер нод: либо внешний, либо фабричный из steps
    final Widget Function(int, Key?) nodeBuilder = buildNode ?? (steps != null
        ? (int id, Key? key) {
            final step = steps!.firstWhere((s) => s.id == id, orElse: () => steps!.first);
            return KeyedSubtree(
              key: key,
              child: factory.buildNodeFromStep(
                step,
                styles: nodeStyles,
                onTap: onNodeTap == null ? null : () => onNodeTap!(id),
                onOpenMenu: onNodeOpenMenu == null ? null : () => onNodeOpenMenu!(id),
                onAddNext: onNodeAddNext == null ? null : () => onNodeAddNext!(id),
                onDelete: onNodeDelete == null ? null : () => onNodeDelete!(id),
              ),
            );
          }
        : (int id, Key? key) => const SizedBox());

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
            color: renderSettings.nextEdgeColor,
            strokeWidth: renderSettings.nextEdgeStrokeWidth,
          ),
          // Рёбра branch (оранжевые)
          EdgesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            edges: layout.branchEdges,
            color: renderSettings.branchEdgeColor,
            strokeWidth: renderSettings.branchEdgeStrokeWidth,
          ),
          // Обратные рёбра (идущие вверх): рисуем отдельным слоем
          if (flags.showBackEdges)
            BackEdgesLayer(
              positions: layout.positions,
              nodeSize: nodeSize,
              allEdges: [
                ...layout.nextEdges,
                ...layout.branchEdges,
              ],
              renderSettings: renderSettings,
              color: renderSettings.backEdgeColor,
              strokeWidth: renderSettings.backEdgeStrokeWidth,
            ),
          // Узлы
          NodesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            buildNode: nodeBuilder,
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

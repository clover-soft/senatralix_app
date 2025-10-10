import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/centered_layered_layout.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/edges_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/back_edges_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/layers/nodes_layer.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/settings/render_settings.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/settings/feature_flags.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/nodes/dialog_node_factory.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/subfeature_styles.dart';

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
    this.subfeatureStyles = const SubfeatureStyles(),
    this.onNodeTap,
    this.onNodeOpenMenu,
    this.onNodeAddNext,
    this.onNodeDelete,
    this.onNodeDoubleTap,
    this.getNodeKey,
  });

  /// Удобный конструктор: создаёт buildNode из списка шагов через DialogNodeFactory
  factory DialogsCenteredCanvas.withFactory({
    Key? key,
    required CenteredLayoutResult layout,
    required Size nodeSize,
    required List<DialogStep> steps,
    DialogNodeFactory factory = const DialogNodeFactory(),
    SubfeatureStyles styles = const SubfeatureStyles(),
    void Function(int id)? onTap,
    void Function(int id)? onOpenMenu,
    void Function(int id)? onAddNext,
    void Function(int id)? onDelete,
    void Function(int id)? onDoubleTap,
    Key? Function(int id)? getNodeKey,
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
            onAddNext: onAddNext == null ? null : () => onAddNext(id),
            onDelete: onDelete == null ? null : () => onDelete(id),
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
      onNodeDoubleTap: onDoubleTap,
      getNodeKey: getNodeKey,
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
  final SubfeatureStyles subfeatureStyles;
  final void Function(int id)? onNodeTap;
  final void Function(int id)? onNodeOpenMenu;
  final void Function(int id)? onNodeAddNext;
  final void Function(int id)? onNodeDelete;
  final void Function(int id)? onNodeDoubleTap;
  final Key? Function(int id)? getNodeKey;

  @override
  Widget build(BuildContext context) {
    // Готовим билдер нод: либо внешний, либо фабричный из steps
    final Widget Function(int, Key?) nodeBuilder =
        buildNode ??
        (steps != null
            ? (int id, Key? key) {
                final step = steps!.firstWhere(
                  (s) => s.id == id,
                  orElse: () => steps!.first,
                );
                return KeyedSubtree(
                  key: key,
                  child: factory.buildNodeFromStep(
                    step,
                    styles: subfeatureStyles,
                    onTap: onNodeTap == null ? null : () => onNodeTap!(id),
                    onOpenMenu: onNodeOpenMenu == null
                        ? null
                        : () => onNodeOpenMenu!(id),
                    onAddNext: onNodeAddNext == null
                        ? null
                        : () => onNodeAddNext!(id),
                    onDelete: onNodeDelete == null
                        ? null
                        : () => onNodeDelete!(id),
                  ),
                );
              }
            : (int id, Key? key) => const SizedBox());

    // Если рисуем обратные рёбра отдельным слоем и стиль Ortho, исключаем дубли в EdgesLayer
    final bool excludeUpBack =
        flags.showBackEdges &&
        renderSettings.backEdgeStyle == BackEdgeStyle.ortho;
    final List<MapEntry<int, int>> nextVisible = excludeUpBack
        ? layout.nextEdges
              .where((e) {
                final from = layout.positions[e.key];
                final to = layout.positions[e.value];
                if (from == null || to == null) return true;
                return from.dy <=
                    to.dy; // не рисуем вверх идущие — их рисует BackEdgesLayer
              })
              .toList(growable: false)
        : layout.nextEdges;
    final List<MapEntry<int, int>> branchVisible = excludeUpBack
        ? layout.branchEdges
              .where((e) {
                final from = layout.positions[e.key];
                final to = layout.positions[e.value];
                if (from == null || to == null) return true;
                return from.dy <= to.dy;
              })
              .toList(growable: false)
        : layout.branchEdges;

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
            edges: nextVisible,
            color: subfeatureStyles.nextEdgeColor,
            strokeWidth: subfeatureStyles.nextEdgeStrokeWidth,
          ),
          // Рёбра branch (оранжевые)
          EdgesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            edges: branchVisible,
            color: subfeatureStyles.branchEdgeColor,
            strokeWidth: subfeatureStyles.branchEdgeStrokeWidth,
          ),
          // Обратные рёбра (идущие вверх): рисуем отдельным слоем
          if (flags.showBackEdges)
            BackEdgesLayer(
              positions: layout.positions,
              nodeSize: nodeSize,
              allEdges: [...layout.nextEdges, ...layout.branchEdges],
              renderSettings: renderSettings,
              color: subfeatureStyles.backEdgeColor,
              strokeWidth: subfeatureStyles.backEdgeStrokeWidth,
            ),
          // Узлы
          NodesLayer(
            positions: layout.positions,
            nodeSize: nodeSize,
            buildNode: nodeBuilder,
            onDoubleTap: onNodeDoubleTap,
            getNodeKey: getNodeKey,
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

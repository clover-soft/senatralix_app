import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/back_edges_painter.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/back_edges_painter_ortho.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/settings/render_settings.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/utils/back_edges_planner.dart';

class BackEdgesLayer extends StatelessWidget {
  const BackEdgesLayer({
    super.key,
    required this.positions,
    required this.nodeSize,
    required this.allEdges,
    required this.renderSettings,
    this.color = const Color(0xFFEA4335),
    this.strokeWidth = 1.8,
  });

  final Map<int, Offset> positions;
  final Size nodeSize;
  final List<MapEntry<int, int>> allEdges;
  final RenderSettings renderSettings;
  final Color color; // устаревающее поле, сохраняем для совместимости
  final double strokeWidth; // устаревающее поле, сохраняем для совместимости

  @override
  Widget build(BuildContext context) {
    // Оставляем только обратные рёбра: те, что идут "вверх" (из большей dy в меньшую dy)
    final filtered = allEdges
        .where((e) {
          final from = positions[e.key];
          final to = positions[e.value];
          if (from == null || to == null) return false;
          return from.dy > to.dy; // вверх по экрану
        })
        .toList(growable: false);

    // Если выбран Ortho-стиль — заранее строим план разведения полок
    BackEdgesPlan? plan;
    if (renderSettings.backEdgeStyle == BackEdgeStyle.ortho) {
      plan = const BackEdgesPlanner().computePlan(
        positions: positions,
        nodeSize: nodeSize,
        allEdges: filtered,
        exitFactor: renderSettings.orthoExitFactor,
        approachFactor: renderSettings.orthoApproachFactor,
        exitOffset: renderSettings.orthoExitOffset,
        approachOffset: renderSettings.orthoApproachOffset,
        lift: renderSettings.orthoLift,
        overshoot: renderSettings.orthoOvershoot,
        shelfSpacing: renderSettings.orthoShelfSpacing,
        shelfMaxLanes: renderSettings.orthoShelfMaxLanes,
        approachSpacingX: renderSettings.orthoApproachSpacingX,
        approachMaxPush: renderSettings.orthoApproachMaxPush,
        approachEchelonSpacingY: renderSettings.orthoApproachEchelonSpacingY,
        approachMaxLanesY: renderSettings.orthoApproachMaxLanesY,
        debug: true,
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: renderSettings.backEdgeStyle == BackEdgeStyle.ortho
              ? BackEdgesPainterOrtho(
                  positions: positions,
                  nodeSize: nodeSize,
                  allEdges: filtered,
                  color: renderSettings.backEdgeColor,
                  strokeWidth: renderSettings.backEdgeStrokeWidth,
                  cornerRadius: renderSettings.orthoCornerRadius,
                  verticalClearance: renderSettings.orthoVerticalClearance,
                  horizontalClearance: renderSettings.orthoHorizontalClearance,
                  exitOffset: renderSettings.orthoExitOffset,
                  approachOffset: renderSettings.orthoApproachOffset,
                  exitFactor: renderSettings.orthoExitFactor,
                  approachFactor: renderSettings.orthoApproachFactor,
                  approachFromTopOnly: renderSettings.orthoApproachFromTopOnly,
                  minSegment: renderSettings.orthoMinSegment,
                  arrowAttachAtEdgeMid: renderSettings.arrowAttachAtEdgeMid,
                  arrowTriangleFilled: renderSettings.arrowTriangleFilled,
                  arrowTriangleBase: renderSettings.arrowTriangleBase,
                  arrowTriangleHeight: renderSettings.arrowTriangleHeight,
                  plan: plan,
                )
              : BackEdgesPainter(
                  positions: positions,
                  nodeSize: nodeSize,
                  allEdges: filtered,
                  color: renderSettings.backEdgeColor,
                  strokeWidth: renderSettings.backEdgeStrokeWidth,
                ),
        ),
      ),
    );
  }
}

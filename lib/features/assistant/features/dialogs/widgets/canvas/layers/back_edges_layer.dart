import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/back_edges_painter.dart';

class BackEdgesLayer extends StatelessWidget {
  const BackEdgesLayer({
    super.key,
    required this.positions,
    required this.nodeSize,
    required this.allEdges,
    this.color = const Color(0xFFEA4335),
    this.strokeWidth = 1.8,
  });

  final Map<int, Offset> positions;
  final Size nodeSize;
  final List<MapEntry<int, int>> allEdges;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: BackEdgesPainter(
            positions: positions,
            nodeSize: nodeSize,
            allEdges: allEdges,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

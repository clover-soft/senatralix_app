import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/edges_painter.dart';

class EdgesLayer extends StatelessWidget {
  const EdgesLayer({
    super.key,
    required this.positions,
    required this.nodeSize,
    required this.edges,
    required this.color,
    this.strokeWidth = 2.0,
  });

  final Map<int, Offset> positions;
  final Size nodeSize;
  final List<MapEntry<int, int>> edges;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: EdgesPainter(
            positions: positions,
            edges: edges,
            nodeSize: nodeSize,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

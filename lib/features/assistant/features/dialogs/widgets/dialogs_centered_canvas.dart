import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/centered_layered_layout.dart';

class DialogsCenteredCanvas extends StatelessWidget {
  const DialogsCenteredCanvas({
    super.key,
    required this.layout,
    required this.nodeSize,
    required this.buildNode,
    this.transformationController,
    this.contentKey,
  });

  final CenteredLayoutResult layout;
  final Size nodeSize;
  final Widget Function(int stepId, Key? key) buildNode;
  final TransformationController? transformationController;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    final content = RepaintBoundary(
      key: contentKey,
      child: Stack(
        children: [
          // Полотно нужного размера
          SizedBox(width: layout.canvasSize.width, height: layout.canvasSize.height),
          // Рёбра next (чёрные)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EdgesPainter(
                  positions: layout.positions,
                  edges: layout.nextEdges,
                  nodeSize: nodeSize,
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          // Рёбра branch (оранжевые)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EdgesPainter(
                  positions: layout.positions,
                  edges: layout.branchEdges,
                  nodeSize: nodeSize,
                  color: const Color(0xFFFF9800),
                  strokeWidth: 1.6,
                ),
              ),
            ),
          ),
          // Узлы
          ...layout.positions.entries.map(
            (e) => Positioned(
              left: e.value.dx,
              top: e.value.dy,
              width: nodeSize.width,
              height: nodeSize.height,
              child: buildNode(e.key, Key(e.key.toString())),
            ),
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

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
    required this.positions,
    required this.edges,
    required this.nodeSize,
    required this.color,
    required this.strokeWidth,
  });

  final Map<int, Offset> positions;
  final List<MapEntry<int, int>> edges;
  final Size nodeSize;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final e in edges) {
      final p0 = positions[e.key];
      final p1 = positions[e.value];
      if (p0 == null || p1 == null) continue;
      final c0 = Offset(p0.dx + nodeSize.width / 2, p0.dy + nodeSize.height / 2);
      final c1 = Offset(p1.dx + nodeSize.width / 2, p1.dy + nodeSize.height / 2);
      canvas.drawLine(c0, c1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.edges != edges ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.nodeSize != nodeSize;
  }
}

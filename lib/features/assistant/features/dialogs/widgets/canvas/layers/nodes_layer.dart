import 'package:flutter/widgets.dart';

class NodesLayer extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.positions,
    required this.nodeSize,
    required this.buildNode,
  });

  final Map<int, Offset> positions;
  final Size nodeSize;
  final Widget Function(int stepId, Key? key) buildNode;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          ...positions.entries.map(
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
  }
}

import 'package:flutter/widgets.dart';

class NodesLayer extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.positions,
    required this.nodeSize,
    required this.buildNode,
    this.onDoubleTap,
    this.getNodeKey,
  });

  final Map<int, Offset> positions;
  final Size nodeSize;
  final Widget Function(int stepId, Key? key) buildNode;
  final void Function(int stepId)? onDoubleTap;
  final Key? Function(int stepId)? getNodeKey;

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
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  // Логируем id ноды при двойном клике
                  debugPrint('[Dialogs] Double-tap on node id=${e.key}');
                  if (onDoubleTap != null) {
                    onDoubleTap!(e.key);
                  } else {
                    debugPrint('[Dialogs] onDoubleTap is null');
                  }
                },
                child: KeyedSubtree(
                  key: getNodeKey?.call(e.key) ?? Key(e.key.toString()),
                  child: buildNode(e.key, Key(e.key.toString())),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

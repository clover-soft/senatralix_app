import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_tree_canvas.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_node.dart';

/// Левая панель: дерево сценария
class DialogsTreePanel extends ConsumerWidget {
  const DialogsTreePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(graphProvider);
    final algorithm = GraphStyle
        .sugiyamaTopBottom(nodeSeparation: 20, levelSeparation: 80)
        .buildAlgorithm();
    final editor = ref.watch(dialogsEditorControllerProvider);

    return DialogsTreeCanvas(
      graph: graph,
      algorithm: algorithm,
      nodeBuilder: (Node n) {
        final id = n.key!.value as int;
        final step = editor.steps.firstWhere((e) => e.id == id);
        final isSelected =
            editor.selectedStepId == id || editor.linkStartStepId == id;
        return GestureDetector(
          onTap: () => ref
              .read(dialogsEditorControllerProvider.notifier)
              .onNodeTap(id),
          child: StepNode(step: step, selected: isSelected),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';

/// Правая панель: свойства выбранного шага
class DialogsPropsPanel extends ConsumerWidget {
  const DialogsPropsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(dialogsEditorControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Text('Свойства шага', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              IconButton(
                tooltip: editor.linkStartStepId == null
                    ? 'Назначить next: выберите узел-источник'
                    : 'Кликните по целевому узлу',
                onPressed: editor.selectedStepId == null
                    ? null
                    : () => ref.read(dialogsEditorControllerProvider.notifier).beginLinkFromSelected(),
                icon: Icon(
                  Icons.call_merge,
                  color: editor.linkStartStepId == null
                      ? null
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: editor.selectedStepId == null
              ? const Center(child: Text('Выберите шаг на графе'))
              : StepProps(
                  step: editor.steps.firstWhere((e) => e.id == editor.selectedStepId),
                  allSteps: editor.steps,
                  onUpdate: (updated) => ref.read(dialogsEditorControllerProvider.notifier).updateStep(updated),
                ),
        ),
      ],
    );
  }
}

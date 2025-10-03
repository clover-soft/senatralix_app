import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';

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
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Сохранить конфигурацию диалога (PATCH)',
                onPressed: () async {
                  final ctrl = ref.read(dialogsConfigControllerProvider.notifier);
                  ctrl.saveFullDebounced();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Изменения будут сохранены')),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_upload),
              ),
            ],
          ),
        ),
        Expanded(
          child: editor.selectedStepId == null
              ? const Center(child: Text('Выберите шаг на графе'))
              : Center(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Открыть настройки шага'),
                    onPressed: () async {
                      final id = editor.selectedStepId!;
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => StepProps(stepId: id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

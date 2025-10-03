import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';
import 'package:sentralix_app/features/assistant/api/assistant_api.dart';
import 'package:sentralix_app/data/api/api_client_provider.dart';

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
                  final api = AssistantApi(ref.read(apiClientProvider));
                  final idCtrl = TextEditingController(text: '1');
                  final nameCtrl = TextEditingController(text: 'Прием заявок');
                  final descCtrl = TextEditingController(text: '');
                  final formKey = GlobalKey<FormState>();

                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Обновить диалог (PATCH)'),
                      content: Form(
                        key: formKey,
                        child: SizedBox(
                          width: 420,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: idCtrl,
                                decoration: const InputDecoration(labelText: 'ID конфигурации'),
                                validator: (v) => (int.tryParse((v ?? '').trim()) == null) ? 'Введите целое число' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Название'),
                                validator: (v) => ((v ?? '').trim().isEmpty) ? 'Заполните название' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: descCtrl,
                                decoration: const InputDecoration(labelText: 'Описание (optional)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            try {
                              final id = int.parse(idCtrl.text.trim());
                              final name = nameCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              await api.updateDialogConfigFull(
                                id: id,
                                name: name,
                                description: desc.isEmpty ? null : desc,
                                steps: editor.steps,
                                metadata: const {},
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Диалог обновлён')),
                                );
                              }
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Обновить'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    // no-op
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

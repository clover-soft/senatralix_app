import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/step_editor_dialog.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_edit_provider.dart';

// ----------------------
// Script Editor Dialog
// ----------------------

class ScriptEditorDialog extends ConsumerWidget {
  const ScriptEditorDialog({super.key, required this.initial});
  final Script initial;

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите имя';
    if (v.trim().length < 2 || v.trim().length > 60) return 'Длина 2–60';
    return null;
  }

  void _onSave(BuildContext context, WidgetRef ref) {
    final state = ref.read(scriptEditProvider(initial));
    // Валидация
    if (state.name.trim().length < 2 || state.name.trim().length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название: 2–60 символов')),
      );
      return;
    }
    for (final p in state.params) {
      if (p.trim().isEmpty || p.trim().length > 40) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ключ параметра должен быть 1–40 символов')),
        );
        return;
      }
    }
    if (state.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте как минимум один шаг')),
      );
      return;
    }
    Navigator.pop(context, ref.read(scriptEditProvider(initial).notifier).buildResult(initial));
  }

  void _addStep(BuildContext context, WidgetRef ref) async {
    final step = await showDialog<ScriptStep>(
      context: context,
      builder: (_) => StepEditorDialog(
        initial: ScriptStep(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          spec: '''
{
  "when": {"jsonpath": "\$.path.to.value"},
  "action": {"type": "http_post", "http": {"url": "https://...", "headers": {}, "query": {}, "body_template": ""}}
}
''',
        ),
      ),
    );
    if (step != null) {
      ref.read(scriptEditProvider(initial).notifier).addStep(step);
    }
  }

  void _editStep(BuildContext context, WidgetRef ref, int index, ScriptStep current) async {
    final step = await showDialog<ScriptStep>(
      context: context,
      builder: (_) => StepEditorDialog(initial: current),
    );
    if (step != null) {
      ref.read(scriptEditProvider(initial).notifier).updateStep(index, step);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scriptEditProvider(initial));
    final ctrl = ref.read(scriptEditProvider(initial).notifier);
    return AlertDialog(
      title: const Text('Скрипт'),
      content: SizedBox(
        width: 860,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: state.name,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator: _vName,
                      onChanged: ctrl.setName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ScriptTrigger>(
                      value: state.trigger,
                      items: const [
                        DropdownMenuItem(
                          value: ScriptTrigger.onDialogStart,
                          child: Text('on_dialog_start'),
                        ),
                        DropdownMenuItem(
                          value: ScriptTrigger.onDialogEnd,
                          child: Text('on_dialog_end'),
                        ),
                      ],
                      onChanged: (v) => ctrl.setTrigger(v ?? ScriptTrigger.onDialogStart),
                      decoration: const InputDecoration(labelText: 'Trigger'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: state.enabled,
                onChanged: ctrl.setEnabled,
                title: const Text('Включен'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Параметры', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.params.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = state.params[index];
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: p,
                          decoration: const InputDecoration(labelText: 'key'),
                          onChanged: (v) => ctrl.setParamKey(index, v),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Удалить параметр',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ctrl.removeParam(index),
                      ),
                    ],
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: ctrl.addParam,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить параметр'),
                ),
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Шаги', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final st = state.steps[index];
                  final order = index + 1;
                  return Card(
                    child: ListTile(
                      title: Text(st.title.isEmpty ? '(без названия)' : st.title),
                      subtitle: Text('Шаг $order • spec: ${st.spec.isEmpty ? '(не задан)' : 'JSON'}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'Редактировать шаг',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editStep(context, ref, index, st),
                          ),
                          IconButton(
                            tooltip: 'Удалить шаг',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ctrl.removeStep(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addStep(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить шаг'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: () => _onSave(context, ref), child: const Text('Сохранить')),
      ],
    );
  }
}

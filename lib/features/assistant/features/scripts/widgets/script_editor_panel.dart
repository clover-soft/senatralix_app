import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_edit_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/scripts_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/step_editor_dialog.dart';

/// Встроенная панель редактирования скрипта (без модального окна)
class ScriptEditorPanel extends ConsumerWidget {
  const ScriptEditorPanel({
    super.key,
    required this.assistantId,
    required this.initial,
  });

  final String assistantId;
  final Script initial;

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите имя';
    if (v.trim().length < 2 || v.trim().length > 60) return 'Длина 2–60';
    return null;
  }

  void _onSave(WidgetRef ref, Script initial) {
    final updated = ref
        .read(scriptEditProvider(initial).notifier)
        .buildResult(initial);
    ref.read(scriptsProvider.notifier).update(assistantId, updated);
    ScaffoldMessenger.of(
      ref.context,
    ).showSnackBar(const SnackBar(content: Text('Скрипт сохранён')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scriptEditProvider(initial));
    final ctrl = ref.read(scriptEditProvider(initial).notifier);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    onChanged: (v) =>
                        ctrl.setTrigger(v ?? ScriptTrigger.onDialogStart),
                    decoration: const InputDecoration(labelText: 'Trigger'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _onSave(ref, initial),
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить'),
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

            // Две колонки: слева Шаги (70%), справа Список переменных (30%)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Левая колонка — Шаги
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Шаги',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 360),
                            child: Scrollbar(
                              child: ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                itemCount: state.steps.length,
                                onReorder: (oldIndex, newIndex) =>
                                    ctrl.moveStep(oldIndex, newIndex),
                                itemBuilder: (context, index) {
                                  final st = state.steps[index];
                                  final order = index + 1;
                                  return Card(
                                    key: ValueKey(st.id),
                                    child: ListTile(
                                      leading: ReorderableDragStartListener(
                                        index: index,
                                        child: const Icon(Icons.drag_handle),
                                      ),
                                      title: Text(
                                        st.title.isEmpty
                                            ? '(без названия)'
                                            : st.title,
                                      ),
                                      subtitle: Text(
                                        'Шаг $order • spec: ${st.spec.isEmpty ? '(не задан)' : 'JSON'}',
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            tooltip: 'Редактировать',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () async {
                                              final res =
                                                  await showDialog<ScriptStep>(
                                                    context: context,
                                                    builder: (_) =>
                                                        StepEditorDialog(
                                                          initial: st,
                                                        ),
                                                  );
                                              if (res != null) {
                                                ctrl.updateStep(index, res);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Удалить',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () =>
                                                ctrl.removeStep(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            final step = ScriptStep(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              title: '',
                              spec: r'''
{
  "when": {"jsonpath": "$.path.to.value"},
  "action": {"type": "http_post", "http": {"url": "https://...", "headers": {}, "query": {}, "body_template": ""}}
}
''',
                            );
                            ctrl.addStep(step);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить шаг'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Правая колонка — Параметры
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Список переменных',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 360),
                            child: Scrollbar(
                              child: ListView.separated(
                                itemCount: state.params.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final keyStr = state.params[index];
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: keyStr,
                                          decoration: const InputDecoration(
                                            labelText: 'key',
                                          ),
                                          onChanged: (v) =>
                                              ctrl.setParamKey(index, v),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Удалить',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () =>
                                            ctrl.removeParam(index),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: ctrl.addParam,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить переменную'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/scripts_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/script_editor_dialog.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantScriptsScreen extends ConsumerStatefulWidget {
  const AssistantScriptsScreen({super.key});

  @override
  ConsumerState<AssistantScriptsScreen> createState() => _AssistantScriptsScreenState();
}

class _AssistantScriptsScreenState extends ConsumerState<AssistantScriptsScreen> {
  late String _assistantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  void _addByPreset(String key) async {
    final json = getScriptPreset(key) ?? getScriptPreset('empty_start')!;
    final script = Script.fromJson({
      ...json,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    final res = await showDialog<Script>(
      context: context,
      builder: (_) => ScriptEditorDialog(initial: script),
    );
    if (res != null) ref.read(scriptsProvider.notifier).add(_assistantId, res);
  }

  void _edit(Script script) async {
    final res = await showDialog<Script>(
      context: context,
      builder: (_) => ScriptEditorDialog(initial: script),
    );
    if (res != null) ref.read(scriptsProvider.notifier).update(_assistantId, res);
  }

  void _remove(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить скрипт?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) ref.read(scriptsProvider.notifier).remove(_assistantId, id);
  }

  String _triggerLabel(ScriptTrigger t) =>
      t == ScriptTrigger.onDialogEnd ? 'on_dialog_end' : 'on_dialog_start';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(scriptsProvider.select((s) => s.byAssistantId[_assistantId] ?? const []));
    return Scaffold(
      appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Scripts'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить скрипт',
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_arrow_outlined),
                    title: const Text('Пустой (start)'),
                    onTap: () => Navigator.pop(ctx, 'empty_start'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('Пустой (end)'),
                    onTap: () => Navigator.pop(ctx, 'empty_end'),
                  ),
                  const Divider(height: 8),
                  ListTile(
                    leading: const Icon(Icons.flash_on_outlined),
                    title: const Text('Старт: GET /warmup'),
                    onTap: () => Navigator.pop(ctx, 'start_get_warmup'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Завершение: POST /summary'),
                    onTap: () => Navigator.pop(ctx, 'end_post_summary'),
                  ),
                ],
              ),
            ),
          );
          _addByPreset(choice ?? 'empty_start');
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final it = items[index];
          return Card(
            child: ListTile(
              leading: Switch(
                value: it.enabled,
                onChanged: (v) =>
                    ref.read(scriptsProvider.notifier).toggleEnabled(_assistantId, it.id, v),
              ),
              title: Text(it.name.isEmpty ? 'Без имени' : it.name),
              subtitle: Text('${_triggerLabel(it.trigger)} • шагов: ${it.steps.length}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(it),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _remove(it.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

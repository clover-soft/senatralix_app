import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_tools_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/tools/widgets/function_tool_dialog.dart';
import 'package:sentralix_app/features/assistant/features/tools/data/tool_presets.dart';

class AssistantToolsScreen extends ConsumerStatefulWidget {
  const AssistantToolsScreen({super.key});

  @override
  ConsumerState<AssistantToolsScreen> createState() =>
      _AssistantToolsScreenState();
}

class _AssistantToolsScreenState extends ConsumerState<AssistantToolsScreen> {
  late String _assistantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  void _addPreset(String preset) {
    final notifier = ref.read(assistantToolsProvider.notifier);
    final presetKey = kFunctionToolPresets.containsKey(preset) ? preset : 'new';
    final json = getFunctionToolPreset(presetKey)!;
    final tool = notifier.fromPresetJson(
      DateTime.now().millisecondsSinceEpoch.toString(),
      json,
    );
    notifier.add(_assistantId, tool);
  }

  void _editTool(AssistantFunctionTool tool) async {
    final result = await showDialog<AssistantFunctionTool>(
      context: context,
      builder: (context) => FunctionToolDialog(initial: tool),
    );
    if (result != null) {
      ref.read(assistantToolsProvider.notifier).update(_assistantId, result);
    }
  }

  void _removeTool(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить инструмент?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(assistantToolsProvider.notifier).remove(_assistantId, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = ref.watch(
      assistantToolsProvider.select(
        (s) => s.byAssistantId[_assistantId] ?? const [],
      ),
    );
    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: _assistantId,
        subfeatureTitle: 'Инструменты',
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить инструмент',
        child: const Icon(Icons.add),
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Пустой Function'),
                    onTap: () => Navigator.pop(ctx, 'new'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.call_split_outlined),
                    title: const Text('Пресет: transferCall'),
                    onTap: () => Navigator.pop(ctx, 'transferCall'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.call_end_outlined),
                    title: const Text('Пресет: hangupCall'),
                    onTap: () => Navigator.pop(ctx, 'hangupCall'),
                  ),
                ],
              ),
            ),
          );
          if (choice != null) _addPreset(choice);
        },
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final t = tools[index];
          return Card(
            child: ListTile(
              leading: Switch(
                value: t.enabled,
                onChanged: (v) => ref
                    .read(assistantToolsProvider.notifier)
                    .toggleEnabled(_assistantId, t.id, v),
              ),
              title: Text(t.def.name),
              subtitle: Text(
                t.def.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editTool(t),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeTool(t.id),
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

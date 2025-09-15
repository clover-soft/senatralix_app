import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_tools_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/tools/widgets/function_tool_dialog.dart';
import 'package:sentralix_app/features/assistant/features/tools/data/tool_presets.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_fab.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_feature_list_item.dart';

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

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(assistantBootstrapProvider);
    final tools = ref.watch(
      assistantToolsProvider.select(
        (s) => s.byAssistantId[_assistantId] ?? const [],
      ),
    );
    if (boot.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: _assistantId,
          subfeatureTitle: 'Инструменты',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (boot.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: _assistantId,
          subfeatureTitle: 'Инструменты',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки данных'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(assistantBootstrapProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: _assistantId,
        subfeatureTitle: 'Инструменты',
      ),
      floatingActionButton: AssistantActionFab(
        icon: Icons.add,
        tooltip: 'Добавить инструмент',
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
          final String fnName = t.def.name;
          final IconData toolIcon = fnName == 'transferCall'
              ? Icons.phone_forwarded
              : (fnName == 'hangupCall'
                  ? Icons.call_end
                  : Icons.extension);
          return AssistantFeatureListItem(
            onTap: () => _editTool(t),
            leadingIcon:
                Icon(toolIcon, color: Theme.of(context).colorScheme.secondary),
            title: t.def.name,
            subtitle: t.def.description,
            meta: 'id: ${t.id}',
            showDelete: true,
            deleteEnabled: false,
            showChevron: true,
          );
        },
      ),
    );
  }
}

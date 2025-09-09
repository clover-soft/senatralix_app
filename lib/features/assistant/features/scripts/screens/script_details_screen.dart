import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/scripts_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/script_editor_panel.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

/// Экран деталей скрипта: редактирование выбранного скрипта в общем UI
class ScriptDetailsScreen extends ConsumerWidget {
  const ScriptDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantId = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final scriptId = GoRouterState.of(context).pathParameters['scriptId'];

    final items = ref.watch(scriptsProvider.select((s) => s.byAssistantId[assistantId] ?? const []));
    final script = items.firstWhere(
      (e) => e.id == scriptId,
      orElse: () => const Script(id: '', name: '', enabled: false, trigger: ScriptTrigger.onDialogStart, params: {}, steps: []),
    );

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Script details',
        backPath: '/assistant/$assistantId/scripts',
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: script.id.isEmpty
            ? Center(
                child: Text('Скрипт не найден', style: Theme.of(context).textTheme.bodyMedium),
              )
            : ScriptEditorPanel(assistantId: assistantId, initial: script),
      ),
    );
  }
}

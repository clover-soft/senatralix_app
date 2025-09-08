import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/widgets/knowledge_editor_dialog.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantKnowledgeScreen extends ConsumerStatefulWidget {
  const AssistantKnowledgeScreen({super.key});

  @override
  ConsumerState<AssistantKnowledgeScreen> createState() => _AssistantKnowledgeScreenState();
}

class _AssistantKnowledgeScreenState extends ConsumerState<AssistantKnowledgeScreen> {
  late String _assistantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  void _addItem() async {
    final now = DateTime.now();
    final draft = KnowledgeBaseItem(
      id: now.millisecondsSinceEpoch,
      externalId: 'kb_${now.millisecondsSinceEpoch}',
      markdown: '',
      status: KnowledgeStatus.ready,
      active: true,
      maxChunkSizeTokens: 700,
      chunkOverlapTokens: 300,
      ttlDays: 30,
      expirationPolicy: 'since_last_active',
      createdAt: now,
      updatedAt: now,
    );
    final res = await showDialog<KnowledgeBaseItem>(
      context: context,
      builder: (_) => KnowledgeEditorDialog(initial: draft),
    );
    if (res != null) {
      ref.read(knowledgeProvider.notifier).add(_assistantId, res);
    }
  }

  void _editItem(KnowledgeBaseItem item) async {
    final res = await showDialog<KnowledgeBaseItem>(
      context: context,
      builder: (_) => KnowledgeEditorDialog(initial: item),
    );
    if (res != null) {
      ref.read(knowledgeProvider.notifier).update(_assistantId, res);
    }
  }

  void _removeItem(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить источник?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(knowledgeProvider.notifier).remove(_assistantId, id);
    }
  }

  String _titleFromMarkdown(String md) {
    final lines = md.split('\n');
    for (final l in lines) {
      final s = l.trim();
      if (s.startsWith('#')) {
        return s.replaceFirst(RegExp(r'^#+\s*'), '');
      }
      if (s.isNotEmpty) return s.length > 60 ? '${s.substring(0, 60)}…' : s;
    }
    return 'Новый источник';
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(knowledgeProvider.select((s) => s.byAssistantId[_assistantId] ?? const []));
    return Scaffold(
      appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Knowledge'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить источник',
        onPressed: _addItem,
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
                value: it.active,
                onChanged: (v) => ref.read(knowledgeProvider.notifier).toggleActive(_assistantId, it.id, v),
              ),
              title: Text(_titleFromMarkdown(it.markdown)),
              subtitle: Text('${it.externalId} • ${it.createdAt.toLocal()}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editItem(it),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeItem(it.id),
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

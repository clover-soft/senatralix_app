import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/assistant_knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/app_list_item.dart';
import 'package:remixicon/remixicon.dart';

class AssistantKnowledgeScreen extends ConsumerStatefulWidget {
  const AssistantKnowledgeScreen({super.key});

  @override
  ConsumerState<AssistantKnowledgeScreen> createState() =>
      _AssistantKnowledgeScreenState();
}

class _AssistantKnowledgeScreenState
    extends ConsumerState<AssistantKnowledgeScreen> {
  late String _assistantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  void _addItem() async {
    final now = DateTime.now();
    final draft = KnowledgeBaseItem(
      id: now.millisecondsSinceEpoch,
      name: 'Новый источник',
      description: '',
      externalId: 'kb_${now.millisecondsSinceEpoch}',
      markdown: '',
      status: KnowledgeStatus.ready,
      active: true,
      maxChunkSizeTokens: 700,
      chunkOverlapTokens: 300,
      createdAt: now,
      updatedAt: now,
    );
    // Переходим на экран создания по роуту, прокидываем draft через extra
    if (!mounted) return;
    context.go('/assistant/$_assistantId/knowledge/new', extra: draft);
  }

  void _editItem(KnowledgeBaseItem item) async {
    if (!mounted) return;
    // Переходим на экран редактирования с ID в URL
    context.go('/assistant/$_assistantId/knowledge/${item.id}');
  }

  void _removeItem(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить источник?'),
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
    final loader = ref.watch(assistantKnowledgeProvider(_assistantId));
    final boot = ref.watch(assistantBootstrapProvider);
    final items = ref.watch(
      knowledgeProvider.select(
        (s) => s.byAssistantId[_assistantId] ?? const [],
      ),
    );
    if (loader.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Источники знаний'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (loader.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Источники знаний'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки данных'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(assistantKnowledgeProvider(_assistantId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (boot.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Источники знаний'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (boot.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Источники знаний'),
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
        subfeatureTitle: 'Источники знаний',
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить источник',
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final it = items[index];
          final title = (it.name.trim().isNotEmpty) ? it.name : _titleFromMarkdown(it.markdown);
          final subtitle = it.description.trim().isNotEmpty ? it.description : '';
          final meta = '${it.externalId} • ${it.updatedAt.toLocal()}';

          return AppListItem(
            onTap: () => _editItem(it),
            leading: SizedBox(
              width: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(RemixIcons.git_repository_line, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 6),
                  Consumer(builder: (context, ref, _) {
                    final linked = ref.watch(assistantSettingsProvider.select((s) =>
                        s.byId[_assistantId]?.knowledgeExternalIds.contains(it.externalId) ?? false));
                    return Tooltip(
                      message: linked ? 'Отключить источник от ассистента' : 'Подключить источник к ассистенту',
                      child: Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: linked,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) async {
                            try {
                              final api = ref.read(assistantApiProvider);
                              if (v) {
                                // bind: получаем новый external_id и обновляем модель
                                final newExt = await api.bindKnowledgeToAssistant(
                                  assistantId: _assistantId,
                                  knowledgeId: it.id,
                                );
                                // Обновим сам элемент (externalId) в списке знаний
                                final updated = it.copyWith(externalId: newExt);
                                ref.read(knowledgeProvider.notifier).update(_assistantId, updated);
                                // Установим единственный external_id у ассистента
                                ref.read(assistantSettingsProvider.notifier).setSingleKnowledge(_assistantId, newExt);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Источник привязан к ассистенту')),
                                  );
                                }
                              } else {
                                // unbind: очистить связи у ассистента
                                await api.unbindKnowledgeFromAssistant(
                                  assistantId: _assistantId,
                                  knowledgeId: it.id,
                                );
                                ref.read(assistantSettingsProvider.notifier).clearKnowledge(_assistantId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Источник отвязан от ассистента')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            title: title,
            subtitle: subtitle,
            meta: meta,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
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
          );
        },
      ),
    );
  }
}

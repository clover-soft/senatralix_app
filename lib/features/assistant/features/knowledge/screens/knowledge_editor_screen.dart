import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_edit_provider.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/assistant_knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

/// Экран редактирования источника знаний (вместо модалки)
class KnowledgeEditorScreen extends ConsumerWidget {
  const KnowledgeEditorScreen({super.key});

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;
  String? _vInt(String? v, {int? min, int? max}) {
    if (v == null || v.trim().isEmpty) return 'Укажите значение';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Введите целое число';
    if (min != null && n < min) return 'Минимум $min';
    if (max != null && n > max) return 'Максимум $max';
    return null;
  }

  void _onSave(BuildContext context, WidgetRef ref, KnowledgeBaseItem initial, String assistantId) {
    final st = ref.read(knowledgeEditProvider(initial));
    if (st.chunkOverlapTokens >= st.maxChunkSizeTokens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('chunk_overlap_tokens должен быть меньше max_chunk_size_tokens')),
      );
      return;
    }
    final updated = ref.read(knowledgeEditProvider(initial).notifier).buildResult(initial);
    // Обновляем провайдер и возвращаемся к списку
    ref.read(knowledgeProvider.notifier).update(assistantId, updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранено')));
      context.go('/assistant/$assistantId/knowledge');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context);
    final assistantId = route.pathParameters['assistantId'] ?? 'unknown';
    final knowledgeIdStr = route.pathParameters['knowledgeId'];
    // Убедимся, что список знаний загружен при прямом входе по URL
    final loader = ref.watch(assistantKnowledgeProvider(assistantId));
    KnowledgeBaseItem? initial = route.extra is KnowledgeBaseItem ? route.extra as KnowledgeBaseItem : null;
    if (initial == null && knowledgeIdStr != null) {
      final id = int.tryParse(knowledgeIdStr);
      if (id != null) {
        final items = ref.watch(knowledgeProvider.select((s) => s.byAssistantId[assistantId] ?? const <KnowledgeBaseItem>[]));
        final idx = items.indexWhere((e) => e.id == id);
        if (idx >= 0) initial = items[idx];
      }
    }

    if (initial == null) {
      // Если ещё идёт загрузка — показываем индикатор
      if (loader.isLoading) {
        return Scaffold(
          appBar: AssistantAppBar(
            assistantId: assistantId,
            subfeatureTitle: 'Источник знаний',
            backPath: '/assistant/$assistantId/knowledge',
            backTooltip: 'К списку источников',
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Источник знаний',
          backPath: '/assistant/$assistantId/knowledge',
          backTooltip: 'К списку источников',
        ),
        body: const Center(child: Text('Источник не найден')),
      );
    }

    final item = initial; // not null после проверки выше
    final st = ref.watch(knowledgeEditProvider(item));
    final ctrl = ref.read(knowledgeEditProvider(item).notifier);

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Источник знаний',
        backPath: '/assistant/$assistantId/knowledge',
        backTooltip: 'К списку источников',
        backPopFirst: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onSave(context, ref, item, assistantId),
        tooltip: 'Сохранить',
        child: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Нередактируемый external_id
            Row(
              children: [
                Text(
                  'external_id: ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SelectableText(
                  st.externalId,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Имя (обязательно)
            TextFormField(
              initialValue: st.name,
              decoration: const InputDecoration(labelText: 'name'),
              validator: _req,
              onChanged: ctrl.setName,
            ),
            const SizedBox(height: 8),
            // Описание (необязательно)
            TextFormField(
              initialValue: st.description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'description',
                helperText: 'Краткое описание источника (до 280 символов)',
              ),
              onChanged: ctrl.setDescription,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: st.markdown,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'markdown',
                helperText: 'Контент (markdown). Рекомендовано не слишком большие тексты.',
              ),
              validator: _req,
              onChanged: ctrl.setMarkdown,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: st.maxChunkSizeTokens.toString(),
                    decoration: const InputDecoration(labelText: 'max_chunk_size_tokens'),
                    keyboardType: TextInputType.number,
                    validator: (v) => _vInt(v, min: 100, max: 2000),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null) ctrl.setMaxChunk(n);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: st.chunkOverlapTokens.toString(),
                    decoration: const InputDecoration(labelText: 'chunk_overlap_tokens'),
                    keyboardType: TextInputType.number,
                    validator: (v) => _vInt(v, min: 0, max: 1000),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null) ctrl.setOverlap(n);
                    },
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

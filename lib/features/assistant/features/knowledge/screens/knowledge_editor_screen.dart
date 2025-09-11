import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_edit_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

/// Экран редактирования источника знаний (вместо модалки)
class KnowledgeEditorScreen extends ConsumerWidget {
  const KnowledgeEditorScreen({super.key, required this.assistantId, required this.initial});

  final String assistantId;
  final KnowledgeBaseItem initial;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;
  String? _vInt(String? v, {int? min, int? max}) {
    if (v == null || v.trim().isEmpty) return 'Укажите значение';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Введите целое число';
    if (min != null && n < min) return 'Минимум $min';
    if (max != null && n > max) return 'Максимум $max';
    return null;
  }

  void _onSave(BuildContext context, WidgetRef ref) {
    final st = ref.read(knowledgeEditProvider(initial));
    if (st.chunkOverlapTokens >= st.maxChunkSizeTokens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('chunk_overlap_tokens должен быть меньше max_chunk_size_tokens')),
      );
      return;
    }
    final updated = ref.read(knowledgeEditProvider(initial).notifier).buildResult(initial);
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(knowledgeEditProvider(initial));
    final ctrl = ref.read(knowledgeEditProvider(initial).notifier);

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Источник знаний',
        backPath: '/assistant/$assistantId/knowledge',
        backTooltip: 'К списку источников',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onSave(context, ref),
        tooltip: 'Сохранить',
        child: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              initialValue: st.externalId,
              decoration: const InputDecoration(labelText: 'external_id'),
              validator: _req,
              onChanged: ctrl.setExternalId,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_edit_provider.dart';

/// Диалог редактирования источника знаний (ConsumerWidget)
class KnowledgeEditorDialog extends ConsumerWidget {
  const KnowledgeEditorDialog({super.key, required this.initial});
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
    return AlertDialog(
      title: const Text('Источник знаний'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: st.ttlDays.toString(),
                      decoration: const InputDecoration(labelText: 'ttl_days'),
                      keyboardType: TextInputType.number,
                      validator: (v) => _vInt(v, min: 1),
                      onChanged: (v) {
                        final n = int.tryParse(v.trim());
                        if (n != null) ctrl.setTtl(n);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: st.expirationPolicy,
                      items: const [
                        DropdownMenuItem(value: 'since_last_active', child: Text('since_last_active')),
                        DropdownMenuItem(value: 'fixed_date', child: Text('fixed_date')),
                      ],
                      onChanged: (v) => ctrl.setExpiration(v ?? 'since_last_active'),
                      decoration: const InputDecoration(labelText: 'expiration_policy'),
                    ),
                  ),
                ],
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

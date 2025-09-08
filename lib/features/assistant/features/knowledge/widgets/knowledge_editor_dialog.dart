import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';

/// Диалог редактирования источника знаний
class KnowledgeEditorDialog extends StatefulWidget {
  const KnowledgeEditorDialog({super.key, required this.initial});

  final KnowledgeBaseItem initial;

  @override
  State<KnowledgeEditorDialog> createState() => _KnowledgeEditorDialogState();
}

class _KnowledgeEditorDialogState extends State<KnowledgeEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _externalId;
  late TextEditingController _markdown;
  late TextEditingController _maxChunk;
  late TextEditingController _overlap;
  late TextEditingController _ttlDays;
  String _expirationPolicy = 'since_last_active';

  @override
  void initState() {
    super.initState();
    _externalId = TextEditingController(text: widget.initial.externalId);
    _markdown = TextEditingController(text: widget.initial.markdown);
    _maxChunk = TextEditingController(text: widget.initial.maxChunkSizeTokens.toString());
    _overlap = TextEditingController(text: widget.initial.chunkOverlapTokens.toString());
    _ttlDays = TextEditingController(text: widget.initial.ttlDays.toString());
    _expirationPolicy = widget.initial.expirationPolicy;
  }

  @override
  void dispose() {
    _externalId.dispose();
    _markdown.dispose();
    _maxChunk.dispose();
    _overlap.dispose();
    _ttlDays.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  String? _vInt(String? v, {int? min, int? max}) {
    if (v == null || v.trim().isEmpty) return 'Укажите значение';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Введите целое число';
    if (min != null && n < min) return 'Минимум $min';
    if (max != null && n > max) return 'Максимум $max';
    return null;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final maxChunk = int.parse(_maxChunk.text.trim());
    final overlap = int.parse(_overlap.text.trim());
    final ttl = int.parse(_ttlDays.text.trim());
    if (overlap >= maxChunk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('chunk_overlap_tokens должен быть меньше max_chunk_size_tokens')),
      );
      return;
    }
    final updated = widget.initial.copyWith(
      externalId: _externalId.text.trim(),
      markdown: _markdown.text,
      maxChunkSizeTokens: maxChunk,
      chunkOverlapTokens: overlap,
      ttlDays: ttl,
      expirationPolicy: _expirationPolicy,
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Источник знаний'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _externalId,
                  decoration: const InputDecoration(labelText: 'external_id'),
                  validator: _req,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _markdown,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'markdown',
                    helperText: 'Контент (markdown). Рекомендовано не слишком большие тексты.',
                  ),
                  validator: _req,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxChunk,
                        decoration: const InputDecoration(labelText: 'max_chunk_size_tokens'),
                        keyboardType: TextInputType.number,
                        validator: (v) => _vInt(v, min: 100, max: 2000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _overlap,
                        decoration: const InputDecoration(labelText: 'chunk_overlap_tokens'),
                        keyboardType: TextInputType.number,
                        validator: (v) => _vInt(v, min: 0, max: 1000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ttlDays,
                        decoration: const InputDecoration(labelText: 'ttl_days'),
                        keyboardType: TextInputType.number,
                        validator: (v) => _vInt(v, min: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _expirationPolicy,
                        items: const [
                          DropdownMenuItem(value: 'since_last_active', child: Text('since_last_active')),
                          DropdownMenuItem(value: 'fixed_date', child: Text('fixed_date')),
                        ],
                        onChanged: (v) => setState(() => _expirationPolicy = v ?? 'since_last_active'),
                        decoration: const InputDecoration(labelText: 'expiration_policy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _onSave, child: const Text('Сохранить')),
      ],
    );
  }
}

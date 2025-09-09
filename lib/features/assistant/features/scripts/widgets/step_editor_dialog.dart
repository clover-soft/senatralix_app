import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';

/// Диалог редактирования шага скрипта (отдельный файл)
class StepEditorDialog extends ConsumerWidget {
  const StepEditorDialog({super.key, required this.initial});
  final ScriptStep initial;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = initial.title;
    String spec = initial.spec;

    return AlertDialog(
      title: const Text('Шаг скрипта'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: 'Название шага'),
                validator: _req,
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: spec,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Шаг (JSON spec)',
                  helperText:
                      '{ "when": {"jsonpath": "..."}, "action": { "type": "http_get|http_post", "http": { ... } } }',
                ),
                validator: _req,
                onChanged: (v) => spec = v,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            if ((title.trim().isEmpty) || (spec.trim().isEmpty)) return;
            Navigator.pop(
              context,
              initial.copyWith(title: title.trim(), spec: spec),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

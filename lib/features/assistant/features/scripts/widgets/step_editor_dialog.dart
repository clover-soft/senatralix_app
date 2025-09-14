import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/json.dart' as hl_json;
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/spec_validation_provider.dart';

/// Диалог редактирования шага скрипта (отдельный файл)
class StepEditorDialog extends ConsumerWidget {
  const StepEditorDialog({super.key, required this.initial});
  final ScriptStep initial;

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = initial.title;
    String spec = initial.spec;
    final stepKey = initial.id.isEmpty ? 'new' : initial.id;
    final specError = ref.watch(specErrorProvider(stepKey));

    final codeController = CodeController(
      text: spec,
      language: hl_json.json,
      patternMap: {},
    );

    codeController.addListener(() {
      spec = codeController.text;
      try {
        json.decode(spec);
        ref.read(specErrorProvider(stepKey).notifier).state = null;
      } catch (e) {
        ref.read(specErrorProvider(stepKey).notifier).state = e.toString();
      }
    });

    void formatJson() {
      try {
        final obj = json.decode(codeController.text);
        final pretty = const JsonEncoder.withIndent('  ').convert(obj);
        codeController.text = pretty;
      } catch (_) {
        // ошибка уже подсвечена — ничего не делаем
      }
    }

    Future<void> copyJson() async {
      await Clipboard.setData(ClipboardData(text: codeController.text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON скопирован в буфер обмена')),
        );
      }
    }

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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Шаг (JSON spec)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: specError == null
                        ? Theme.of(context).dividerColor
                        : Theme.of(context).colorScheme.error,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 240,
                    child: CodeField(
                      controller: codeController,
                      textStyle: const TextStyle(
                        fontFamily: 'SourceCodePro',
                        fontSize: 13,
                      ),
                      expands: false,
                      lineNumberStyle: const LineNumberStyle(width: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: formatJson,
                    icon: const Icon(Icons.format_align_left),
                    label: const Text('Форматировать JSON'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: copyJson,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Копировать JSON'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  specError == null
                      ? '{ "when": {"jsonpath": "..."}, "action": { ... } }'
                      : 'Ошибка: $specError',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: specError == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).colorScheme.error,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if ((title.trim().isEmpty) || (spec.trim().isEmpty)) return;
            // финальная проверка JSON
            try {
              json.decode(spec);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Исправьте JSON в поле spec')),
              );
              return;
            }
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

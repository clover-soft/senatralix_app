import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/tools/providers/function_tool_edit_provider.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';

/// Диалог редактирования Function Tool (Riverpod + ConsumerWidget)
class FunctionToolDialog extends ConsumerWidget {
  const FunctionToolDialog({super.key, required this.initial});
  final AssistantFunctionTool initial;

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите имя';
    if (v.trim().length < 2 || v.trim().length > 40) {
      return 'Длина 2–40 символов';
    }
    return null;
  }

  String? _vDesc(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите описание';
    if (v.trim().length > 280) {
      return 'Не более 280 символов';
    }
    return null;
  }

  void _onSave(BuildContext context, WidgetRef ref) {
    try {
      final updated = ref
          .read(functionToolEditProvider(initial).notifier)
          .buildResult(initial);
      Navigator.pop(context, updated);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка в parameters: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(functionToolEditProvider(initial));
    final ctrl = ref.read(functionToolEditProvider(initial).notifier);
    return AlertDialog(
      title: const Text('Function Tool'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: state.name,
                decoration: const InputDecoration(labelText: 'name'),
                validator: _vName,
                onChanged: ctrl.setName,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.description,
                decoration: const InputDecoration(labelText: 'description'),
                validator: _vDesc,
                onChanged: ctrl.setDescription,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.parametersJson,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'parameters (JSON Schema object)',
                  helperText:
                      '{ "type": "object", "properties": { ... }, "required": [ ... ] }',
                ),
                onChanged: ctrl.setParametersJson,
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
          onPressed: () => _onSave(context, ref),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

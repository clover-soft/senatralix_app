import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';

/// Диалог редактирования Function Tool
class FunctionToolDialog extends StatefulWidget {
  const FunctionToolDialog({super.key, required this.initial});
  final AssistantFunctionTool initial;

  @override
  State<FunctionToolDialog> createState() => _FunctionToolDialogState();
}

class _FunctionToolDialogState extends State<FunctionToolDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _paramsJson;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.def.name);
    _desc = TextEditingController(text: widget.initial.def.description);
    _paramsJson = TextEditingController(
      text: widget.initial.def.parameters?.toJson() != null
          ? const JsonEncoder.withIndent('  ').convert(widget.initial.def.parameters!.toJson())
          : const JsonEncoder.withIndent('  ').convert({
              'type': 'object',
              'properties': {},
              'required': [],
            }),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _paramsJson.dispose();
    super.dispose();
  }

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите имя';
    if (v.trim().length < 2 || v.trim().length > 40) return 'Длина 2–40 символов';
    return null;
  }

  String? _vDesc(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите описание';
    if (v.trim().length > 280) return 'Не более 280 символов';
    return null;
  }

  JsonSchemaObject _parseParams(String raw) {
    final obj = json.decode(raw);
    if (obj is! Map<String, dynamic>) {
      throw const FormatException('JSON должен быть объектом');
    }
    return JsonSchemaObject.fromJson(obj);
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    try {
      final schema = _parseParams(_paramsJson.text);
      final updated = widget.initial.copyWith(
        def: widget.initial.def.copyWith(
          name: _name.text.trim(),
          description: _desc.text.trim(),
          parameters: schema,
        ),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка в parameters: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Function Tool'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'name'),
                  validator: _vName,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'description'),
                  validator: _vDesc,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paramsJson,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'parameters (JSON Schema object)',
                    helperText: '{ "type": "object", "properties": { ... }, "required": [ ... ] }',
                  ),
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

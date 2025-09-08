import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_tools_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantToolsScreen extends ConsumerStatefulWidget {
  const AssistantToolsScreen({super.key});

  @override
  ConsumerState<AssistantToolsScreen> createState() => _AssistantToolsScreenState();
}

class _AssistantToolsScreenState extends ConsumerState<AssistantToolsScreen> {
  late String _assistantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  void _addPreset(String preset) {
    final notifier = ref.read(assistantToolsProvider.notifier);
    Map<String, dynamic> fn;
    if (preset == 'transferCall') {
      fn = {
        'function': {
          'name': 'transferCall',
          'description': 'Переводит текущий звонок на указанного сотрудника и произносит прощальную фразу',
          'parameters': {
            'type': 'object',
            'properties': {
              'employee_extension': {
                'type': 'string',
                'description': 'Внутренний номер сотрудника компании, на который нужно перевести звонок'
              },
              'farewell_phrase': {
                'type': 'string',
                'description': 'Фраза, которую необходимо произнести абоненту перед переводом звонка'
              }
            },
            'required': ['employee_extension', 'farewell_phrase']
          }
        }
      };
    } else if (preset == 'hangupCall') {
      fn = {
        'function': {
          'name': 'hangupCall',
          'description': 'Инструмент для завершения звонка',
          'parameters': {
            'type': 'object',
            'properties': {
              'farewell_phrase': {
                'type': 'string',
                'description': 'Фраза прощания (на естественном русском языке)'
              }
            },
            'required': ['farewell_phrase']
          }
        }
      };
    } else {
      fn = {
        'function': {
          'name': 'newFunction',
          'description': 'Описание',
          'parameters': {
            'type': 'object',
            'properties': {},
            'required': []
          }
        }
      };
    }
    final tool = notifier.fromPresetJson(DateTime.now().millisecondsSinceEpoch.toString(), fn);
    notifier.add(_assistantId, tool);
  }

  void _editTool(AssistantFunctionTool tool) async {
    final result = await showDialog<AssistantFunctionTool>(
      context: context,
      builder: (context) => _FunctionToolDialog(initial: tool),
    );
    if (result != null) {
      ref.read(assistantToolsProvider.notifier).update(_assistantId, result);
    }
  }

  void _removeTool(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить инструмент?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(assistantToolsProvider.notifier).remove(_assistantId, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = ref.watch(assistantToolsProvider.select((s) => s.byAssistantId[_assistantId] ?? const []));
    return Scaffold(
      appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Tools'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить инструмент',
        child: const Icon(Icons.add),
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Пустой Function'),
                    onTap: () => Navigator.pop(ctx, 'new'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.call_split_outlined),
                    title: const Text('Пресет: transferCall'),
                    onTap: () => Navigator.pop(ctx, 'transferCall'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.call_end_outlined),
                    title: const Text('Пресет: hangupCall'),
                    onTap: () => Navigator.pop(ctx, 'hangupCall'),
                  ),
                ],
              ),
            ),
          );
          if (choice != null) _addPreset(choice);
        },
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final t = tools[index];
          return Card(
            child: ListTile(
              leading: Switch(
                value: t.enabled,
                onChanged: (v) => ref.read(assistantToolsProvider.notifier).toggleEnabled(_assistantId, t.id, v),
              ),
              title: Text(t.def.name),
              subtitle: Text(t.def.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editTool(t),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeTool(t.id),
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

class _FunctionToolDialog extends StatefulWidget {
  const _FunctionToolDialog({required this.initial});
  final AssistantFunctionTool initial;

  @override
  State<_FunctionToolDialog> createState() => _FunctionToolDialogState();
}

class _FunctionToolDialogState extends State<_FunctionToolDialog> {
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

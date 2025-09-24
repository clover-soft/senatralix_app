import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/presets/script_action_presets.dart';
import '../data/presets/script_action_preset.dart';
import '../models/script_action_config.dart';
import '../models/script_command_step.dart';

/// Модальное окно редактирования шага скрипта
class ScriptStepEditorDialog extends StatefulWidget {
  const ScriptStepEditorDialog({
    super.key,
    required this.step,
  });

  final ScriptCommandStep step;

  @override
  State<ScriptStepEditorDialog> createState() => _ScriptStepEditorDialogState();
}

class _ScriptStepEditorDialogState extends State<ScriptStepEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late String _actionName;
  ScriptActionPreset? _currentPreset;
  late Map<String, ScriptActionValue> _inputs;
  ScriptActionOutputs? _outputs;
  ScriptActionOptions? _options;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step.name);
    _initConfig();
  }

  void _initConfig() {
    final existingConfig = widget.step.actionConfig;
    if (existingConfig != null) {
      _actionName = existingConfig.actionName;
      _inputs = Map<String, ScriptActionValue>.from(existingConfig.inputs);
      _outputs = existingConfig.outputs;
      _options = existingConfig.options;
      _currentPreset = findScriptActionPreset(existingConfig.actionName);
    } else {
      _currentPreset = kScriptActionPresets.isNotEmpty
          ? kScriptActionPresets.first
          : null;
      final presetConfig =
          _currentPreset?.createDefaultConfig() ?? _fallbackConfig();
      _actionName = presetConfig.actionName;
      _inputs = Map<String, ScriptActionValue>.from(presetConfig.inputs);
      _outputs = presetConfig.outputs;
      _options = presetConfig.options;
    }
    // Если шага не нашли в списке пресетов, но конфиг есть
    _currentPreset ??= findScriptActionPreset(_actionName);
  }

  ScriptActionConfig _fallbackConfig() {
    return const ScriptActionConfig(
      actionName: '',
      inputs: <String, ScriptActionValue>{},
      outputs: null,
      options: null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Редактирование шага'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 540),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPresetDropdown(theme),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название шага'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Укажите название шага';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((_currentPreset?.inputFields ?? []).isNotEmpty)
                        ..._buildInputsSection(theme),
                      if ((_currentPreset?.outputFields ?? []).isNotEmpty)
                        ..._buildOutputsSection(theme),
                      if ((_currentPreset?.optionFields ?? []).isNotEmpty)
                        ..._buildOptionsSection(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Widget _buildPresetDropdown(ThemeData theme) {
    final presets = kScriptActionPresets;
    return DropdownButtonFormField<String>(
      initialValue: presets.any((p) => p.actionName == _actionName)
          ? _actionName
          : null,
      decoration: const InputDecoration(
        labelText: 'Пресет действия',
        helperText: 'Определяет набор полей и их значения по умолчанию',
      ),
      items: [
        for (final preset in presets)
          DropdownMenuItem<String>(
            value: preset.actionName,
            child: Text(preset.title),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        final preset = presets.firstWhere((p) => p.actionName == value);
        setState(() {
          _actionName = preset.actionName;
          _currentPreset = preset;
          final config = preset.createDefaultConfig();
          _inputs = Map<String, ScriptActionValue>.from(config.inputs);
          _outputs = config.outputs;
          _options = config.options;
        });
      },
    );
  }

  List<Widget> _buildInputsSection(ThemeData theme) {
    final fields = _currentPreset?.inputFields ?? const [];
    return [
      Text(
        'Входные параметры',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      for (final field in fields) ...[
        _buildInputField(theme, field),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildInputField(
    ThemeData theme,
    ScriptActionInputFieldSchema field,
  ) {
    final value = _inputs[field.key] ?? const ScriptActionValue();
    final literalStr = _stringifyLiteral(value.literal);
    final hasSelect =
        (field.allowedValues != null && field.allowedValues!.isNotEmpty);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (field.description != null && field.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                field.description!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            if (field.type == ScriptActionFieldType.boolean)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Значение'),
                value: (value.literal is bool) ? value.literal as bool : false,
                onChanged: (val) {
                  _updateInput(field.key, value.copyWith(literal: val));
                },
              )
            else if (hasSelect)
              DropdownButtonFormField<String>(
                initialValue: value.literal?.toString(),
                decoration: InputDecoration(
                  labelText:
                      field.key == 'method' ? 'Метод' : 'Literal',
                ),
                items: [
                  for (final option in field.allowedValues!)
                    DropdownMenuItem<String>(
                      value: option.toString(),
                      child: Text(option.toString()),
                    ),
                ],
                onChanged: (selected) {
                  _updateInput(
                    field.key,
                    value.copyWith(literal: selected),
                  );
                },
              )
            else
              TextFormField(
                key: ValueKey('input-literal-${field.key}-$_actionName'),
                initialValue: literalStr,
                decoration: const InputDecoration(labelText: 'Literal'),
                maxLines: _isMultiline(field.type) ? 5 : 1,
                onChanged: (text) {
                  final parsed = _parseLiteral(text, field.type);
                  _updateInput(field.key, value.copyWith(literal: parsed));
                },
              ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('input-from-${field.key}-$_actionName'),
              initialValue: value.from ?? '',
              decoration: const InputDecoration(labelText: 'From'),
              onChanged: (text) {
                _updateInput(field.key, value.copyWith(from: _emptyToNull(text)));
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('input-transform-${field.key}-$_actionName'),
              initialValue: value.transform ?? '',
              decoration: const InputDecoration(labelText: 'Transform'),
              onChanged: (text) {
                _updateInput(
                  field.key,
                  value.copyWith(transform: _emptyToNull(text)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOutputsSection(ThemeData theme) {
    final fields = _currentPreset?.outputFields ?? const [];
    final current = _outputs ?? const ScriptActionOutputs();
    return [
      const SizedBox(height: 12),
      Text(
        'Выходные параметры',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      for (final field in fields) ...[
        _buildOutputField(theme, field, current),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildOutputField(
    ThemeData theme,
    ScriptActionOutputFieldSchema field,
    ScriptActionOutputs current,
  ) {
    String initialValue;
    switch (field.key) {
      case 'to':
        initialValue = current.to ?? '';
        break;
      case 'extract_jsonpath':
        initialValue = current.extractJsonPath ?? '';
        break;
      case 'map':
        initialValue = _stringifyLiteral(current.map);
        break;
      default:
        initialValue = '';
    }

    final isMultiline =
        field.type == ScriptActionFieldType.json ||
            field.type == ScriptActionFieldType.map ||
            field.type == ScriptActionFieldType.list;

    return TextFormField(
      key: ValueKey('output-${field.key}-$_actionName'),
      initialValue: initialValue,
      decoration: InputDecoration(labelText: field.label),
      maxLines: isMultiline ? 5 : 1,
      onChanged: (text) {
        setState(() {
          final parsed = _parseLiteral(text, field.type);
          _outputs = ( _outputs ?? const ScriptActionOutputs() ).copyWith(
            to: field.key == 'to' ? _emptyToNull(text) : current.to,
            extractJsonPath: field.key == 'extract_jsonpath'
                ? _emptyToNull(text)
                : current.extractJsonPath,
            map: field.key == 'map' ? parsed as Map<String, dynamic>? : current.map,
          );
        });
      },
    );
  }

  List<Widget> _buildOptionsSection(ThemeData theme) {
    final fields = _currentPreset?.optionFields ?? const [];
    final current = _options ?? const ScriptActionOptions();
    return [
      const SizedBox(height: 12),
      Text(
        'Опции выполнения',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      for (final field in fields) ...[
        _buildOptionField(theme, field, current),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildOptionField(
    ThemeData theme,
    ScriptActionOptionFieldSchema field,
    ScriptActionOptions current,
  ) {
    switch (field.key) {
      case 'required_inputs':
        final initial = (current.requiredInputs ?? []).join(', ');
        return TextFormField(
          key: ValueKey('option-${field.key}-$_actionName'),
          initialValue: initial,
          decoration: InputDecoration(labelText: field.label),
          onChanged: (text) {
            final list = text
                .split(',')
                .map((e) => e.trim())
                .where((element) => element.isNotEmpty)
                .toList();
            setState(() {
              _options = ( _options ?? const ScriptActionOptions() )
                  .copyWith(requiredInputs: list.isEmpty ? null : list);
            });
          },
        );
      case 'on_error':
        final options = field.allowedValues ?? const ['skip', 'fail'];
        final currentValue = current.onError ??
            (options.isNotEmpty ? options.first.toString() : null);
        return DropdownButtonFormField<String>(
          key: ValueKey('option-${field.key}-$_actionName'),
          initialValue: current.onError ?? currentValue,
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final val in options)
              DropdownMenuItem<String>(
                value: val.toString(),
                child: Text(val.toString()),
              ),
          ],
          onChanged: (selected) {
            setState(() {
              _options = ( _options ?? const ScriptActionOptions() )
                  .copyWith(onError: selected);
            });
          },
        );
      default:
        return TextFormField(
          key: ValueKey('option-${field.key}-$_actionName'),
          initialValue: '',
          decoration: InputDecoration(labelText: field.label),
          onChanged: (_) {},
        );
    }
  }

  void _updateInput(String key, ScriptActionValue value) {
    setState(() {
      _inputs[key] = value;
    });
  }

  bool _isMultiline(ScriptActionFieldType type) {
    return type == ScriptActionFieldType.map ||
        type == ScriptActionFieldType.json ||
        type == ScriptActionFieldType.template ||
        type == ScriptActionFieldType.list;
  }

  dynamic _parseLiteral(String text, ScriptActionFieldType type) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    switch (type) {
      case ScriptActionFieldType.number:
        return num.tryParse(trimmed) ?? trimmed;
      case ScriptActionFieldType.boolean:
        return trimmed.toLowerCase() == 'true';
      case ScriptActionFieldType.map:
      case ScriptActionFieldType.list:
      case ScriptActionFieldType.json:
        try {
          return jsonDecode(trimmed);
        } catch (_) {
          return trimmed;
        }
      default:
        return trimmed;
    }
  }

  String _stringifyLiteral(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final updatedConfig = ScriptActionConfig(
      actionName: _actionName,
      inputs: Map<String, ScriptActionValue>.from(_inputs),
      outputs: _outputs,
      options: _options,
    );

    final updatedStep = widget.step.copyWith(
      name: _nameController.text.trim(),
      actionConfig: updatedConfig,
    );

    Navigator.of(context).pop(updatedStep);
  }
}

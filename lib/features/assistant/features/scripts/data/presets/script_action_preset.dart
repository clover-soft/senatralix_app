import 'package:flutter/foundation.dart';

import '../../models/script_action_config.dart';

/// Тип входного поля/параметра в конфигурации действия
enum ScriptActionFieldType {
  text,
  number,
  boolean,
  json,
  map,
  list,
  select,
  template,
  duration,
}

/// Схема входного параметра действия
@immutable
class ScriptActionInputFieldSchema {
  const ScriptActionInputFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.allowedValues,
    this.defaultValue,
  });

  final String key;
  final String label;
  final ScriptActionFieldType type;
  final String? description;
  final bool required;
  final List<dynamic>? allowedValues;
  final ScriptActionValue? defaultValue;
}

/// Схема выходного параметра действия
@immutable
class ScriptActionOutputFieldSchema {
  const ScriptActionOutputFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.allowedValues,
    this.defaultValue,
  });

  final String key;
  final String label;
  final ScriptActionFieldType type;
  final String? description;
  final bool required;
  final List<dynamic>? allowedValues;
  final dynamic defaultValue;
}

/// Схема опции выполнения действия
@immutable
class ScriptActionOptionFieldSchema {
  const ScriptActionOptionFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.allowedValues,
    this.defaultValue,
  });

  final String key;
  final String label;
  final ScriptActionFieldType type;
  final String? description;
  final bool required;
  final List<dynamic>? allowedValues;
  final dynamic defaultValue;
}

/// Пресет действия шага скрипта
@immutable
class ScriptActionPreset {
  const ScriptActionPreset({
    required this.actionName,
    required this.title,
    this.description,
    this.inputFields = const <ScriptActionInputFieldSchema>[],
    this.outputFields = const <ScriptActionOutputFieldSchema>[],
    this.optionFields = const <ScriptActionOptionFieldSchema>[],
  });

  final String actionName;
  final String title;
  final String? description;
  final List<ScriptActionInputFieldSchema> inputFields;
  final List<ScriptActionOutputFieldSchema> outputFields;
  final List<ScriptActionOptionFieldSchema> optionFields;

  /// Формирует конфигурацию по умолчанию на основе значений пресета
  ScriptActionConfig createDefaultConfig() {
    final inputs = <String, ScriptActionValue>{};
    for (final field in inputFields) {
      final defaultValue = field.defaultValue;
      if (defaultValue != null) {
        inputs[field.key] = defaultValue;
      }
    }

    final outputs = _buildOutputs();
    final options = _buildOptions();

    return ScriptActionConfig(
      actionName: actionName,
      inputs: inputs,
      outputs: outputs,
      options: options,
    );
  }

  ScriptActionOutputs? _buildOutputs() {
    if (outputFields.isEmpty) return null;

    String? to;
    String? extractJsonPath;
    Map<String, dynamic>? map;

    for (final field in outputFields) {
      final value = field.defaultValue;
      switch (field.key) {
        case 'to':
          to = value?.toString();
          break;
        case 'extract_jsonpath':
          extractJsonPath = value?.toString();
          break;
        case 'map':
          if (value is Map) {
            map = Map<String, dynamic>.from(value);
          }
          break;
        default:
          break;
      }
    }

    if (to == null && extractJsonPath == null && map == null) {
      return null;
    }

    return ScriptActionOutputs(
      to: to,
      extractJsonPath: extractJsonPath,
      map: map,
    );
  }

  ScriptActionOptions? _buildOptions() {
    if (optionFields.isEmpty) return null;

    List<String>? requiredInputs;
    String? onError;

    for (final field in optionFields) {
      final value = field.defaultValue;
      switch (field.key) {
        case 'required_inputs':
          if (value is List) {
            requiredInputs = value.map((e) => e.toString()).toList();
          }
          break;
        case 'on_error':
          onError = value?.toString();
          break;
        default:
          break;
      }
    }

    if (requiredInputs == null && onError == null) {
      return null;
    }

    return ScriptActionOptions(
      requiredInputs: requiredInputs,
      onError: onError,
    );
  }
}

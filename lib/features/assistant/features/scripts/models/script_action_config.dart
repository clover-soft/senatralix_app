import 'package:flutter/foundation.dart';

/// Конфигурация действия шага скрипта ассистента
@immutable
class ScriptActionConfig {
  const ScriptActionConfig({
    required this.actionName,
    this.inputs = const <String, ScriptActionValue>{},
    this.outputs,
    this.options,
  });

  /// Уникальное имя действия, приходящее от бэкенда
  final String actionName;

  /// Карта входных параметров действия
  final Map<String, ScriptActionValue> inputs;

  /// Конфигурация выходных значений действия
  final ScriptActionOutputs? outputs;

  /// Дополнительные опции выполнения действия
  final ScriptActionOptions? options;

  ScriptActionConfig copyWith({
    String? actionName,
    Map<String, ScriptActionValue>? inputs,
    ScriptActionOutputs? outputs,
    ScriptActionOptions? options,
  }) {
    return ScriptActionConfig(
      actionName: actionName ?? this.actionName,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      options: options ?? this.options,
    );
  }

  factory ScriptActionConfig.fromJson(Map<String, dynamic> json) {
    return ScriptActionConfig(
      actionName: (json['action_name'] ?? '').toString(),
      inputs: _parseInputs(json['inputs']),
      outputs: json['outputs'] is Map
          ? ScriptActionOutputs.fromJson(
              Map<String, dynamic>.from(json['outputs'] as Map),
            )
          : null,
      options: json['options'] is Map
          ? ScriptActionOptions.fromJson(
              Map<String, dynamic>.from(json['options'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'action_name': actionName,
      if (inputs.isNotEmpty)
        'inputs': inputs.map((key, value) => MapEntry(key, value.toJson())),
      if (outputs != null) 'outputs': outputs!.toJson(),
      if (options != null) 'options': options!.toJson(),
    };
  }

  static Map<String, ScriptActionValue> _parseInputs(dynamic raw) {
    if (raw is Map) {
      return raw.map<String, ScriptActionValue>((key, value) {
        return MapEntry(
          key.toString(),
          ScriptActionValue.fromJson(Map<String, dynamic>.from(value as Map)),
        );
      });
    }
    return const <String, ScriptActionValue>{};
  }
}

/// Описание входного параметра действия
@immutable
class ScriptActionValue {
  const ScriptActionValue({
    this.literal,
    this.from,
    this.transform,
  });

  final dynamic literal;
  final String? from;
  final String? transform;

  ScriptActionValue copyWith({
    dynamic literal,
    String? from,
    String? transform,
  }) {
    return ScriptActionValue(
      literal: literal ?? this.literal,
      from: from ?? this.from,
      transform: transform ?? this.transform,
    );
  }

  factory ScriptActionValue.fromJson(Map<String, dynamic> json) {
    return ScriptActionValue(
      literal: json.containsKey('literal') ? json['literal'] : null,
      from: json['from']?.toString(),
      transform: json['transform']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'literal': literal,
      'from': from,
      'transform': transform,
    };
  }
}

/// Конфигурация выхода действия
@immutable
class ScriptActionOutputs {
  const ScriptActionOutputs({
    this.to,
    this.extractJsonPath,
    this.map,
  });

  final String? to;
  final String? extractJsonPath;
  final Map<String, dynamic>? map;

  ScriptActionOutputs copyWith({
    String? to,
    String? extractJsonPath,
    Map<String, dynamic>? map,
  }) {
    return ScriptActionOutputs(
      to: to ?? this.to,
      extractJsonPath: extractJsonPath ?? this.extractJsonPath,
      map: map ?? this.map,
    );
  }

  factory ScriptActionOutputs.fromJson(Map<String, dynamic> json) {
    return ScriptActionOutputs(
      to: json['to']?.toString(),
      extractJsonPath: json['extract_jsonpath']?.toString(),
      map: json['map'] is Map
          ? Map<String, dynamic>.from(json['map'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'to': to,
      'extract_jsonpath': extractJsonPath,
      'map': map,
    };
  }
}

/// Дополнительные опции выполнения действия
@immutable
class ScriptActionOptions {
  const ScriptActionOptions({
    this.requiredInputs,
    this.onError,
  });

  final List<String>? requiredInputs;
  final String? onError;

  ScriptActionOptions copyWith({
    List<String>? requiredInputs,
    String? onError,
  }) {
    return ScriptActionOptions(
      requiredInputs: requiredInputs ?? this.requiredInputs,
      onError: onError ?? this.onError,
    );
  }

  factory ScriptActionOptions.fromJson(Map<String, dynamic> json) {
    return ScriptActionOptions(
      requiredInputs: json['required_inputs'] is List
          ? (json['required_inputs'] as List)
              .map((e) => e.toString())
              .toList(growable: false)
          : null,
      onError: json['on_error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'required_inputs': requiredInputs,
      'on_error': onError,
    };
  }
}

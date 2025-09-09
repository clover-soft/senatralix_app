import 'package:flutter/foundation.dart';

@immutable
class ScriptStep {
  final String id;
  final String title; // пользовательское название шага
  final String spec; // JSON-текст шага (описание команды с применением JSONPath)

  const ScriptStep({
    required this.id,
    required this.title,
    required this.spec,
  });

  ScriptStep copyWith({String? id, String? title, String? spec}) => ScriptStep(
        id: id ?? this.id,
        title: title ?? this.title,
        spec: spec ?? this.spec,
      );

  factory ScriptStep.fromJson(Map<String, dynamic> json) => ScriptStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        spec: json['spec'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'spec': spec,
      };
}

enum ScriptTrigger { onDialogStart, onDialogEnd }

@immutable
class Script {
  final String id;
  final String name;
  final bool enabled;
  final ScriptTrigger trigger;
  final Map<String, String> params;
  final List<ScriptStep> steps;

  const Script({
    required this.id,
    required this.name,
    required this.enabled,
    required this.trigger,
    required this.params,
    required this.steps,
  });

  Script copyWith({
    String? id,
    String? name,
    bool? enabled,
    ScriptTrigger? trigger,
    Map<String, String>? params,
    List<ScriptStep>? steps,
  }) => Script(
        id: id ?? this.id,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        trigger: trigger ?? this.trigger,
        params: params ?? this.params,
        steps: steps ?? this.steps,
      );

  factory Script.fromJson(Map<String, dynamic> json) => Script(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        trigger: ((json['trigger'] as String? ?? 'on_dialog_start') == 'on_dialog_end')
            ? ScriptTrigger.onDialogEnd
            : ScriptTrigger.onDialogStart,
        params: (json['params'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {},
        steps: (json['steps'] as List?)
                ?.map((e) => ScriptStep.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const <ScriptStep>[],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'trigger': trigger == ScriptTrigger.onDialogEnd ? 'on_dialog_end' : 'on_dialog_start',
        'params': params,
        'steps': steps.map((e) => e.toJson()).toList(),
      };
}

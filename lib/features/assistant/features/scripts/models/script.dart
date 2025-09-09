import 'package:flutter/foundation.dart';

@immutable
class ActionHttp {
  final String url;
  final Map<String, String> headers;
  final Map<String, String> query; // для GET
  final String? bodyTemplate; // для POST

  const ActionHttp({
    required this.url,
    this.headers = const {},
    this.query = const {},
    this.bodyTemplate,
  });

  factory ActionHttp.fromJson(Map<String, dynamic> json) => ActionHttp(
        url: json['url'] as String? ?? '',
        headers: (json['headers'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {},
        query: (json['query'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {},
        bodyTemplate: json['body_template'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        if (headers.isNotEmpty) 'headers': headers,
        if (query.isNotEmpty) 'query': query,
        if (bodyTemplate != null) 'body_template': bodyTemplate,
      };
}

enum ActionType { httpGet, httpPost }

@immutable
class ActionDef {
  final ActionType type;
  final ActionHttp http;

  const ActionDef({required this.type, required this.http});

  factory ActionDef.fromJson(Map<String, dynamic> json) => ActionDef(
        type: (() {
          final t = json['type'] as String? ?? 'http_get';
          return t == 'http_post' ? ActionType.httpPost : ActionType.httpGet;
        })(),
        http: ActionHttp.fromJson(Map<String, dynamic>.from(json['http'] as Map? ?? {})),
      );

  Map<String, dynamic> toJson() => {
        'type': type == ActionType.httpPost ? 'http_post' : 'http_get',
        'http': http.toJson(),
      };
}

@immutable
class ScriptStep {
  final String id;
  final String jsonpath;
  final ActionDef action;

  const ScriptStep({required this.id, required this.jsonpath, required this.action});

  ScriptStep copyWith({String? id, String? jsonpath, ActionDef? action}) => ScriptStep(
        id: id ?? this.id,
        jsonpath: jsonpath ?? this.jsonpath,
        action: action ?? this.action,
      );

  factory ScriptStep.fromJson(Map<String, dynamic> json) => ScriptStep(
        id: json['id'] as String? ?? '',
        jsonpath: json['when']?['jsonpath'] as String? ?? '',
        action: ActionDef.fromJson(Map<String, dynamic>.from(json['action'] as Map? ?? {})),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'when': {'jsonpath': jsonpath},
        'action': action.toJson(),
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

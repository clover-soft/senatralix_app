import 'package:flutter/foundation.dart';

@immutable
class JsonSchemaObject {
  final Map<String, Map<String, dynamic>> properties; // key -> schema
  final List<String> requiredKeys;

  const JsonSchemaObject({
    required this.properties,
    required this.requiredKeys,
  });

  Map<String, dynamic> toJson() => {
        'type': 'object',
        'properties': properties,
        'required': requiredKeys,
      };

  factory JsonSchemaObject.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'object') {
      throw ArgumentError('schema.type must be "object"');
    }
    final props = <String, Map<String, dynamic>>{};
    final rawP = (json['properties'] as Map?) ?? {};
    for (final entry in rawP.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is Map) {
        props[key] = Map<String, dynamic>.from(val);
      } else {
        throw ArgumentError('property "$key" must be an object');
      }
    }
    final rawReq = (json['required'] as List?) ?? const [];
    final req = rawReq.map((e) => e.toString()).toList();
    // ensure required subset
    for (final k in req) {
      if (!props.containsKey(k)) {
        throw ArgumentError('required "$k" is not present in properties');
      }
    }
    return JsonSchemaObject(properties: props, requiredKeys: req);
  }
}

@immutable
class FunctionToolDef {
  final String name;
  final String description;
  final JsonSchemaObject? parameters; // optional for mvp

  const FunctionToolDef({
    required this.name,
    required this.description,
    this.parameters,
  });

  FunctionToolDef copyWith({
    String? name,
    String? description,
    JsonSchemaObject? parameters,
  }) => FunctionToolDef(
        name: name ?? this.name,
        description: description ?? this.description,
        parameters: parameters ?? this.parameters,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (parameters != null) 'parameters': parameters!.toJson(),
      };

  factory FunctionToolDef.fromJson(Map<String, dynamic> json) => FunctionToolDef(
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        parameters: json['parameters'] == null
            ? null
            : JsonSchemaObject.fromJson(Map<String, dynamic>.from(json['parameters'] as Map)),
      );
}

@immutable
class AssistantFunctionTool {
  final String id; // uuid or generated key
  final bool enabled;
  final FunctionToolDef def;

  const AssistantFunctionTool({
    required this.id,
    required this.enabled,
    required this.def,
  });

  AssistantFunctionTool copyWith({bool? enabled, FunctionToolDef? def}) =>
      AssistantFunctionTool(id: id, enabled: enabled ?? this.enabled, def: def ?? this.def);

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'function': def.toJson(),
      };

  factory AssistantFunctionTool.fromJson(Map<String, dynamic> json) => AssistantFunctionTool(
        id: json['id'] as String,
        enabled: json['enabled'] as bool? ?? true,
        def: FunctionToolDef.fromJson(Map<String, dynamic>.from(json['function'] as Map)),
      );
}

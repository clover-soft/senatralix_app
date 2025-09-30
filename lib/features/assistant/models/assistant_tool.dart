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
    if ((json['type'] ?? 'object') != 'object') {
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
    for (final k in req) {
      if (!props.containsKey(k)) {
        throw ArgumentError('required "$k" is not present in properties');
      }
    }
    return JsonSchemaObject(properties: props, requiredKeys: req);
  }
}

@immutable
class AssistantTool {
  final int id;
  final String assistantId;
  final String type;
  final String name;
  final String displayName;
  final String description;
  final JsonSchemaObject? parameters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssistantTool({
    required this.id,
    required this.assistantId,
    required this.type,
    required this.name,
    required this.displayName,
    required this.description,
    required this.parameters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  AssistantTool copyWith({
    String? assistantId,
    String? type,
    String? name,
    String? displayName,
    String? description,
    JsonSchemaObject? parameters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AssistantTool(
    id: id,
    assistantId: assistantId ?? this.assistantId,
    type: type ?? this.type,
    name: name ?? this.name,
    displayName: displayName ?? this.displayName,
    description: description ?? this.description,
    parameters: parameters ?? this.parameters,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory AssistantTool.fromJson(Map<String, dynamic> json) {
    final params = json['parameters'];
    return AssistantTool(
      id: int.tryParse('${json['id']}') ?? 0,
      assistantId: '${json['assistant_id'] ?? ''}',
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      parameters: params is Map<String, dynamic>
          ? JsonSchemaObject.fromJson(Map<String, dynamic>.from(params))
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'assistant_id': assistantId,
    'type': type,
    'name': name,
    'display_name': displayName,
    'description': description,
    if (parameters != null) 'parameters': parameters!.toJson(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

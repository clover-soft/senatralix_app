import 'package:flutter/foundation.dart';

import 'script_action_config.dart';

/// Шаг (thread-command step) внутри скрипта ассистента
@immutable
class ScriptCommandStep {
  final int id;
  final int commandId;
  final String name;
  final int priority;
  final bool isActive;
  final ScriptActionConfig? actionConfig;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ScriptCommandStep({
    required this.id,
    required this.commandId,
    required this.name,
    required this.priority,
    required this.isActive,
    required this.actionConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  ScriptCommandStep copyWith({
    int? id,
    int? commandId,
    String? name,
    int? priority,
    bool? isActive,
    ScriptActionConfig? actionConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScriptCommandStep(
      id: id ?? this.id,
      commandId: commandId ?? this.commandId,
      name: name ?? this.name,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      actionConfig: actionConfig ?? this.actionConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ScriptCommandStep.fromJson(Map<String, dynamic> json) {
    return ScriptCommandStep(
      id: int.tryParse('${json['id']}') ?? 0,
      commandId: int.tryParse('${json['command_id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      priority: int.tryParse('${json['priority']}') ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      actionConfig: json['action_config'] is Map
          ? ScriptActionConfig.fromJson(
              Map<String, dynamic>.from(json['action_config'] as Map),
            )
          : null,
      createdAt: DateTime.tryParse('${json['created_at']}'),
      updatedAt: DateTime.tryParse('${json['updated_at']}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'command_id': commandId,
        'name': name,
        'priority': priority,
        'is_active': isActive,
        'action_config': actionConfig?.toJson(),
      };

  String get actionName => actionConfig?.actionName.trim() ?? '';
}

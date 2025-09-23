import 'package:flutter/foundation.dart';

/// Элемент списка скриптов (thread-commands) из бэкенда
@immutable
class ScriptListItem {
  final int id;
  final int assistantId;
  final int order;
  final String name;
  final String description;
  final String filterExpression;
  final bool isActive;

  const ScriptListItem({
    required this.id,
    required this.assistantId,
    required this.order,
    required this.name,
    required this.description,
    required this.filterExpression,
    required this.isActive,
  });

  ScriptListItem copyWith({
    int? id,
    int? assistantId,
    int? order,
    String? name,
    String? description,
    String? filterExpression,
    bool? isActive,
  }) => ScriptListItem(
        id: id ?? this.id,
        assistantId: assistantId ?? this.assistantId,
        order: order ?? this.order,
        name: name ?? this.name,
        description: description ?? this.description,
        filterExpression: filterExpression ?? this.filterExpression,
        isActive: isActive ?? this.isActive,
      );

  factory ScriptListItem.fromJson(Map<String, dynamic> json) => ScriptListItem(
        id: int.tryParse('${json['id']}') ?? 0,
        assistantId: int.tryParse('${json['assistant_id']}') ?? 0,
        order: int.tryParse('${json['order']}') ?? 0,
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        filterExpression: (json['filter_expression'] ?? '').toString(),
        isActive: (json['is_active'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assistant_id': assistantId,
        'order': order,
        'name': name,
        'description': description,
        'filter_expression': filterExpression,
        'is_active': isActive,
      };
}

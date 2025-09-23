import 'package:flutter/foundation.dart';

/// Состояние формы редактирования команды (thread-command)
@immutable
class ScriptCommandEditState {
  final int order;
  final String name;
  final String description;
  final String filterExpression;
  final bool isActive;

  const ScriptCommandEditState({
    required this.order,
    required this.name,
    required this.description,
    required this.filterExpression,
    required this.isActive,
  });

  factory ScriptCommandEditState.initial() => const ScriptCommandEditState(
        order: 1,
        name: '',
        description: '',
        filterExpression: '',
        isActive: true,
      );

  ScriptCommandEditState copy({
    int? order,
    String? name,
    String? description,
    String? filterExpression,
    bool? isActive,
  }) => ScriptCommandEditState(
        order: order ?? this.order,
        name: name ?? this.name,
        description: description ?? this.description,
        filterExpression: filterExpression ?? this.filterExpression,
        isActive: isActive ?? this.isActive,
      );
}

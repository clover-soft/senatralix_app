
/// Модель шага диалога
class DialogStep {
  final int id;
  final String name;
  final String label;
  final String instructions;
  final List<int> requiredSlotsIds;
  final List<int> optionalSlotsIds;
  final int? next;
  final Map<String, Map<String, int>> branchLogic; // slotId -> {value: nextStepId}

  const DialogStep({
    required this.id,
    required this.name,
    required this.label,
    required this.instructions,
    required this.requiredSlotsIds,
    required this.optionalSlotsIds,
    required this.next,
    required this.branchLogic,
  });

  factory DialogStep.fromJson(Map<String, dynamic> json) {
    final rawBranch = json['branch_logic'] as Map?;
    final normalized = <String, Map<String, int>>{};
    if (rawBranch != null) {
      for (final entry in rawBranch.entries) {
        final inner = Map<String, dynamic>.from(entry.value as Map);
        normalized[entry.key.toString()] = inner.map(
          (k, v) => MapEntry(k.toString(), int.tryParse('$v')),
        ).map((k, v) => MapEntry(k, v ?? 0));
      }
    }
    return DialogStep(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      requiredSlotsIds: List<int>.from((json['required_slots_ids'] as List? ?? const [])
          .map((e) => int.tryParse('$e') ?? 0)),
      optionalSlotsIds: List<int>.from((json['optional_slots_ids'] as List? ?? const [])
          .map((e) => int.tryParse('$e') ?? 0)),
      next: json['next'] == null ? null : int.tryParse('${json['next']}'),
      branchLogic: normalized,
    );
  }

  /// Сериализация шага в формат backend (snake_case поля)
  Map<String, dynamic> toBackendJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'instructions': instructions,
      'required_slots_ids': requiredSlotsIds,
      'optional_slots_ids': optionalSlotsIds,
      'next': next,
      'branch_logic': branchLogic,
    };
  }
}

/// Утилита: сериализовать список шагов в backend-формат
List<Map<String, dynamic>> stepsToBackendJson(List<DialogStep> steps) =>
    steps.map((e) => e.toBackendJson()).toList();

/// Модель краткой конфигурации
class DialogConfigShort {
  final int id;
  final String name;
  final String description;

  const DialogConfigShort({
    required this.id,
    required this.name,
    required this.description,
  });

  factory DialogConfigShort.fromJson(Map<String, dynamic> json) => DialogConfigShort(
        id: int.tryParse('${json['id']}') ?? 0,
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
      );
}

/// Полные детали конфигурации
class DialogConfigDetails {
  final int id;
  final String name;
  final String description;
  final List<DialogStep> steps;
  final Map<String, dynamic> metadata;

  const DialogConfigDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.metadata,
  });

  factory DialogConfigDetails.fromJson(Map<String, dynamic> json) {
    final cfg = Map<String, dynamic>.from(json['config'] as Map);
    final steps = List<Map<String, dynamic>>.from(cfg['steps'] as List);
    return DialogConfigDetails(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      steps: steps.map((e) => DialogStep.fromJson(e)).toList(),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}

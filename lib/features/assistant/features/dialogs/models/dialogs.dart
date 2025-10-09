/// Действие установки/очистки слота при входе/выходе из шага
class SlotSetAction {
  final int slotId;
  final Object? setValue; // произвольный JSON-тип
  final bool setNull;
  final bool clear;
  final bool onlyIfAbsent; // применимо только с setValue

  const SlotSetAction({
    required this.slotId,
    this.setValue,
    this.setNull = false,
    this.clear = false,
    this.onlyIfAbsent = false,
  }) : assert(
         // Ровно одно действие из: clear | setNull | setValue
         (clear ? 1 : 0) + (setNull ? 1 : 0) + (setValue != null ? 1 : 0) == 1,
         'Должно быть задано ровно одно действие: clear, setNull или setValue',
       );

  factory SlotSetAction.fromJson(Map<String, dynamic> json) {
    final slotId = int.tryParse('${json['slot_id']}') ?? 0;
    final isClear = (json['clear'] as bool?) == true;
    final isNull = (json['set_null'] as bool?) == true;
    final hasValue = json.containsKey('set_value');
    final value = json['set_value'];
    final onlyIfAbsent = (json['only_if_absent'] as bool?) == true;
    return SlotSetAction(
      slotId: slotId,
      clear: isClear,
      setNull: isNull,
      setValue: hasValue ? value : null,
      onlyIfAbsent: onlyIfAbsent,
    );
  }

  Map<String, dynamic> toBackendJson() {
    final m = <String, dynamic>{'slot_id': slotId};
    if (clear) {
      m['clear'] = true;
    } else if (setNull) {
      m['set_null'] = true;
    } else {
      // setValue гарантированно не null по assert
      m['set_value'] = setValue;
      if (onlyIfAbsent) m['only_if_absent'] = true;
    }
    return m;
  }
}

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

/// Набор действий для on_enter/on_exit
class StepHookActions {
  final List<SlotSetAction> setSlots;

  const StepHookActions({required this.setSlots});

  bool get isEmpty => setSlots.isEmpty;

  factory StepHookActions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StepHookActions(setSlots: []);
    final raw = List<Map<String, dynamic>>.from(
      (json['set_slots'] as List?) ?? const [],
    );
    return StepHookActions(
      setSlots: raw.map((e) => SlotSetAction.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toBackendJson() => {
        'set_slots': setSlots.map((e) => e.toBackendJson()).toList(),
      };
}

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
  final StepHookActions? onEnter;
  final StepHookActions? onExit;

  const DialogStep({
    required this.id,
    required this.name,
    required this.label,
    required this.instructions,
    required this.requiredSlotsIds,
    required this.optionalSlotsIds,
    required this.next,
    required this.branchLogic,
    this.onEnter,
    this.onExit,
  });

  factory DialogStep.fromJson(Map<String, dynamic> json) {
    final rawBranch = json['branch_logic'] as Map?;
    final normalized = <String, Map<String, int>>{};
    if (rawBranch != null) {
      for (final entry in rawBranch.entries) {
        final inner = Map<String, dynamic>.from(entry.value as Map);
        normalized[entry.key.toString()] = inner
            .map((k, v) => MapEntry(k.toString(), int.tryParse('$v')))
            .map((k, v) => MapEntry(k, v ?? 0));
      }
    }

    final onEnterHook = StepHookActions.fromJson(
      json['on_enter'] is Map ? Map<String, dynamic>.from(json['on_enter']) : null,
    );
    final onExitHook = StepHookActions.fromJson(
      json['on_exit'] is Map ? Map<String, dynamic>.from(json['on_exit']) : null,
    );

    return DialogStep(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      requiredSlotsIds: List<int>.from(
        (json['required_slots_ids'] as List? ?? const [])
            .map((e) => int.tryParse('$e') ?? 0),
      ),
      optionalSlotsIds: List<int>.from(
        (json['optional_slots_ids'] as List? ?? const [])
            .map((e) => int.tryParse('$e') ?? 0),
      ),
      next: json['next'] == null ? null : int.tryParse('${json['next']}'),
      branchLogic: normalized,
      onEnter: onEnterHook.isEmpty ? null : onEnterHook,
      onExit: onExitHook.isEmpty ? null : onExitHook,
    );
  }

  /// Сериализация шага в формат backend (snake_case поля)
  Map<String, dynamic> toBackendJson() {
    // Гарантируем: если задан branch_logic, соответствующий slot_id присутствует в required_slots_ids
    final req = <int>{...requiredSlotsIds};
    if (branchLogic.isNotEmpty) {
      for (final key in branchLogic.keys) {
        final slotId = int.tryParse(key.toString());
        if (slotId != null) req.add(slotId);
      }
    }
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'label': label,
      'instructions': instructions,
      'required_slots_ids': req.toList(),
      'optional_slots_ids': optionalSlotsIds,
      // Если есть ветвление — next должен быть null
      'next': branchLogic.isNotEmpty ? null : next,
      'branch_logic': branchLogic,
    };
    if (onEnter != null && !onEnter!.isEmpty) {
      map['on_enter'] = onEnter!.toBackendJson();
    }
    if (onExit != null && !onExit!.isEmpty) {
      map['on_exit'] = onExit!.toBackendJson();
    }
    return map;
  }
}

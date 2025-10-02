import 'package:flutter/foundation.dart';
import 'package:sentralix_app/core/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Состояние редактора диалогов
class DialogsEditorState {
  const DialogsEditorState({
    required this.steps,
    this.selectedStepId,
    this.linkStartStepId,
  });

  final List<DialogStep> steps;
  final int? selectedStepId;
  final int? linkStartStepId;

  DialogsEditorState copyWith({
    List<DialogStep>? steps,
    int? selectedStepId,
    int? linkStartStepId,
  }) => DialogsEditorState(
        steps: steps ?? this.steps,
        selectedStepId: selectedStepId,
        linkStartStepId: linkStartStepId,
      );
}

/// Контроллер редактора: выбор шага, режим назначения next, обновление шагов
class DialogsEditorController extends StateNotifier<DialogsEditorState> {
  DialogsEditorController() : super(const DialogsEditorState(steps: []));

  /// Инициализация шагов из деталей конфига
  void setSteps(List<DialogStep> steps) {
    if (listEquals(state.steps, steps)) return;
    state = DialogsEditorState(steps: List<DialogStep>.from(steps));
    AppLogger.d('[Editor] setSteps: count=${state.steps.length}', tag: 'DialogsEditor');
  }

  /// Добавить новую ноду как next к существующей ноде `fromId`.
  /// Возвращает id созданной ноды.
  int addNextStep(int fromId) {
    final steps = List<DialogStep>.from(state.steps);
    // Новый id
    var maxId = 0;
    for (final s in steps) {
      if (s.id > maxId) maxId = s.id;
    }
    final newId = maxId + 1;
    // Обновить from.next
    final fromIdx = steps.indexWhere((e) => e.id == fromId);
    if (fromIdx >= 0) {
      final s = steps[fromIdx];
      steps[fromIdx] = DialogStep(
        id: s.id,
        name: s.name,
        label: s.label,
        instructions: s.instructions,
        requiredSlotsIds: s.requiredSlotsIds,
        optionalSlotsIds: s.optionalSlotsIds,
        next: newId,
        branchLogic: s.branchLogic,
      );
    }
    // Добавить новую ноду
    final newStep = DialogStep(
      id: newId,
      name: 'step_$newId',
      label: 'Шаг $newId',
      instructions: '',
      requiredSlotsIds: const [],
      optionalSlotsIds: const [],
      next: null,
      branchLogic: const {},
    );
    steps.add(newStep);
    state = DialogsEditorState(
      steps: steps,
      selectedStepId: newId,
      linkStartStepId: null,
    );
    AppLogger.d('[Editor] addNextStep: from=$fromId -> newId=$newId, total=${steps.length}', tag: 'DialogsEditor');
    return newId;
  }

  /// Выделить шаг
  void selectStep(int id) {
    state = state.copyWith(
      steps: state.steps,
      selectedStepId: id,
      linkStartStepId: state.linkStartStepId,
    );
  }

  /// Начать назначение next для выделенного шага
  void beginLinkFromSelected() {
    if (state.selectedStepId == null) return;
    state = state.copyWith(
      steps: state.steps,
      selectedStepId: state.selectedStepId,
      linkStartStepId: state.selectedStepId,
    );
  }

  /// Клик по ноде: если включён режим линковки — назначаем next, иначе просто выделяем
  void onNodeTap(int tappedId) {
    final start = state.linkStartStepId;
    if (start != null && start != tappedId) {
      // назначить next
      final steps = List<DialogStep>.from(state.steps);
      final idx = steps.indexWhere((e) => e.id == start);
      if (idx >= 0) {
        final s = steps[idx];
        steps[idx] = DialogStep(
          id: s.id,
          name: s.name,
          label: s.label,
          instructions: s.instructions,
          requiredSlotsIds: s.requiredSlotsIds,
          optionalSlotsIds: s.optionalSlotsIds,
          next: tappedId,
          branchLogic: s.branchLogic,
        );
      }
      state = DialogsEditorState(
        steps: steps,
        selectedStepId: start,
        linkStartStepId: null,
      );
      AppLogger.d('[Editor] link next: from=$start -> to=$tappedId', tag: 'DialogsEditor');
    } else {
      selectStep(tappedId);
      AppLogger.d('[Editor] selectStep: id=$tappedId', tag: 'DialogsEditor');
    }
  }

  /// Обновить шаг (например, из правой панели свойств)
  void updateStep(DialogStep updated) {
    final steps = List<DialogStep>.from(state.steps);
    final idx = steps.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      steps[idx] = updated;
      state = DialogsEditorState(
        steps: steps,
        selectedStepId: updated.id,
        linkStartStepId: state.linkStartStepId,
      );
      AppLogger.d('[Editor] updateStep: id=${updated.id}', tag: 'DialogsEditor');
    }
  }

  /// Добавить новую ноду (шаг) без связей
  void addStep() {
    final steps = List<DialogStep>.from(state.steps);
    // Найти следующий id
    var maxId = 0;
    for (final s in steps) {
      if (s.id > maxId) maxId = s.id;
    }
    final newId = maxId + 1;
    final newStep = DialogStep(
      id: newId,
      name: 'step_$newId',
      label: 'Шаг $newId',
      instructions: '',
      requiredSlotsIds: const [],
      optionalSlotsIds: const [],
      next: null,
      branchLogic: const {},
    );
    steps.add(newStep);
    state = DialogsEditorState(
      steps: steps,
      selectedStepId: newId,
      linkStartStepId: state.linkStartStepId,
    );
    AppLogger.d('[Editor] addStep: newId=$newId, total=${steps.length}', tag: 'DialogsEditor');
  }
}

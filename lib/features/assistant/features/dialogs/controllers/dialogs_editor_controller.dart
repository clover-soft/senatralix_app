import 'package:flutter/foundation.dart';
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
    } else {
      selectStep(tappedId);
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
    }
  }

  /// Создать новый шаг и назначить его как `next` для шага `fromId`.
  /// Возвращает id созданного шага.
  int addNextStep(int fromId) {
    final steps = List<DialogStep>.from(state.steps);
    // Найдём максимум id и создадим новый
    var maxId = 0;
    for (final s in steps) {
      if (s.id > maxId) maxId = s.id;
    }
    final newId = maxId + 1;

    // Обновим исходный шаг: next -> newId
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

    // Добавим новый шаг с дефолтами
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
    return newId;
  }

  /// Удалить шаг: удаляет сам шаг, обнуляет next у ссылающихся,
  /// удаляет в branchLogic ветви, указывающие на удаляемый шаг.
  void deleteStep(int id) {
    final steps = List<DialogStep>.from(state.steps);
    // Удалим сам шаг
    steps.removeWhere((e) => e.id == id);

    // Обновим ссылки у остальных
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final newNext = (s.next == id) ? null : s.next;

      // Фильтрация branchLogic: убрать значения, ведущие на удалённый id
      final newBranch = <String, Map<String, int>>{};
      s.branchLogic.forEach((slot, mapping) {
        final filtered = <String, int>{};
        mapping.forEach((k, v) {
          if (v != id) filtered[k] = v;
        });
        if (filtered.isNotEmpty) newBranch[slot] = filtered;
      });

      if (newNext != s.next || !mapEquals(newBranch, s.branchLogic)) {
        steps[i] = DialogStep(
          id: s.id,
          name: s.name,
          label: s.label,
          instructions: s.instructions,
          requiredSlotsIds: s.requiredSlotsIds,
          optionalSlotsIds: s.optionalSlotsIds,
          next: newNext,
          branchLogic: newBranch,
        );
      }
    }

    state = DialogsEditorState(
      steps: steps,
      selectedStepId: steps.isNotEmpty ? steps.first.id : null,
      linkStartStepId: null,
    );
  }
}

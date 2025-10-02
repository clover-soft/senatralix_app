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
}

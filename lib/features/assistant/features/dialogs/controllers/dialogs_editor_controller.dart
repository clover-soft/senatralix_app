import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';

/// Состояние редактора диалогов
class DialogsEditorState {
  const DialogsEditorState({this.selectedStepId, this.linkStartStepId});

  final int? selectedStepId;
  final int? linkStartStepId;

  DialogsEditorState copyWith({int? selectedStepId, int? linkStartStepId}) =>
      DialogsEditorState(
        selectedStepId: selectedStepId,
        linkStartStepId: linkStartStepId,
      );
}

/// Контроллер редактора: выбор шага, режим назначения next, обновление шагов
class DialogsEditorController extends StateNotifier<DialogsEditorState> {
  DialogsEditorController(this._read) : super(const DialogsEditorState());

  final Ref _read;

  /// Добавить новую ноду как next к существующей ноде `fromId`.
  /// Возвращает id созданной ноды.
  int addNextStep(int fromId) {
    final cfg = _read.read(dialogsConfigControllerProvider);
    final steps = List<DialogStep>.from(cfg.steps);
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
    final cfgNotifier = _read.read(dialogsConfigControllerProvider.notifier);
    cfgNotifier.updateSteps(steps);
    cfgNotifier.saveFullDebounced();
    state = DialogsEditorState(selectedStepId: newId, linkStartStepId: null);

    return newId;
  }

  /// Выделить шаг
  void selectStep(int id) {
    state = state.copyWith(
      selectedStepId: id,
      linkStartStepId: state.linkStartStepId,
    );
  }

  /// Начать назначение next для выделенного шага
  void beginLinkFromSelected() {
    if (state.selectedStepId == null) return;
    state = state.copyWith(
      selectedStepId: state.selectedStepId,
      linkStartStepId: state.selectedStepId,
    );
  }

  /// Клик по ноде: если включён режим линковки — назначаем next, иначе просто выделяем
  void onNodeTap(int tappedId) {
    final start = state.linkStartStepId;
    if (start != null && start != tappedId) {
      // назначить next
      final cfg = _read.read(dialogsConfigControllerProvider);
      final steps = List<DialogStep>.from(cfg.steps);
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
      final cfgNotifier = _read.read(dialogsConfigControllerProvider.notifier);
      cfgNotifier.updateSteps(steps);
      cfgNotifier.saveFullDebounced();
      state = DialogsEditorState(selectedStepId: start, linkStartStepId: null);
    } else {
      selectStep(tappedId);
    }
  }

  /// Обновить шаг (например, из правой панели свойств)
  void updateStep(DialogStep updated) {
    final cfg = _read.read(dialogsConfigControllerProvider);
    final steps = List<DialogStep>.from(cfg.steps);
    final idx = steps.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      // Валидируем branchLogic против актуальных опций слотов (enum)
      final slotsAsync = _read.read(dialogSlotsProvider);
      final slots = slotsAsync.maybeWhen(
        data: (s) => s,
        orElse: () => const <DialogSlot>[],
      );
      final sanitizedBranch = _sanitizeBranchLogic(updated.branchLogic, slots);
      final sanitized = DialogStep(
        id: updated.id,
        name: updated.name,
        label: updated.label,
        instructions: updated.instructions,
        requiredSlotsIds: updated.requiredSlotsIds,
        optionalSlotsIds: updated.optionalSlotsIds,
        next: updated.next,
        branchLogic: sanitizedBranch,
        onEnter: updated.onEnter,
        onExit: updated.onExit,
        searchIndexId: updated.searchIndexId,
      );

      steps[idx] = sanitized;
      _read.read(dialogsConfigControllerProvider.notifier).updateSteps(steps);
      state = DialogsEditorState(
        selectedStepId: sanitized.id,
        linkStartStepId: state.linkStartStepId,
      );
    }
  }

  /// Очищает branchLogic от значений, которых больше нет в соответствующих слотах.
  /// Оставляет только те пары slotId -> {value: nextId}, где slotId существует,
  /// слот имеет опции и value входит в список options этого слота.
  Map<String, Map<String, int>> _sanitizeBranchLogic(
    Map<String, Map<String, int>> source,
    List<DialogSlot> slots,
  ) {
    if (source.isEmpty) return const {};
    if (slots.isEmpty) return source; // нет данных по слотам — ничего не меняем
    final slotsById = {for (final s in slots) s.id.toString(): s};
    final result = <String, Map<String, int>>{};
    source.forEach((slotKey, mapping) {
      final slot = slotsById[slotKey];
      if (slot == null || slot.options.isEmpty) {
        return; // слот отсутствует или без опций — вычищаем ветвление
      }
      final allowed = slot.options.toSet();
      final filtered = <String, int>{};
      mapping.forEach((value, nextId) {
        if (allowed.contains(value)) {
          filtered[value] = nextId;
        }
      });
      if (filtered.isNotEmpty) {
        result[slotKey] = filtered;
      }
    });
    return result;
  }

  /// Добавить новую ноду (шаг) без связей
  void addStep() {
    final cfg = _read.read(dialogsConfigControllerProvider);
    final steps = List<DialogStep>.from(cfg.steps);
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
    _read.read(dialogsConfigControllerProvider.notifier).updateSteps(steps);
    state = DialogsEditorState(
      selectedStepId: newId,
      linkStartStepId: state.linkStartStepId,
    );
  }
}

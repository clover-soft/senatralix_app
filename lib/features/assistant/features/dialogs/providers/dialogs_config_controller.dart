import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/api/assistant_api.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Состояние конфигурации диалога
class DialogsConfigState {
  const DialogsConfigState({
    this.configId,
    this.name = '',
    this.description,
    this.metadata = const {},
    this.steps = const <DialogStep>[],
    this.isSaving = false,
    this.error,
  });

  final int? configId;
  final String name;
  final String? description;
  final Map<String, dynamic> metadata;
  final List<DialogStep> steps;
  final bool isSaving;
  final String? error;

  DialogsConfigState copyWith({
    int? configId,
    String? name,
    String? description,
    Map<String, dynamic>? metadata,
    List<DialogStep>? steps,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return DialogsConfigState(
      configId: configId ?? this.configId,
      name: name ?? this.name,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      steps: steps ?? this.steps,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Контроллер бизнес-логики конфигурации диалога
class DialogsConfigController extends StateNotifier<DialogsConfigState> {
  DialogsConfigController(this._api) : super(const DialogsConfigState());
  final AssistantApi _api;
  Timer? _saveDebounce;

  /// Создать новый диалог с одним шагом приветствия и вернуть его id
  Future<int?> createConfigWithWelcomeStep({
    required String name,
    String? description,
  }) async {
    try {
      final welcome = DialogStep(
        id: 1,
        name: 'welcome',
        label: 'Приветствие',
        instructions: '',
        requiredSlotsIds: const [],
        optionalSlotsIds: const [],
        next: null,
        branchLogic: const {},
      );
      final json = await _api.createDialogConfigFull(
        name: name,
        description: (description?.trim().isEmpty ?? true)
            ? null
            : description!.trim(),
        steps: [welcome],
        metadata: const {},
      );
      final newId = int.tryParse('${json['id']}');
      if (newId != null) {
        await loadDetails(newId);
      }
      return newId;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return null;
    }
  }

  /// Выбрать конфигурацию и загрузить детали
  Future<void> selectConfig(int id) async {
    state = state.copyWith(configId: id, clearError: true);
    await loadDetails(id);
  }

  /// Загрузить детали конфигурации: name/description/metadata/steps
  Future<void> loadDetails(int id) async {
    try {
      final json = await _api.fetchDialogConfig(id);
      final details = DialogConfigDetails.fromJson(json);
      state = state.copyWith(
        configId: details.id,
        name: details.name,
        description: details.description,
        metadata: details.metadata,
        steps: details.steps,
        clearError: true,
      );
      
    } catch (e) {
      state = state.copyWith(error: '$e');
      
    }
  }

  /// Обновить имя/описание локально и на сервере (PATCH name/description)
  Future<void> updateNameDescription(String name, String? description) async {
    final id = state.configId;
    if (id == null) return;
    // Локально
    state = state.copyWith(name: name, description: description, clearError: true);
    // API
    try {
      await _api.updateDialogConfig(id: id, name: name, description: description);
    } catch (e) {
      state = state.copyWith(error: '$e');
      
    }
  }

  /// Полное сохранение конфигурации (PATCH config + steps + metadata)
  Future<void> saveFull() async {
    final id = state.configId;
    if (id == null) return;
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _api.updateDialogConfigFull(
        id: id,
        name: state.name,
        description: state.description,
        steps: state.steps,
        metadata: state.metadata,
      );
      state = state.copyWith(isSaving: false);
      
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      
    }
  }

  /// Debounce-обертка над полным сохранением
  void saveFullDebounced([Duration delay = const Duration(milliseconds: 600)]) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(delay, () {
      // ignore: discarded_futures
      saveFull();
    });
  }

  /// Заменить весь список шагов локально (без немедленного сохранения)
  void updateSteps(List<DialogStep> steps) {
    final newList = List<DialogStep>.from(steps);
    if (listEquals(state.steps, newList)) return;
    state = state.copyWith(steps: newList, clearError: true);
  }

  /// Обновить один шаг по id локально (без немедленного сохранения)
  void updateStep(DialogStep updated) {
    final steps = List<DialogStep>.from(state.steps);
    final idx = steps.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      steps[idx] = updated;
      state = state.copyWith(steps: steps, clearError: true);
    }
  }

  /// Удалить шаг по id: очистить ссылки next и ветвления branchLogic, затем удалить сам шаг
  void deleteStep(int id) {
    final steps = List<DialogStep>.from(state.steps);
    final idx = steps.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    // Пройтись по всем шагам и очистить ссылки на удаляемый id
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      // Обновим next, если он указывает на удаляемый шаг
      final newNext = (s.next == id) ? null : s.next;
      // Отфильтруем branchLogic: убрать все маршруты, ведущие к удаляемому шагу
      final Map<String, Map<String, int>> newBranch = {};
      s.branchLogic.forEach((slotKey, mapping) {
        final filtered = <String, int>{
          for (final e in mapping.entries)
            if (e.value != id) e.key: e.value,
        };
        if (filtered.isNotEmpty) {
          newBranch[slotKey] = filtered;
        }
      });
      // Перезапишем шаг, только если были изменения
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

    // Удаляем сам шаг
    steps.removeAt(idx);
    state = state.copyWith(steps: steps, clearError: true);
    
  }

  /// Удалить текущий диалог (DELETE) и очистить локальное состояние провайдера
  Future<void> deleteDialog() async {
    final id = state.configId;
    if (id == null) return;
    try {
      await _api.deleteDialogConfig(id);
      state = const DialogsConfigState();
      
    } catch (e) {
      state = state.copyWith(error: '$e');
      
    }
  }
}

/// Провайдер контроллера конфигурации диалогов
final dialogsConfigControllerProvider =
    StateNotifierProvider<DialogsConfigController, DialogsConfigState>((ref) {
  final api = ref.read(assistantApiProvider);
  return DialogsConfigController(api);
});

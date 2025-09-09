import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_edit_state.dart';

/// Контроллер редактора скрипта (управляет временным состоянием формы)
class ScriptEditController extends StateNotifier<ScriptEditState> {
  ScriptEditController(Script initial)
      : super(ScriptEditState(
          name: initial.name,
          enabled: initial.enabled,
          trigger: initial.trigger,
          params: initial.params.entries.map((e) => MapEntry(e.key, e.value)).toList(),
          steps: List<ScriptStep>.from(initial.steps),
        ));

  void setName(String v) => state = state.copy(name: v);
  void setEnabled(bool v) => state = state.copy(enabled: v);
  void setTrigger(ScriptTrigger v) => state = state.copy(trigger: v);
  void addParam() => state = state.copy(params: [...state.params, const MapEntry('', '')]);
  void setParamKey(int i, String key) {
    final p = [...state.params];
    p[i] = MapEntry(key, p[i].value);
    state = state.copy(params: p);
  }

  void setParamValue(int i, String value) {
    final p = [...state.params];
    p[i] = MapEntry(p[i].key, value);
    state = state.copy(params: p);
  }

  void removeParam(int i) {
    final p = [...state.params]..removeAt(i);
    state = state.copy(params: p);
  }

  void addStep(ScriptStep step) => state = state.copy(steps: [...state.steps, step]);
  void updateStep(int i, ScriptStep step) {
    final s = [...state.steps];
    s[i] = step;
    state = state.copy(steps: s);
  }

  void removeStep(int i) {
    final s = [...state.steps]..removeAt(i);
    state = state.copy(steps: s);
  }

  Script buildResult(Script initial) => initial.copyWith(
        name: state.name.trim(),
        enabled: state.enabled,
        trigger: state.trigger,
        params: {for (final e in state.params) e.key.trim(): e.value},
        steps: state.steps,
      );
}

/// Family-провайдер, чтобы хранить отдельное состояние на каждый запуск диалога
final scriptEditProvider = StateNotifierProvider.autoDispose
    .family<ScriptEditController, ScriptEditState, Script>((ref, initial) {
  return ScriptEditController(initial);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_edit_state.dart';

/// Контроллер редактора скрипта (управляет временным состоянием формы)
class ScriptEditController extends StateNotifier<ScriptEditState> {
  ScriptEditController(Script initial)
    : super(
        ScriptEditState(
          name: initial.name,
          enabled: initial.enabled,
          trigger: initial.trigger,
          params: initial.params.keys.toList(),
          steps: List<ScriptStep>.from(initial.steps),
        ),
      );

  void setName(String v) => state = state.copy(name: v);
  void setEnabled(bool v) => state = state.copy(enabled: v);
  void setTrigger(ScriptTrigger v) => state = state.copy(trigger: v);
  void addParam() => state = state.copy(params: [...state.params, '']);
  void setParamKey(int i, String key) {
    final p = [...state.params];
    p[i] = key;
    state = state.copy(params: p);
  }

  void removeParam(int i) {
    final p = [...state.params]..removeAt(i);
    state = state.copy(params: p);
  }

  void addStep(ScriptStep step) =>
      state = state.copy(steps: [...state.steps, step]);
  void updateStep(int i, ScriptStep step) {
    final s = [...state.steps];
    s[i] = step;
    state = state.copy(steps: s);
  }

  void removeStep(int i) {
    final s = [...state.steps]..removeAt(i);
    state = state.copy(steps: s);
  }

  void moveStep(int oldIndex, int newIndex) {
    final s = [...state.steps];
    if (oldIndex < 0 || oldIndex >= s.length) return;
    if (newIndex < 0 || newIndex > s.length) return;
    // Flutter ReorderableListView uses semantics where newIndex already accounts
    // for removal; adjust when dragging down
    if (newIndex > oldIndex) newIndex -= 1;
    final item = s.removeAt(oldIndex);
    s.insert(newIndex, item);
    state = state.copy(steps: s);
  }

  Script buildResult(Script initial) => initial.copyWith(
    name: state.name.trim(),
    enabled: state.enabled,
    trigger: state.trigger,
    params: {for (final k in state.params) k.trim(): ''},
    steps: state.steps,
  );
}

/// Family-провайдер, чтобы хранить отдельное состояние на каждый запуск диалога
final scriptEditProvider = StateNotifierProvider.autoDispose
    .family<ScriptEditController, ScriptEditState, Script>((ref, initial) {
      return ScriptEditController(initial);
    });

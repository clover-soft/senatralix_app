import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';

@immutable
class ScriptsState {
  final Map<String, List<Script>> byAssistantId;
  const ScriptsState({required this.byAssistantId});

  ScriptsState copyWith({Map<String, List<Script>>? byAssistantId}) =>
      ScriptsState(byAssistantId: byAssistantId ?? this.byAssistantId);
}

class ScriptsNotifier extends StateNotifier<ScriptsState> {
  final Ref _ref;
  ScriptsNotifier(this._ref) : super(const ScriptsState(byAssistantId: {}));

  List<Script> list(String assistantId) =>
      List<Script>.from(state.byAssistantId[assistantId] ?? const []);

  void _put(String assistantId, List<Script> value) {
    final map = Map<String, List<Script>>.from(state.byAssistantId);
    map[assistantId] = value;
    state = state.copyWith(byAssistantId: map);
  }

  void add(String assistantId, Script script) {
    final items = list(assistantId);
    final max = _ref.read(assistantFeatureSettingsProvider).settings.scripts.maxScriptItems;
    if (max > 0 && items.length >= max) {
      if (kDebugMode) {
        print('Scripts limit reached ($max) for assistant=$assistantId');
      }
      return;
    }
    items.add(script);
    _put(assistantId, items);
  }

  void update(String assistantId, Script script) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == script.id);
    if (idx >= 0) {
      items[idx] = script;
      _put(assistantId, items);
    }
  }

  void remove(String assistantId, String id) {
    final items = list(assistantId);
    items.removeWhere((e) => e.id == id);
    _put(assistantId, items);
  }

  void toggleEnabled(String assistantId, String id, bool enabled) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(enabled: enabled);
      _put(assistantId, items);
    }
  }

  void addStep(String assistantId, String scriptId, ScriptStep step) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == scriptId);
    if (idx >= 0) {
      final steps = List<ScriptStep>.from(items[idx].steps)..add(step);
      items[idx] = items[idx].copyWith(steps: steps);
      _put(assistantId, items);
    }
  }

  void updateStep(String assistantId, String scriptId, ScriptStep step) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == scriptId);
    if (idx >= 0) {
      final steps = List<ScriptStep>.from(items[idx].steps);
      final sIdx = steps.indexWhere((s) => s.id == step.id);
      if (sIdx >= 0) steps[sIdx] = step;
      items[idx] = items[idx].copyWith(steps: steps);
      _put(assistantId, items);
    }
  }

  void removeStep(String assistantId, String scriptId, String stepId) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == scriptId);
    if (idx >= 0) {
      final steps = List<ScriptStep>.from(items[idx].steps)..removeWhere((s) => s.id == stepId);
      items[idx] = items[idx].copyWith(steps: steps);
      _put(assistantId, items);
    }
  }
}

final scriptsProvider = StateNotifierProvider<ScriptsNotifier, ScriptsState>((ref) => ScriptsNotifier(ref));

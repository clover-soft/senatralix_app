import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';

@immutable
class AssistantToolsState {
  final Map<String, List<AssistantFunctionTool>> byAssistantId;
  const AssistantToolsState({required this.byAssistantId});

  AssistantToolsState copyWith({
    Map<String, List<AssistantFunctionTool>>? byAssistantId,
  }) => AssistantToolsState(byAssistantId: byAssistantId ?? this.byAssistantId);
}

class AssistantToolsNotifier extends StateNotifier<AssistantToolsState> {
  final Ref _ref;
  AssistantToolsNotifier(this._ref)
    : super(const AssistantToolsState(byAssistantId: {})) {
    // Моки по умолчанию можно инициализировать по требованию (лениво)
  }

  List<AssistantFunctionTool> list(String assistantId) {
    return List<AssistantFunctionTool>.from(
      state.byAssistantId[assistantId] ?? const [],
    );
  }

  void _put(String assistantId, List<AssistantFunctionTool> tools) {
    final map = Map<String, List<AssistantFunctionTool>>.from(
      state.byAssistantId,
    );
    map[assistantId] = tools;
    state = state.copyWith(byAssistantId: map);
  }

  void add(String assistantId, AssistantFunctionTool tool) {
    final tools = list(assistantId);
    final max = _ref
        .read(assistantFeatureSettingsProvider)
        .settings
        .tools
        .maxToolsItems;
    if (max > 0 && tools.length >= max) {
      if (kDebugMode) {
        print('Tools limit reached ($max) for assistant=$assistantId');
      }
      return;
    }
    tools.add(tool);
    _put(assistantId, tools);
  }

  void update(String assistantId, AssistantFunctionTool tool) {
    final tools = list(assistantId);
    final idx = tools.indexWhere((t) => t.id == tool.id);
    if (idx >= 0) {
      tools[idx] = tool;
      _put(assistantId, tools);
    }
  }

  /// Полная замена списка инструментов для ассистента
  void replaceAll(String assistantId, List<AssistantFunctionTool> tools) {
    _put(assistantId, List<AssistantFunctionTool>.from(tools));
  }

  void remove(String assistantId, String toolId) {
    final tools = list(assistantId);
    tools.removeWhere((t) => t.id == toolId);
    _put(assistantId, tools);
  }

  void toggleEnabled(String assistantId, String toolId, bool enabled) {
    final tools = list(assistantId);
    final idx = tools.indexWhere((t) => t.id == toolId);
    if (idx >= 0) {
      tools[idx] = tools[idx].copyWith(enabled: enabled);
      _put(assistantId, tools);
    }
  }

  // Утилита: создать из пресета (пример из docs/assistant.json)
  AssistantFunctionTool fromPresetJson(String id, Map<String, dynamic> json) {
    // ожидаем { function: { name, description, parameters } }
    final fn = FunctionToolDef.fromJson(
      Map<String, dynamic>.from(json['function'] as Map),
    );
    return AssistantFunctionTool(id: id, enabled: true, def: fn);
  }
}

final assistantToolsProvider =
    StateNotifierProvider<AssistantToolsNotifier, AssistantToolsState>(
      (ref) => AssistantToolsNotifier(ref),
    );

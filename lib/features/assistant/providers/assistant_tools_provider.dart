import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

@immutable
class AssistantToolsState {
  final Map<String, List<AssistantTool>> byAssistantId;
  const AssistantToolsState({required this.byAssistantId});

  AssistantToolsState copyWith({
    Map<String, List<AssistantTool>>? byAssistantId,
  }) => AssistantToolsState(byAssistantId: byAssistantId ?? this.byAssistantId);
}

class AssistantToolsNotifier extends StateNotifier<AssistantToolsState> {
  AssistantToolsNotifier(this._ref)
    : super(const AssistantToolsState(byAssistantId: {}));

  final Ref _ref;

  List<AssistantTool> list(String assistantId) {
    return List<AssistantTool>.from(
      state.byAssistantId[assistantId] ?? const [],
    );
  }

  void _put(String assistantId, List<AssistantTool> tools) {
    final map = Map<String, List<AssistantTool>>.from(state.byAssistantId);
    map[assistantId] = tools;
    state = state.copyWith(byAssistantId: map);
  }

  void replaceAll(String assistantId, List<AssistantTool> tools) {
    _put(assistantId, List<AssistantTool>.from(tools));
  }

  Future<void> fetch(String assistantId, {int limit = 50, int offset = 0}) async {
    try {
      final api = _ref.read(assistantApiProvider);
      final tools = await api.fetchAssistantTools(
        assistantId: assistantId,
        limit: limit,
        offset: offset,
      );
      replaceAll(assistantId, tools);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load tools for $assistantId: $e');
      }
      rethrow;
    }
  }

  Future<AssistantTool> createFunctionTool({
    required String assistantId,
    required String name,
    required String displayName,
    required String description,
    required Map<String, dynamic> parameters,
    bool isActive = true,
  }) async {
    final api = _ref.read(assistantApiProvider);
    final created = await api.createAssistantTool(
      assistantId: assistantId,
      type: 'function',
      name: name,
      displayName: displayName,
      description: description,
      parameters: parameters,
      isActive: isActive,
    );
    final next = list(assistantId)..add(created);
    _put(assistantId, next);
    return created;
  }

  Future<void> setActive({
    required String assistantId,
    required int toolId,
    required bool isActive,
  }) async {
    final api = _ref.read(assistantApiProvider);
    final updated = await api.updateAssistantTool(
      toolId: toolId,
      body: {'is_active': isActive},
    );
    final tools = list(assistantId);
    final idx = tools.indexWhere((t) => t.id == toolId);
    if (idx >= 0) {
      tools[idx] = updated;
      _put(assistantId, tools);
    }
  }

  Future<void> delete({required String assistantId, required int toolId}) async {
    final api = _ref.read(assistantApiProvider);
    await api.deleteAssistantTool(toolId);
    final tools = list(assistantId)
      ..removeWhere((t) => t.id == toolId);
    _put(assistantId, tools);
  }

  Future<void> reorder({
    required String assistantId,
    required List<AssistantTool> ordered,
  }) async {
    final api = _ref.read(assistantApiProvider);
    await api.reorderAssistantTools(
      assistantId: assistantId,
      orderedIds: ordered.map((e) => e.id).toList(),
    );
    _put(assistantId, ordered);
  }
}

final assistantToolsProvider =
    StateNotifierProvider<AssistantToolsNotifier, AssistantToolsState>(
      (ref) => AssistantToolsNotifier(ref),
    );

final assistantToolsLoaderProvider = FutureProvider.family<void, String>(
  (ref, assistantId) async {
    await ref.read(assistantBootstrapProvider.future);
    await ref.read(assistantToolsProvider.notifier).fetch(assistantId);
  },
);


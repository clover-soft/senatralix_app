import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';

@immutable
class KnowledgeState {
  final Map<String, List<KnowledgeBaseItem>> byAssistantId;
  const KnowledgeState({required this.byAssistantId});

  KnowledgeState copyWith({Map<String, List<KnowledgeBaseItem>>? byAssistantId}) =>
      KnowledgeState(byAssistantId: byAssistantId ?? this.byAssistantId);
}

class KnowledgeNotifier extends StateNotifier<KnowledgeState> {
  KnowledgeNotifier() : super(const KnowledgeState(byAssistantId: {}));

  List<KnowledgeBaseItem> list(String assistantId) {
    return List<KnowledgeBaseItem>.from(state.byAssistantId[assistantId] ?? const []);
  }

  void _put(String assistantId, List<KnowledgeBaseItem> items) {
    final map = Map<String, List<KnowledgeBaseItem>>.from(state.byAssistantId);
    map[assistantId] = items;
    state = state.copyWith(byAssistantId: map);
  }

  void add(String assistantId, KnowledgeBaseItem item) {
    final items = list(assistantId);
    items.add(item);
    _put(assistantId, items);
  }

  void update(String assistantId, KnowledgeBaseItem item) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
      _put(assistantId, items);
    }
  }

  /// Полная замена списка источников знаний для ассистента
  void replaceAll(String assistantId, List<KnowledgeBaseItem> items) {
    _put(assistantId, List<KnowledgeBaseItem>.from(items));
  }

  void remove(String assistantId, int id) {
    final items = list(assistantId);
    items.removeWhere((e) => e.id == id);
    _put(assistantId, items);
  }

  void toggleActive(String assistantId, int id, bool active) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(active: active);
      _put(assistantId, items);
    }
  }
}

final knowledgeProvider = StateNotifierProvider<KnowledgeNotifier, KnowledgeState>(
  (ref) => KnowledgeNotifier(),
);

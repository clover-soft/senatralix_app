import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_list_item.dart';

@immutable
class ScriptListState {
  final Map<String, List<ScriptListItem>> byAssistantId;
  const ScriptListState({required this.byAssistantId});

  ScriptListState copyWith({Map<String, List<ScriptListItem>>? byAssistantId}) =>
      ScriptListState(byAssistantId: byAssistantId ?? this.byAssistantId);
}

class ScriptListNotifier extends StateNotifier<ScriptListState> {
  ScriptListNotifier() : super(const ScriptListState(byAssistantId: {}));

  List<ScriptListItem> list(String assistantId) =>
      List<ScriptListItem>.from(state.byAssistantId[assistantId] ?? const []);

  void _put(String assistantId, List<ScriptListItem> items) {
    final map = Map<String, List<ScriptListItem>>.from(state.byAssistantId);
    map[assistantId] = items;
    state = state.copyWith(byAssistantId: map);
  }

  void replaceAll(String assistantId, List<ScriptListItem> items) {
    _put(assistantId, List<ScriptListItem>.from(items));
  }

  void add(String assistantId, ScriptListItem item) {
    final items = list(assistantId);
    items.add(item);
    _put(assistantId, items);
  }

  void update(String assistantId, ScriptListItem item) {
    final items = list(assistantId);
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
      _put(assistantId, items);
    }
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
      items[idx] = items[idx].copyWith(isActive: active);
      _put(assistantId, items);
    }
  }

  /// Перестановка элементов списка с пересчётом order (1..N)
  void reorder(String assistantId, int oldIndex, int newIndex) {
    final items = list(assistantId);
    // Отладка: вывести параметры и длину
    // ignore: avoid_print
    print('[DnD][prov] reorder request old=$oldIndex new=$newIndex len=${items.length}');

    if (items.isEmpty) {
      // ignore: avoid_print
      print('[DnD][prov] skip: empty items');
      return;
    }
    if (oldIndex < 0 || oldIndex >= items.length) {
      // ignore: avoid_print
      print('[DnD][prov] skip: oldIndex OOB');
      return;
    }
    if (newIndex < 0 || newIndex > items.length) {
      // ignore: avoid_print
      print('[DnD][prov] skip: newIndex OOB');
      return;
    }
    int adjustedNew = newIndex;
    if (adjustedNew > oldIndex) adjustedNew -= 1;
    if (adjustedNew == oldIndex) {
      // ignore: avoid_print
      print('[DnD][prov] no-op after adjust, skip');
      return;
    }

    final it = items.removeAt(oldIndex);
    if (adjustedNew < 0 || adjustedNew > items.length) {
      // ignore: avoid_print
      print('[DnD][prov] adjustedNew OOB after remove, push to tail');
      adjustedNew = items.length;
    }
    items.insert(adjustedNew, it);
    // ignore: avoid_print
    print('[DnD][prov] moved id=${it.id} to pos=$adjustedNew');
    // Пересчитать order последовательно от 1
    for (int i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(order: i + 1);
    }
    // ignore: avoid_print
    print('[DnD][prov] new order: ' + items.map((e) => '${e.id}:${e.order}').join(','));
    _put(assistantId, items);
  }
}

final scriptListProvider =
    StateNotifierProvider<ScriptListNotifier, ScriptListState>(
  (ref) => ScriptListNotifier(),
);

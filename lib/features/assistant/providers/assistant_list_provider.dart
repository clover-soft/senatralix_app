// Провайдер списка ассистентов (заглушка, хранение в памяти)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';

/// Состояние: список ассистентов
class AssistantListState {
  final List<Assistant> items;
  const AssistantListState({required this.items});

  AssistantListState copyWith({List<Assistant>? items}) =>
      AssistantListState(items: items ?? this.items);
}

/// Нотифаер со CRUD-заглушками
class AssistantListNotifier extends StateNotifier<AssistantListState> {
  AssistantListNotifier()
    : super(
        const AssistantListState(
          items: [
            Assistant(id: 'stub-1', name: 'Екатерина'),
            Assistant(id: 'stub-2', name: 'Анна'),
          ],
        ),
      );

  void add(String name) {
    final id = 'id-${DateTime.now().microsecondsSinceEpoch}';
    state = state.copyWith(
      items: [
        ...state.items,
        Assistant(id: id, name: name),
      ],
    );
  }

  void remove(String id) {
    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
    );
  }

  void rename(String id, String name) {
    state = state.copyWith(
      items: state.items
          .map((e) => e.id == id ? e.copyWith(name: name) : e)
          .toList(),
    );
  }
}

/// Глобальный провайдер списка ассистентов
final assistantListProvider =
    StateNotifierProvider<AssistantListNotifier, AssistantListState>(
      (ref) => AssistantListNotifier(),
    );

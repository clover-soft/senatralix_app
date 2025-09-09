import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';

@immutable
class ConnectorsState {
  final Map<String, List<Connector>> byAssistantId;
  const ConnectorsState({required this.byAssistantId});

  ConnectorsState copyWith({Map<String, List<Connector>>? byAssistantId}) =>
      ConnectorsState(byAssistantId: byAssistantId ?? this.byAssistantId);
}

class ConnectorsNotifier extends StateNotifier<ConnectorsState> {
  ConnectorsNotifier() : super(const ConnectorsState(byAssistantId: {}));

  List<Connector> list(String assistantId) =>
      List<Connector>.from(state.byAssistantId[assistantId] ?? const []);

  void _put(String assistantId, List<Connector> list) {
    final map = Map<String, List<Connector>>.from(state.byAssistantId);
    map[assistantId] = list;
    state = state.copyWith(byAssistantId: map);
  }

  void add(String assistantId, Connector connector) {
    final list0 = list(assistantId);
    list0.add(connector);
    _put(assistantId, list0);
  }

  void update(String assistantId, Connector connector) {
    final ls = list(assistantId);
    final idx = ls.indexWhere((c) => c.id == connector.id);
    if (idx >= 0) {
      ls[idx] = connector;
      _put(assistantId, ls);
    }
  }

  void remove(String assistantId, String id) {
    final ls = list(assistantId);
    ls.removeWhere((c) => c.id == id);
    _put(assistantId, ls);
  }

  void toggleActive(String assistantId, String id, bool active) {
    final ls = list(assistantId);
    final idx = ls.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      ls[idx] = ls[idx].copyWith(isActive: active);
      _put(assistantId, ls);
    }
  }
}

final connectorsProvider =
    StateNotifierProvider<ConnectorsNotifier, ConnectorsState>((ref) => ConnectorsNotifier());

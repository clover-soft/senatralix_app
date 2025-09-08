import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';

/// Состояние настроек по ассистентам (in-memory, моки)
@immutable
class AssistantSettingsState {
  final Map<String, AssistantSettings> byId; // assistantId -> settings
  const AssistantSettingsState({required this.byId});

  AssistantSettingsState copyWith({Map<String, AssistantSettings>? byId}) =>
      AssistantSettingsState(byId: byId ?? this.byId);
}

class AssistantSettingsNotifier extends StateNotifier<AssistantSettingsState> {
  AssistantSettingsNotifier()
      : super(const AssistantSettingsState(byId: {}));

  /// Получить настройки ассистента (если нет — вернём дефолт)
  AssistantSettings getFor(String assistantId) {
    return state.byId[assistantId] ?? AssistantSettings.defaults();
  }

  /// Сохранить настройки ассистента
  void save(String assistantId, AssistantSettings settings) {
    final map = Map<String, AssistantSettings>.from(state.byId);
    map[assistantId] = settings;
    state = state.copyWith(byId: map);
  }
}

/// Провайдер настроек
final assistantSettingsProvider =
    StateNotifierProvider<AssistantSettingsNotifier, AssistantSettingsState>(
  (ref) => AssistantSettingsNotifier(),
);

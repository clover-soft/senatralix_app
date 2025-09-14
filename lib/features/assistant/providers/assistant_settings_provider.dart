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
  AssistantSettingsNotifier() : super(const AssistantSettingsState(byId: {}));

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

  /// Проверить, подключён ли external_id базы знаний к ассистенту
  bool isKnowledgeLinked(String assistantId, String externalId) {
    final s = getFor(assistantId);
    return s.knowledgeExternalIds.contains(externalId);
  }

  /// Подключить external_id базы знаний к ассистенту
  void linkKnowledge(String assistantId, String externalId) {
    final current = getFor(assistantId);
    final next = current.copyWith(
      knowledgeExternalIds: {...current.knowledgeExternalIds, externalId},
    );
    save(assistantId, next);
  }

  /// Отключить external_id базы знаний от ассистента
  void unlinkKnowledge(String assistantId, String externalId) {
    final current = getFor(assistantId);
    final set = {...current.knowledgeExternalIds}..remove(externalId);
    final next = current.copyWith(knowledgeExternalIds: set);
    save(assistantId, next);
  }

  /// Переключить связь external_id базы знаний
  void toggleKnowledge(String assistantId, String externalId, bool linked) {
    if (linked) {
      linkKnowledge(assistantId, externalId);
    } else {
      unlinkKnowledge(assistantId, externalId);
    }
  }

  /// Установить единственный external_id базы знаний (остальные очистить)
  void setSingleKnowledge(String assistantId, String externalId) {
    final current = getFor(assistantId);
    final next = current.copyWith(knowledgeExternalIds: {externalId});
    save(assistantId, next);
  }

  /// Очистить все связи баз знаний у ассистента
  void clearKnowledge(String assistantId) {
    final current = getFor(assistantId);
    final next = current.copyWith(knowledgeExternalIds: {});
    save(assistantId, next);
  }
}

/// Провайдер настроек
final assistantSettingsProvider =
    StateNotifierProvider<AssistantSettingsNotifier, AssistantSettingsState>(
      (ref) => AssistantSettingsNotifier(),
    );

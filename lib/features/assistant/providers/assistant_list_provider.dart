// Провайдер списка ассистентов (заглушка, хранение в памяти)
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';

/// Состояние: список ассистентов
class AssistantListState {
  final List<Assistant> items;
  const AssistantListState({required this.items});

  AssistantListState copyWith({List<Assistant>? items}) =>
      AssistantListState(items: items ?? this.items);

  /// Найти ассистента по id
  Assistant? byId(String id) =>
      items
          .firstWhere(
            (e) => e.id == id,
            orElse: () => const Assistant(id: '', name: ''),
          )
          .id
          .isEmpty
      ? null
      : items.firstWhere((e) => e.id == id);
}

/// Нотифаер со CRUD-заглушками
class AssistantListNotifier extends StateNotifier<AssistantListState> {
  final Ref _ref;
  AssistantListNotifier(this._ref)
    : super(
        const AssistantListState(
          items: [
            Assistant(
              id: 'stub-1',
              name: 'Екатерина',
              description: 'Персональный ассистент для тестов',
            ),
            Assistant(
              id: 'stub-2',
              name: 'Алексей',
              description: 'Ассистент техподдержки: быстрые ответы клиентам',
            ),
            Assistant(
              id: 'stub-3',
              name: 'Мария',
              description:
                  'HR-ассистент: рекрутинг и коммуникация с кандидатами',
            ),
            Assistant(
              id: 'stub-4',
              name: 'Олег',
              description: 'Аналитик: сводки и инсайты по данным',
            ),
            Assistant(
              id: 'stub-5',
              name: 'София',
              description: 'Маркетинг: работа с контентом и промо-активностями',
            ),
          ],
        ),
      );

  void add(String name, {String? description}) {
    final max = _ref
        .read(assistantFeatureSettingsProvider)
        .settings
        .maxAssistantItems;
    if (max > 0 && state.items.length >= max) {
      if (kDebugMode) {
        print('Assistant limit reached ($max)');
      }
      return;
    }
    final id = 'id-${DateTime.now().microsecondsSinceEpoch}';
    state = state.copyWith(
      items: [
        ...state.items,
        Assistant(
          id: id,
          name: name,
          description: _normalizeDescription(description),
        ),
      ],
    );
  }

  void remove(String id) {
    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
    );
  }

  void rename(String id, String name, {String? description}) {
    state = state.copyWith(
      items: state.items
          .map(
            (e) => e.id == id
                ? e.copyWith(
                    name: name,
                    description: _normalizeDescription(description),
                  )
                : e,
          )
          .toList(),
    );
  }

  /// Установить привязанный сценарий диалога к ассистенту
  void setDialogId(String id, int? dialogId) {
    state = state.copyWith(
      items: state.items.map((e) {
        if (e.id != id) return e;
        // Явно создаём новый экземпляр с заданным dialogId (включая null)
        return Assistant(
          id: e.id,
          name: e.name,
          description: e.description,
          settings: e.settings,
          dialogId: dialogId,
        );
      }).toList(),
    );
  }

  /// Полная замена списка ассистентов (после загрузки с бэкенда)
  void replaceAll(List<Assistant> items) {
    state = state.copyWith(items: List<Assistant>.from(items));
  }

  String? _normalizeDescription(String? value) {
    final t = value?.trim() ?? '';
    return t.isEmpty ? null : (t.length > 280 ? t.substring(0, 280) : t);
  }
}

/// Глобальный провайдер списка ассистентов
final assistantListProvider =
    StateNotifierProvider<AssistantListNotifier, AssistantListState>(
      (ref) => AssistantListNotifier(ref),
    );

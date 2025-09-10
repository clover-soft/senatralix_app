import 'package:sentralix_app/data/api/api_client.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';
import 'package:sentralix_app/features/assistant/models/assistant_feature_settings.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';

/// HTTP API для надфичи Assistant
class AssistantApi {
  final ApiClient _client;
  AssistantApi(this._client);

  /// Настройки надфичи
  Future<AssistantFeatureSettings> fetchFeatureSettings() async {
    final resp = await _client.get<dynamic>('/assistants/settings/');
    final data = resp.data;
    return AssistantFeatureSettings.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  /// Список ассистентов (минимальный маппинг под текущую модель)
  Future<List<Assistant>> fetchAssistants() async {
    final resp = await _client.get<dynamic>('/assistants/list/');
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list
        .map(
          (e) => Assistant(
            id: '${e['id']}',
            name: (e['name'] ?? '').toString(),
            description: (e['description'] as String?)?.trim(),
            settings: (e['settings'] is Map)
                ? AssistantSettings.fromBackend(Map<String, dynamic>.from(e['settings'] as Map))
                : null,
          ),
        )
        .toList();
  }

  /// Список ассистентов (сырой JSON), нужен для раздельного разбирательства settings
  Future<List<Map<String, dynamic>>> fetchAssistantsRaw() async {
    final resp = await _client.get<dynamic>('/assistants/list/');
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }
}

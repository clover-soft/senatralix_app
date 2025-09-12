import 'package:sentralix_app/data/api/api_client.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';
import 'package:sentralix_app/features/assistant/models/assistant_feature_settings.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';

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

  /// Список коннекторов ассистента (READ)
  Future<List<Connector>> fetchConnectorsList({int limit = 100, int offset = 0}) async {
    final resp = await _client.get<dynamic>('/assistant/connectors/list?limit=$limit&offset=$offset');
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map((e) => Connector.fromJson(e)).toList();
  }

  /// Список коннекторов, подключенных к ассистенту (возвращает external_id)
  Future<Set<String>> fetchAssistantAttachedConnectors(String assistantId, {int limit = 50, int offset = 0}) async {
    final resp = await _client.get<dynamic>('/assistants/$assistantId/connectors', query: {
      'limit': '$limit',
      'offset': '$offset',
    });
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list
        .map((e) => (e['external_id'] as String?)?.trim())
        .whereType<String>()
        .toSet();
  }

  /// Создание нового коннектора на бэкенде. Возвращает созданный объект с дефолтными значениями.
  Future<Connector> createConnector({required String name}) async {
    final resp = await _client.post<dynamic>(
      '/assistant/connectors/create-default',
      data: {'name': name},
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return Connector.fromJson(data);
  }

  /// Обновление коннектора (PATCH) по id. Отправляем полную структуру, как в ответах бэкенда.
  Future<Connector> updateConnector(Connector connector) async {
    final resp = await _client.patch<dynamic>(
      '/assistant/connectors/${connector.id}',
      data: connector.toJson(),
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return Connector.fromJson(data);
  }

  /// Удаление коннектора по id
  Future<void> deleteConnector(String id) async {
    await _client.delete<dynamic>('/assistant/connectors/$id');
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

  /// Список баз знаний (READ)
  Future<List<KnowledgeBaseItem>> fetchKnowledgeList() async {
    final resp = await _client.get<dynamic>('/assistants/knowledge/list');
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map((e) {
      final settings = Map<String, dynamic>.from(e['settings'] as Map? ?? const {});
      return KnowledgeBaseItem(
        id: int.tryParse('${e['id']}') ?? 0,
        name: (settings['name'] as String?)?.trim() ?? '',
        description: (settings['description'] as String?)?.trim() ?? '',
        externalId: (e['external_id'] as String?)?.trim() ?? '',
        markdown: (e['markdown'] as String?) ?? '',
        status: KnowledgeStatus.ready,
        active: true,
        maxChunkSizeTokens: int.tryParse('${settings['max_chunk_size_tokens']}') ?? 700,
        chunkOverlapTokens: int.tryParse('${settings['chunk_overlap_tokens']}') ?? 300,
        createdAt: DateTime.tryParse('${e['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${e['updated_at']}') ?? DateTime.now(),
      );
    }).toList();
  }

  /// Обновление базы знаний (PATCH) по id. Возвращает сырой JSON ответа бэкенда.
  Future<Map<String, dynamic>> updateKnowledgeRaw({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.patch<dynamic>('/assistants/knowledge/$id', data: body);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Удобный метод: собрать тело запроса из модели KnowledgeBaseItem и выполнить PATCH
  Future<Map<String, dynamic>> updateKnowledge(KnowledgeBaseItem item) async {
    final body = <String, dynamic>{
      'id': item.id,
      'markdown': item.markdown,
      'settings': {
        'max_chunk_size_tokens': item.maxChunkSizeTokens,
        'chunk_overlap_tokens': item.chunkOverlapTokens,
        'name': item.name,
        'description': item.description.isEmpty ? null : item.description,
      },
    };
    return updateKnowledgeRaw(id: item.id, body: body);
  }
}

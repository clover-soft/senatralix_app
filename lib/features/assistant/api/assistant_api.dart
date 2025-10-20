import 'dart:convert';
import 'package:sentralix_app/data/api/api_client.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';
import 'package:sentralix_app/features/assistant/models/assistant_feature_settings.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
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
    // Возможные форматы:
    // 1) Уже готовый объект assistants {...}
    // 2) Объект { subscription: { settings: "{...}" } }, где внутри settings есть ключ assistants
    if (data is Map && data['subscription'] is Map) {
      final sub = Map<String, dynamic>.from(data['subscription'] as Map);
      final rawSettings = sub['settings'];
      if (rawSettings is String && rawSettings.isNotEmpty) {
        final parsed = jsonDecode(rawSettings);
        if (parsed is Map && parsed['assistants'] is Map) {
          final assistants = Map<String, dynamic>.from(
            parsed['assistants'] as Map,
          );
          final s = AssistantFeatureSettings.fromJson(assistants);
          return s;
        }
      } else if (rawSettings is Map && rawSettings['assistants'] is Map) {
        final assistants = Map<String, dynamic>.from(
          rawSettings['assistants'] as Map,
        );
        final s = AssistantFeatureSettings.fromJson(assistants);
        return s;
      }
    }
    // Альтернативный формат: на верхнем уровне есть settings
    if (data is Map && data['settings'] != null) {
      final rawTop = data['settings'];
      if (rawTop is String && rawTop.isNotEmpty) {
        final parsed = jsonDecode(rawTop);
        if (parsed is Map && parsed['assistants'] is Map) {
          final assistants = Map<String, dynamic>.from(
            parsed['assistants'] as Map,
          );
          final s = AssistantFeatureSettings.fromJson(assistants);
          return s;
        }
      } else if (rawTop is Map && rawTop['assistants'] is Map) {
        final assistants = Map<String, dynamic>.from(
          rawTop['assistants'] as Map,
        );
        final s = AssistantFeatureSettings.fromJson(assistants);
        return s;
      }
    }
    // Fallback: считаем, что data уже имеет нужные поля
    AssistantFeatureSettings s = AssistantFeatureSettings.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
    // Если лимит не пришёл (==0), попробуем достать из /me/context
    if (s.connectors.maxConnectorItems == 0) {
      try {
        final ctxResp = await _client.get<dynamic>('/me/context');
        final ctx = ctxResp.data;
        if (ctx is Map && ctx['subscription'] is Map) {
          final sub = Map<String, dynamic>.from(ctx['subscription'] as Map);
          final raw = sub['settings'];
          Map<String, dynamic>? assistants;
          if (raw is String && raw.isNotEmpty) {
            final parsed = jsonDecode(raw);
            if (parsed is Map && parsed['assistants'] is Map) {
              assistants = Map<String, dynamic>.from(
                parsed['assistants'] as Map,
              );
            }
          } else if (raw is Map && raw['assistants'] is Map) {
            assistants = Map<String, dynamic>.from(raw['assistants'] as Map);
          }
          if (assistants != null) {
            final s2 = AssistantFeatureSettings.fromJson(assistants);
            s = s.copyWith(
              connectors: s2.connectors,
              maxAssistantItems: s2.maxAssistantItems,
              allowedModels: s2.allowedModels,
            );
          }
        }
      } catch (e) {
        // ignore
      }
    }
    return s;
  }

  /// Список коннекторов ассистента (READ)
  Future<List<Connector>> fetchConnectorsList({
    int limit = 100,
    int offset = 0,
  }) async {
    final resp = await _client.get<dynamic>(
      '/assistant/connectors/list?limit=$limit&offset=$offset',
    );
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map((e) => Connector.fromJson(e)).toList();
  }

  /// Привязать базу знаний к ассистенту. Возвращает external_id привязанной БЗ
  Future<String> bindKnowledgeToAssistant({
    required String assistantId,
    required int knowledgeId,
  }) async {
    final resp = await _client.post<dynamic>(
      '/assistants/$assistantId/knowledge/$knowledgeId/bind',
      data: {},
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return data['external_id']?.toString() ?? '';
  }

  /// Отвязать базу знаний от ассистента
  Future<void> unbindKnowledgeFromAssistant({
    required String assistantId,
    required int knowledgeId,
  }) async {
    await _client.post<dynamic>(
      '/assistants/$assistantId/knowledge/$knowledgeId/unbind',
      data: {},
    );
  }

  /// Создать новую базу знаний (общую), возвращает заполненный объект
  Future<KnowledgeBaseItem> createKnowledgeBase() async {
    final resp = await _client.post<dynamic>(
      '/assistants/knowledge/',
      data: {},
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return KnowledgeBaseItem.fromJson(data);
  }

  /// Удалить базу знаний по id (204 без контента при успехе)
  Future<void> deleteKnowledgeBase(int id) async {
    await _client.delete<void>('/assistants/knowledge/$id');
  }

  /// Список коннекторов, подключенных к ассистенту (возвращает external_id)
  Future<Set<String>> fetchAssistantAttachedConnectors(
    String assistantId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await _client.get<dynamic>(
      '/assistants/$assistantId/connectors',
      query: {'limit': '$limit', 'offset': '$offset'},
    );
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list
        .map((e) => (e['external_id'] as String?)?.trim())
        .whereType<String>()
        .toSet();
  }

  /// Назначить коннектор ассистенту
  Future<Map<String, dynamic>> assignConnectorToAssistant({
    required String assistantId,
    required String externalId,
    required String type,
  }) async {
    final resp = await _client.post<dynamic>(
      '/assistants/connectors/assign',
      data: {
        'assistant_id': assistantId,
        'external_id': externalId,
        'type': type,
      },
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Удалить конфигурацию диалога по id (204 No Content при успехе)
  Future<void> deleteDialogConfig(int id) async {
    await _client.delete<void>('/assistants/dialog-configs/$id');
  }

  /// Создать конфигурацию диалога с начальными шагами (CREATE)
  /// POST /assistants/dialog-configs/
  /// Тело запроса поддерживает ключ "config": { "steps": [...] }
  Future<Map<String, dynamic>> createDialogConfigFull({
    required String name,
    String? description,
    required List<DialogStep> steps,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'config': {
        'steps': steps.map((e) => e.toBackendJson()).toList(),
      },
      'metadata': metadata ?? <String, dynamic>{},
    };
    final resp = await _client.post<dynamic>(
      '/assistants/dialog-configs/',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Полное обновление конфигурации диалога с передачей шагов и метаданных
  /// PATCH /assistants/dialog-configs/{id}
  /// Тело запроса:
  /// {
  ///   "name": "...",
  ///   "description": "...",
  ///   "config": { "steps": [ { ...step... } ] },
  ///   "metadata": { ... }
  /// }
  Future<Map<String, dynamic>> updateDialogConfigFull({
    required int id,
    required String name,
    String? description,
    required List<DialogStep> steps,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null) 'description': description,
      'config': {
        'steps': steps.map((e) => e.toBackendJson()).toList(),
      },
      'metadata': metadata ?? <String, dynamic>{},
    };
    final resp = await _client.patch<dynamic>(
      '/assistants/dialog-configs/$id',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Обновить конфигурацию диалога (PATCH)
  /// PATCH /assistants/dialog-configs/{id}
  /// Возвращает обновлённый объект (сырой JSON)
  Future<Map<String, dynamic>> updateDialogConfig({
    required int id,
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': (description?.trim().isEmpty ?? true)
          ? null
          : description!.trim(),
    };
    final resp = await _client.patch<dynamic>(
      '/assistants/dialog-configs/$id',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Разназначить коннектор от ассистента
  Future<void> unassignConnectorFromAssistant({
    required String assistantId,
    required String externalId,
  }) async {
    await _client.post<dynamic>(
      '/assistants/connectors/unassign',
      data: {'assistant_id': assistantId, 'external_id': externalId},
    );
  }

  /// Список тулсов ассистента (READ)
  Future<List<AssistantTool>> fetchAssistantTools({
    required String assistantId,
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await _client.get<dynamic>(
      '/assistants/tools/',
      query: {
        'assistant_id': assistantId,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list
        .map((e) => AssistantTool.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Создание function-tool для ассистента
  Future<AssistantTool> createAssistantTool({
    required String assistantId,
    required String type,
    required String name,
    required String displayName,
    required String description,
    required Map<String, dynamic> parameters,
    bool isActive = true,
  }) async {
    final resp = await _client.post<dynamic>(
      '/assistants/tools/',
      data: {
        'assistant_id': assistantId,
        'type': type,
        'name': name,
        'display_name': displayName,
        'description': description,
        'parameters': parameters,
        'is_active': isActive,
      },
    );
    return AssistantTool.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// Частичное обновление инструмента
  Future<AssistantTool> updateAssistantTool({
    required int toolId,
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.patch<dynamic>(
      '/assistants/tools/$toolId/',
      data: body,
    );
    return AssistantTool.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// Удаление инструмента
  Future<void> deleteAssistantTool(int toolId) async {
    await _client.delete<dynamic>('/assistants/tools/$toolId/');
  }

  /// Перестановка инструментов ассистента
  Future<void> reorderAssistantTools({
    required String assistantId,
    required List<int> orderedIds,
  }) async {
    await _client.post<dynamic>(
      '/assistants/tools/reorder/',
      data: {
        'assistant_id': assistantId,
        'tool_ids': orderedIds,
      },
    );
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

  /// Обновление ядра ассистента (имя/описание и ключевые настройки)
  /// PATCH /assistants/{assistantId}/core
  /// Тело запроса (по спецификации бэкенда):
  /// {
  ///   "name": "...",
  ///   "description": "...",
  ///   "model": "...",
  ///   "maxTokens": 150,
  ///   "instruction": "...",
  ///   "temperature": 0.5
  /// }
  Future<Assistant> updateAssistantCore({
    required String assistantId,
    required String name,
    String? description,
    required AssistantSettings settings,
    int? dialogId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': (description?.trim().isEmpty ?? true)
          ? null
          : description!.trim(),
      'model': settings.model,
      'maxTokens': settings.maxTokens,
      'instruction': settings.instruction,
      'temperature': settings.temperature,
      // Передаём dialog_id всегда: null снимает привязку
      'dialog_id': dialogId,
    };
    final resp = await _client.patch<dynamic>(
      '/assistants/$assistantId/core',
      data: body,
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return Assistant(
      id: '${data['id']}',
      name: (data['name'] ?? '').toString(),
      description: (data['description'] as String?)?.trim(),
      settings: (data['settings'] is Map)
          ? AssistantSettings.fromBackend(
              Map<String, dynamic>.from(data['settings'] as Map),
            )
          : null,
      dialogId: (data['dialog_id'] != null)
          ? int.tryParse('${data['dialog_id']}')
          : null,
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
                ? AssistantSettings.fromBackend(
                    Map<String, dynamic>.from(e['settings'] as Map),
                  )
                : null,
            dialogId: (e['dialog_id'] != null)
                ? int.tryParse('${e['dialog_id']}')
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

  /// Слоты диалога (READ)
  Future<List<Map<String, dynamic>>> fetchDialogSlots() async {
    final resp = await _client.get<dynamic>('/assistants/dialog-slots/');
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Список конфигураций диалогов (READ)
  Future<List<Map<String, dynamic>>> fetchDialogConfigs() async {
    final resp = await _client.get<dynamic>('/assistants/dialog-configs/');
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Детали конфигурации диалога по id (READ)
  Future<Map<String, dynamic>> fetchDialogConfig(int id) async {
    final resp = await _client.get<dynamic>('/assistants/dialog-configs/$id');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Создать конфигурацию диалога (CREATE)
  /// POST /assistants/dialog-configs/
  /// Возвращает созданный объект (сырой JSON)
  Future<Map<String, dynamic>> createDialogConfig({
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final resp = await _client.post<dynamic>(
      '/assistants/dialog-configs/',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Создать слот диалога (POST)
  Future<DialogSlot> createDialogSlot({
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.post<dynamic>(
      '/assistants/dialog-slots/',
      data: body,
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return DialogSlot.fromJson(data);
  }

  /// Удалить слот диалога (DELETE). Возвращает 204 No Content.
  Future<void> deleteDialogSlot(int id) async {
    await _client.delete<void>('/assistants/dialog-slots/$id');
  }

  /// Обновить слот диалога (PATCH)
  Future<DialogSlot> updateDialogSlot({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.patch<dynamic>(
      '/assistants/dialog-slots/$id',
      data: body,
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    return DialogSlot.fromJson(data);
  }

  /// Список шагов команды (thread-command steps)
  Future<List<Map<String, dynamic>>> fetchThreadCommandSteps({
    required int commandId,
  }) async {
    final resp = await _client.get<dynamic>(
      '/assistants/thread-commands/$commandId/steps',
    );
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Заглушка: перестановка шагов скрипта
  Future<void> reorderThreadCommandSteps({
    required int commandId,
    required List<int> orderedStepIds,
  }) async {
    // Перебираем шаги и обновляем их priority через PATCH
    int pr = 1;
    for (final stepId in orderedStepIds) {
      await updateThreadCommandStep(
        stepId: stepId,
        body: {
          'priority': pr,
        },
      );
      pr++;
    }
  }

  /// Заглушка: обновление активности шага скрипта
  Future<void> setThreadCommandStepActive({
    required int stepId,
    required bool isActive,
  }) async {
    await updateThreadCommandStep(
      stepId: stepId,
      body: {
        'is_active': isActive,
      },
    );
  }

  /// Заглушка: удаление шага скрипта
  Future<void> deleteThreadCommandStep(int stepId) async {
    await _client.delete<dynamic>(
      '/assistants/thread-commands/steps/$stepId',
    );
  }

  /// Создать шаг команды (thread-command step)
  /// POST /assistants/thread-commands/{commandId}/steps
  /// Возвращает созданный шаг (сырой JSON)
  Future<Map<String, dynamic>> createThreadCommandStep({
    required int commandId,
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.post<dynamic>(
      '/assistants/thread-commands/$commandId/steps',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Обновить шаг команды (PATCH)
  /// PATCH /assistants/thread-commands/steps/{stepId}
  /// Возвращает обновлённый шаг (сырой JSON)
  Future<Map<String, dynamic>> updateThreadCommandStep({
    required int stepId,
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.patch<dynamic>(
      '/assistants/thread-commands/steps/$stepId',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Список баз знаний (READ)
  Future<List<KnowledgeBaseItem>> fetchKnowledgeList() async {
    final resp = await _client.get<dynamic>('/assistants/knowledge/list');
    final data = resp.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list
        .map((e) => KnowledgeBaseItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Обновление базы знаний (PATCH) по id. Возвращает сырой JSON ответа бэкенда.
  Future<Map<String, dynamic>> updateKnowledgeRaw({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final resp = await _client.patch<dynamic>(
      '/assistants/knowledge/$id',
      data: body,
    );
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

  /// Список скриптов (thread-commands) для ассистента
  /// GET `/assistants/thread-commands/?assistant_id=<id>&limit=<limit>&offset=<offset>`
  Future<List<Map<String, dynamic>>> fetchScriptCommands({
    required String assistantId,
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await _client.get<dynamic>(
      '/assistants/thread-commands/',
      query: {
        'assistant_id': assistantId,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Создать новую команду (thread-command)
  Future<Map<String, dynamic>> createThreadCommand({
    required int assistantId,
    required int order,
    required String name,
    required String description,
    required String filterExpression,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'assistant_id': assistantId,
      'order': order,
      'name': name,
      'description': description,
      'filter_expression': filterExpression,
      'is_active': isActive,
    };
    final resp = await _client.post<dynamic>(
      '/assistants/thread-commands/',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Обновить команду (thread-command) по id (PATCH)
  /// Требуется полный набор полей, как в ответе бэкенда
  Future<Map<String, dynamic>> updateThreadCommandRaw({
    required int id,
    required int assistantId,
    required int order,
    required String name,
    required String description,
    required String filterExpression,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'assistant_id': assistantId,
      'order': order,
      'name': name,
      'description': description,
      'filter_expression': filterExpression,
      'is_active': isActive,
      'id': id,
    };
    final resp = await _client.patch<dynamic>(
      '/assistants/thread-commands/$id',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Удобный метод: обновить команду из JSON (если где-то имеется сырая модель)
  Future<Map<String, dynamic>> updateThreadCommandFromItem(
      Map<String, dynamic> itemJson) async {
    final id = int.tryParse('${itemJson['id']}') ?? 0;
    final assistantId = int.tryParse('${itemJson['assistant_id']}') ?? 0;
    final order = int.tryParse('${itemJson['order']}') ?? 0;
    final name = (itemJson['name'] ?? '').toString();
    final description = (itemJson['description'] ?? '').toString();
    final filterExpression = (itemJson['filter_expression'] ?? '').toString();
    final isActive = (itemJson['is_active'] as bool?) ?? true;
    return updateThreadCommandRaw(
      id: id,
      assistantId: assistantId,
      order: order,
      name: name,
      description: description,
      filterExpression: filterExpression,
      isActive: isActive,
    );
  }

  /// Удалить команду (thread-command) по id (204 No Content при успехе)
  Future<void> deleteThreadCommand(int id) async {
    await _client.delete<void>('/assistants/thread-commands/$id');
  }

  /// Список тредов ассистента (чаты)
  /// GET `/assistants/threads/?assistant_id=<id>&limit=<limit>&offset=<offset>&created_from=<iso>&created_to=<iso>`
  Future<List<Map<String, dynamic>>> fetchAssistantThreads({
    required String assistantId,
    int limit = 10,
    int offset = 0,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    final query = <String, String>{
      'assistant_id': assistantId,
      'limit': '$limit',
      'offset': '$offset',
      if (createdFrom != null) 'created_from': createdFrom.toIso8601String(),
      if (createdTo != null) 'created_to': createdTo.toIso8601String(),
    };
    final resp = await _client.get<dynamic>(
      '/assistants/threads/',
      query: query,
    );
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Таймлайн треда (по internal_id)
  /// GET `/assistants/threads/{internalId}/timeline`
  Future<List<Map<String, dynamic>>> fetchThreadTimeline(String internalId) async {
    final resp = await _client.get<dynamic>(
      '/assistants/threads/$internalId/timeline',
    );
    final data = resp.data;
    return List<Map<String, dynamic>>.from(data as List);
  }
}

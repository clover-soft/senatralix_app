import 'package:flutter/foundation.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';

/// Модель настроек ассистента (упрощённая)
@immutable
class AssistantSettings {
  final String model;
  final String instruction;
  final double temperature; // 0.0–2.0
  final int maxTokens; // > 0
  final List<AssistantFunctionTool> tools;
  // Список external_id баз знаний, подключённых к ассистенту (из tools.searchIndex)
  final Set<String> knowledgeExternalIds;

  const AssistantSettings({
    required this.model,
    required this.instruction,
    required this.temperature,
    required this.maxTokens,
    this.tools = const [],
    this.knowledgeExternalIds = const {},
  });

  factory AssistantSettings.defaults() => const AssistantSettings(
    model: 'yandexgpt',
    instruction: '',
    temperature: 0.7,
    maxTokens: 512,
    tools: [],
    knowledgeExternalIds: {},
  );

  AssistantSettings copyWith({
    String? model,
    String? instruction,
    double? temperature,
    int? maxTokens,
    List<AssistantFunctionTool>? tools,
    Set<String>? knowledgeExternalIds,
  }) => AssistantSettings(
    model: model ?? this.model,
    instruction: instruction ?? this.instruction,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens ?? this.maxTokens,
    tools: tools ?? this.tools,
    knowledgeExternalIds: knowledgeExternalIds ?? this.knowledgeExternalIds,
  );

  Map<String, dynamic> toJson() => {
    'model': model,
    'instruction': instruction,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'tools': tools.map((t) => t.toJson()).toList(),
    'knowledgeExternalIds': knowledgeExternalIds.toList(),
  };

  factory AssistantSettings.fromJson(
    Map<String, dynamic> json,
  ) => AssistantSettings(
    model: json['model'] as String? ?? 'yandexgpt',
    instruction: json['instruction'] as String? ?? '',
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    maxTokens: int.tryParse('${json['maxTokens']}') ?? 512,
    tools:
        (json['tools'] as List?)
            ?.whereType<Map>()
            .map(
              (e) =>
                  AssistantFunctionTool.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList() ??
        const [],
    knowledgeExternalIds: ((json['knowledgeExternalIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet(),
  );

  /// Фабрика для маппинга вложенного JSON из бэкенда в списке ассистентов
  /// Ожидается структура:
  /// {
  ///   "model": "...",
  ///   "instruction": "...",
  ///   "completionOptions": { "temperature": 0.1, "maxTokens": "150" }
  /// }
  factory AssistantSettings.fromBackend(Map<String, dynamic> json) {
    final completion = Map<String, dynamic>.from(
      json['completionOptions'] as Map? ?? const {},
    );
    final temp = (completion['temperature'] as num?)?.toDouble();
    final maxT = completion['maxTokens'];
    final rawTools = (json['tools'] as List?) ?? const [];
    final tools = <AssistantFunctionTool>[];
    final knowledge = <String>{};
    for (var i = 0; i < rawTools.length; i++) {
      final item = rawTools[i];
      if (item is Map && item['function'] is Map) {
        final fnMap = Map<String, dynamic>.from(item['function'] as Map);
        final def = FunctionToolDef.fromJson(fnMap);
        final name = def.name.isNotEmpty ? def.name : 'tool_$i';
        tools.add(
          AssistantFunctionTool(id: 'fn-$i-$name', enabled: true, def: def),
        );
      } else if (item is Map && item['searchIndex'] is List) {
        final ids = (item['searchIndex'] as List).map((e) => e.toString());
        knowledge.addAll(ids);
      }
      // иные типы (searchIndex и т.п.) пропускаем на этом этапе
    }
    return AssistantSettings(
      model: json['model'] as String? ?? 'yandexgpt',
      instruction: json['instruction'] as String? ?? '',
      temperature: temp ?? 0.7,
      maxTokens: int.tryParse('$maxT') ?? 512,
      tools: tools,
      knowledgeExternalIds: knowledge,
    );
  }
}

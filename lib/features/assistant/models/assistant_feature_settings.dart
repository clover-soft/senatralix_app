import 'package:flutter/foundation.dart';

/// Настройки надфичи Assistant, возвращаемые бэкендом
@immutable
class AssistantFeatureSettings {
  final int maxAssistantItems;
  final List<String> allowedModels;
  final ConnectorsSettings connectors;
  final ScriptsSettings scripts;
  final ToolsSettings tools;

  const AssistantFeatureSettings({
    required this.maxAssistantItems,
    required this.allowedModels,
    required this.connectors,
    required this.scripts,
    required this.tools,
  });

  factory AssistantFeatureSettings.fromJson(Map<String, dynamic> json) {
    return AssistantFeatureSettings(
      maxAssistantItems: json['max_assistent_items'] as int? ?? 0,
      allowedModels: (json['allowed_models'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      connectors: ConnectorsSettings.fromJson(Map<String, dynamic>.from(json['connectors'] as Map? ?? const {})),
      scripts: ScriptsSettings.fromJson(Map<String, dynamic>.from(json['scripts'] as Map? ?? const {})),
      tools: ToolsSettings.fromJson(Map<String, dynamic>.from(json['tools'] as Map? ?? const {})),
    );
  }

  AssistantFeatureSettings copyWith({
    int? maxAssistantItems,
    List<String>? allowedModels,
    ConnectorsSettings? connectors,
    ScriptsSettings? scripts,
    ToolsSettings? tools,
  }) => AssistantFeatureSettings(
        maxAssistantItems: maxAssistantItems ?? this.maxAssistantItems,
        allowedModels: allowedModels ?? this.allowedModels,
        connectors: connectors ?? this.connectors,
        scripts: scripts ?? this.scripts,
        tools: tools ?? this.tools,
      );
}

@immutable
class ConnectorsSettings {
  final int maxConnectorItems;
  final List<String> types;
  final List<String> dictors;

  const ConnectorsSettings({
    required this.maxConnectorItems,
    required this.types,
    required this.dictors,
  });

  factory ConnectorsSettings.fromJson(Map<String, dynamic> json) => ConnectorsSettings(
        maxConnectorItems: (json['max_connector_items'] is num)
            ? (json['max_connector_items'] as num).toInt()
            : int.tryParse('${json['max_connector_items']}') ?? 0,
        types: (json['types'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        dictors: (json['dictors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

@immutable
class ScriptsSettings {
  final int maxScriptItems;

  const ScriptsSettings({required this.maxScriptItems});

  factory ScriptsSettings.fromJson(Map<String, dynamic> json) =>
      ScriptsSettings(maxScriptItems: json['max_script_items'] as int? ?? 0);
}

@immutable
class ToolsSettings {
  final int maxToolsItems;

  const ToolsSettings({required this.maxToolsItems});

  factory ToolsSettings.fromJson(Map<String, dynamic> json) =>
      ToolsSettings(maxToolsItems: json['max_tools_items'] as int? ?? 0);
}

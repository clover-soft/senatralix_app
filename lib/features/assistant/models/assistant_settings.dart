import 'package:flutter/foundation.dart';
/// Модель настроек ассистента (упрощённая)
@immutable
class AssistantSettings {
  final String model;
  final String instruction;
  final double temperature; // 0.0–2.0
  final int maxTokens; // > 0

  const AssistantSettings({
    required this.model,
    required this.instruction,
    required this.temperature,
    required this.maxTokens,
  });

  factory AssistantSettings.defaults() => const AssistantSettings(
    model: 'yandexgpt',
    instruction: '',
    temperature: 0.7,
    maxTokens: 512,
  );

  AssistantSettings copyWith({
    String? model,
    String? instruction,
    double? temperature,
    int? maxTokens,
  }) => AssistantSettings(
    model: model ?? this.model,
    instruction: instruction ?? this.instruction,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens ?? this.maxTokens,
  );

  Map<String, dynamic> toJson() => {
    'model': model,
    'instruction': instruction,
    'temperature': temperature,
    'maxTokens': maxTokens,
  };

  factory AssistantSettings.fromJson(
    Map<String, dynamic> json,
  ) => AssistantSettings(
    model: json['model'] as String? ?? 'yandexgpt',
    instruction: json['instruction'] as String? ?? '',
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    maxTokens: int.tryParse('${json['maxTokens']}') ?? 512,
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
    return AssistantSettings(
      model: json['model'] as String? ?? 'yandexgpt',
      instruction: json['instruction'] as String? ?? '',
      temperature: temp ?? 0.7,
      maxTokens: int.tryParse('$maxT') ?? 512,
    );
  }
}

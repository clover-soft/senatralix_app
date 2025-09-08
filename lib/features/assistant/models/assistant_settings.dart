import 'package:flutter/foundation.dart';

/// Модель настроек ассистента (упрощённая)
@immutable
class AssistantSettings {
  final String model;
  final String modelVersion;
  final String instruction;
  final double temperature; // 0.0–2.0
  final int maxTokens; // > 0

  const AssistantSettings({
    required this.model,
    required this.modelVersion,
    required this.instruction,
    required this.temperature,
    required this.maxTokens,
  });

  factory AssistantSettings.defaults() => const AssistantSettings(
        model: 'yandexgpt',
        modelVersion: 'latest',
        instruction: '',
        temperature: 0.7,
        maxTokens: 512,
      );

  AssistantSettings copyWith({
    String? model,
    String? modelVersion,
    String? instruction,
    double? temperature,
    int? maxTokens,
  }) => AssistantSettings(
        model: model ?? this.model,
        modelVersion: modelVersion ?? this.modelVersion,
        instruction: instruction ?? this.instruction,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
      );

  Map<String, dynamic> toJson() => {
        'model': model,
        'modelVersion': modelVersion,
        'instruction': instruction,
        'temperature': temperature,
        'maxTokens': maxTokens,
      };

  factory AssistantSettings.fromJson(Map<String, dynamic> json) => AssistantSettings(
        model: json['model'] as String? ?? 'yandexgpt',
        modelVersion: json['modelVersion'] as String? ?? 'latest',
        instruction: json['instruction'] as String? ?? '',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        maxTokens: int.tryParse('${json['maxTokens']}') ?? 512,
      );
}

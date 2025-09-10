import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';

/// Состояние формы настроек ассистента (локальное для диалога/экрана)
class SettingsEditState {
  SettingsEditState({
    required this.model,
    required this.instruction,
    required this.temperature,
    required this.maxTokens,
  });

  final String model;
  final String instruction;
  final double temperature;
  final int maxTokens;

  SettingsEditState copy({
    String? model,
    String? instruction,
    double? temperature,
    int? maxTokens,
  }) => SettingsEditState(
        model: model ?? this.model,
        instruction: instruction ?? this.instruction,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
      );

  static SettingsEditState fromSettings(AssistantSettings s) => SettingsEditState(
        model: s.model,
        instruction: s.instruction,
        temperature: s.temperature,
        maxTokens: s.maxTokens,
      );
}

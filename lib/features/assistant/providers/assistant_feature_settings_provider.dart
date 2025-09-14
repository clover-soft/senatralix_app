import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant_feature_settings.dart';

@immutable
class AssistantFeatureSettingsState {
  final AssistantFeatureSettings settings;
  const AssistantFeatureSettingsState(this.settings);

  AssistantFeatureSettingsState copyWith({
    AssistantFeatureSettings? settings,
  }) => AssistantFeatureSettingsState(settings ?? this.settings);
}

class AssistantFeatureSettingsNotifier
    extends StateNotifier<AssistantFeatureSettingsState> {
  AssistantFeatureSettingsNotifier()
    : super(
        AssistantFeatureSettingsState(
          const AssistantFeatureSettings(
            maxAssistantItems: 10,
            allowedModels: ['YandexGPT Pro 5.1', 'YandexGPT Lite'],
            connectors: ConnectorsSettings(
              maxConnectorItems: 10,
              types: ['voip'],
              dictors: ['alena_good', 'lera_friendly'],
            ),
            scripts: ScriptsSettings(maxScriptItems: 10),
            tools: ToolsSettings(maxToolsItems: 10),
          ),
        ),
      );

  void setFromJson(Map<String, dynamic> json) {
    state = state.copyWith(settings: AssistantFeatureSettings.fromJson(json));
  }

  void set(AssistantFeatureSettings newSettings) {
    state = state.copyWith(settings: newSettings);
  }
}

final assistantFeatureSettingsProvider =
    StateNotifierProvider<
      AssistantFeatureSettingsNotifier,
      AssistantFeatureSettingsState
    >((ref) => AssistantFeatureSettingsNotifier());

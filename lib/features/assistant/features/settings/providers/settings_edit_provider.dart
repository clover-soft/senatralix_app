import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/settings/models/settings_edit_state.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';

class SettingsEditController extends StateNotifier<SettingsEditState> {
  SettingsEditController(AssistantSettings initial)
    : super(SettingsEditState.fromSettings(initial));

  void setModel(String v) => state = state.copy(model: v);
  void setInstruction(String v) => state = state.copy(instruction: v);
  void setTemperature(double v) => state = state.copy(temperature: v);
  void setMaxTokens(int v) => state = state.copy(maxTokens: v);

  AssistantSettings buildResult() => AssistantSettings(
    model: state.model.trim(),
    instruction: state.instruction,
    temperature: state.temperature,
    maxTokens: state.maxTokens,
  );
}

final settingsEditProvider = StateNotifierProvider.autoDispose
    .family<SettingsEditController, SettingsEditState, AssistantSettings>((
      ref,
      initial,
    ) {
      return SettingsEditController(initial);
    });

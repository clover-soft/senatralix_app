import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector_edit_state.dart';

class ConnectorEditController extends StateNotifier<ConnectorEditState> {
  ConnectorEditController(Connector initial)
      : super(ConnectorEditState.fromConnector(initial));

  void setName(String v) => state = state.copy(name: v);
  void setActive(bool v) => state = state.copy(isActive: v);
  void setVoice(String v) => state = state.copy(voice: v);
  void setVoiceSpeed(double v) => state = state.copy(voiceSpeed: v);
  void setGreetingTexts(String v) => state = state.copy(greetingTexts: v);
  void setRepromptTexts(String v) => state = state.copy(repromptTexts: v);
  void setAllowBargeIn(bool v) => state = state.copy(allowBargeIn: v);

  Connector buildResult(Connector initial) => initial.copyWith(
        name: state.name.trim(),
        isActive: state.isActive,
        settings: ConnectorSettings(
          ttsVoicePool: [TtsVoice(voice: state.voice, speed: state.voiceSpeed)],
          ttsLexicon: initial.settings.ttsLexicon,
          dialogGreetingTexts: state.greetingTexts
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          dialogRepromptTexts: state.repromptTexts
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          dialogAllowBargeIn: state.allowBargeIn,
        ),
      );
}

final connectorEditProvider = StateNotifierProvider.autoDispose
    .family<ConnectorEditController, ConnectorEditState, Connector>((ref, initial) {
  return ConnectorEditController(initial);
});

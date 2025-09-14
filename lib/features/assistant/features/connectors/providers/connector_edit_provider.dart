import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector_edit_state.dart';

class ConnectorEditController extends StateNotifier<ConnectorEditState> {
  ConnectorEditController(Connector initial)
    : super(ConnectorEditState.fromConnector(initial));

  void setName(String v) => state = state.copy(name: v);
  void setActive(bool v) => state = state.copy(isActive: v);
  void setGreetingTexts(List<String> v) => state = state.copy(greetingTexts: v);
  void setGreetingStrategy(String v) =>
      state = state.copy(greetingSelectionStrategy: v);
  void setRepromptTexts(List<String> v) => state = state.copy(repromptTexts: v);
  void setRepromptStrategy(String v) =>
      state = state.copy(repromptSelectionStrategy: v);
  void setAllowBargeIn(bool v) => state = state.copy(allowBargeIn: v);
  void setSoftTimeoutMs(int v) => state = state.copy(softTimeoutMs: v);
  void setFillerList(List<String> v) => state = state.copy(fillerTextList: v);
  void setFillerStrategy(String v) =>
      state = state.copy(fillerSelectionStrategy: v);
  void setDictor(String v) => state = state.copy(dictor: v);
  void setSpeed(double v) => state = state.copy(speed: v);

  Connector buildResult(Connector initial) => initial.copyWith(
    name: state.name.trim(),
    isActive: state.isActive,
    settings: ConnectorSettings(
      dialog: ConnectorDialogSettings(
        greetingTexts: state.greetingTexts,
        greetingSelectionStrategy: state.greetingSelectionStrategy,
        repromptTexts: state.repromptTexts,
        repromptSelectionStrategy: state.repromptSelectionStrategy,
        allowBargeIn: state.allowBargeIn,
        maxTurns: initial.settings.dialog.maxTurns,
        noinputRetries: initial.settings.dialog.noinputRetries,
        hangupOnNoinput: initial.settings.dialog.hangupOnNoinput,
        maxCallDurationSec: initial.settings.dialog.maxCallDurationSec,
        repeatPromptOnInterrupt:
            initial.settings.dialog.repeatPromptOnInterrupt,
        interruptMaxRetries: initial.settings.dialog.interruptMaxRetries,
        interruptFinalText: initial.settings.dialog.interruptFinalText,
        noinputFinalText: initial.settings.dialog.noinputFinalText,
        maxTurnsFinalText: initial.settings.dialog.maxTurnsFinalText,
        maxCallDurationFinalText:
            initial.settings.dialog.maxCallDurationFinalText,
      ),
      assistant: ConnectorAssistantSettings(
        fillerTextList: state.fillerTextList,
        fillerSelectionStrategy: state.fillerSelectionStrategy,
        softTimeoutMs: state.softTimeoutMs,
        dictor: state.dictor,
        speed: state.speed,
      ),
      allowDelete: initial.settings.allowDelete,
      allowUpdate: initial.settings.allowUpdate,
    ),
  );
}

final connectorEditProvider = StateNotifierProvider.autoDispose
    .family<ConnectorEditController, ConnectorEditState, Connector>((
      ref,
      initial,
    ) {
      return ConnectorEditController(initial);
    });

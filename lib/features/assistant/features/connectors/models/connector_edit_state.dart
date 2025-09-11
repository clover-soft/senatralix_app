import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';

/// Состояние редактора коннектора (новая структура)
class ConnectorEditState {
  ConnectorEditState({
    required this.name,
    required this.isActive,
    required this.greetingTexts,
    required this.greetingSelectionStrategy,
    required this.repromptTexts,
    required this.repromptSelectionStrategy,
    required this.allowBargeIn,
    required this.softTimeoutMs,
    required this.fillerTextList,
    required this.fillerSelectionStrategy,
    required this.dictor,
    required this.speed,
  });

  final String name;
  final bool isActive;
  final List<String> greetingTexts;
  final String greetingSelectionStrategy;
  final List<String> repromptTexts;
  final String repromptSelectionStrategy;
  final bool allowBargeIn;
  final int softTimeoutMs;
  final List<String> fillerTextList;
  final String fillerSelectionStrategy;
  final String dictor;
  final double speed;

  ConnectorEditState copy({
    String? name,
    bool? isActive,
    List<String>? greetingTexts,
    String? greetingSelectionStrategy,
    List<String>? repromptTexts,
    String? repromptSelectionStrategy,
    bool? allowBargeIn,
    int? softTimeoutMs,
    List<String>? fillerTextList,
    String? fillerSelectionStrategy,
    String? dictor,
    double? speed,
  }) => ConnectorEditState(
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        greetingTexts: greetingTexts ?? this.greetingTexts,
        greetingSelectionStrategy: greetingSelectionStrategy ?? this.greetingSelectionStrategy,
        repromptTexts: repromptTexts ?? this.repromptTexts,
        repromptSelectionStrategy: repromptSelectionStrategy ?? this.repromptSelectionStrategy,
        allowBargeIn: allowBargeIn ?? this.allowBargeIn,
        softTimeoutMs: softTimeoutMs ?? this.softTimeoutMs,
        fillerTextList: fillerTextList ?? this.fillerTextList,
        fillerSelectionStrategy: fillerSelectionStrategy ?? this.fillerSelectionStrategy,
        dictor: dictor ?? this.dictor,
        speed: speed ?? this.speed,
      );

  static ConnectorEditState fromConnector(Connector c) {
    final d = c.settings.dialog;
    final a = c.settings.assistant;
    return ConnectorEditState(
      name: c.name,
      isActive: c.isActive,
      greetingTexts: List<String>.from(d.greetingTexts),
      greetingSelectionStrategy: d.greetingSelectionStrategy,
      repromptTexts: List<String>.from(d.repromptTexts),
      repromptSelectionStrategy: d.repromptSelectionStrategy,
      allowBargeIn: d.allowBargeIn,
      softTimeoutMs: a.softTimeoutMs,
      fillerTextList: List<String>.from(a.fillerTextList),
      fillerSelectionStrategy: a.fillerSelectionStrategy,
      dictor: a.dictor,
      speed: a.speed,
    );
  }
}

import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';

/// Состояние редактора коннектора (упрощённый набор полей)
class ConnectorEditState {
  ConnectorEditState({
    required this.name,
    required this.isActive,
    required this.voice,
    required this.voiceSpeed,
    required this.greetingTexts,
    required this.repromptTexts,
    required this.allowBargeIn,
  });

  final String name;
  final bool isActive;
  final String voice;
  final double voiceSpeed;
  final String greetingTexts; // запятая-разделитель
  final String repromptTexts; // запятая-разделитель
  final bool allowBargeIn;

  ConnectorEditState copy({
    String? name,
    bool? isActive,
    String? voice,
    double? voiceSpeed,
    String? greetingTexts,
    String? repromptTexts,
    bool? allowBargeIn,
  }) => ConnectorEditState(
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        voice: voice ?? this.voice,
        voiceSpeed: voiceSpeed ?? this.voiceSpeed,
        greetingTexts: greetingTexts ?? this.greetingTexts,
        repromptTexts: repromptTexts ?? this.repromptTexts,
        allowBargeIn: allowBargeIn ?? this.allowBargeIn,
      );

  static ConnectorEditState fromConnector(Connector c) {
    final s = c.settings;
    final v = s.ttsVoicePool.isNotEmpty ? s.ttsVoicePool.first : const TtsVoice(voice: 'oksana', speed: 1.0);
    return ConnectorEditState(
      name: c.name,
      isActive: c.isActive,
      voice: v.voice,
      voiceSpeed: v.speed,
      greetingTexts: s.dialogGreetingTexts.join(', '),
      repromptTexts: s.dialogRepromptTexts.join(', '),
      allowBargeIn: s.dialogAllowBargeIn,
    );
  }
}

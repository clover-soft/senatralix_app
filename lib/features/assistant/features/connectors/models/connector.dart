import 'package:flutter/foundation.dart';

@immutable
class TtsVoice {
  final String voice; // идентификатор голоса
  final double speed; // 0.5..2.0

  const TtsVoice({
    required this.voice,
    required this.speed,
  });

  factory TtsVoice.fromJson(Map<String, dynamic> json) => TtsVoice(
        voice: json['voice'] as String? ?? 'default',
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
        'voice': voice,
        'speed': speed,
      };
}

@immutable
class LexiconRule {
  final String type; // regex
  final String pattern;
  final String replace;
  final bool enabled;
  final List<String> flags; // i,m,s,u...

  const LexiconRule({
    required this.type,
    required this.pattern,
    required this.replace,
    required this.enabled,
    required this.flags,
  });

  factory LexiconRule.fromJson(Map<String, dynamic> json) => LexiconRule(
        type: json['type'] as String? ?? 'regex',
        pattern: json['pattern'] as String? ?? '',
        replace: json['replace'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        flags: (json['flags'] as List?)?.map((e) => '$e').toList() ?? const <String>[],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'pattern': pattern,
        'replace': replace,
        'enabled': enabled,
        'flags': flags,
      };
}

@immutable
class ConnectorSettings {
  // Только для type=telephony на этом шаге
  final List<TtsVoice> ttsVoicePool;
  final List<LexiconRule> ttsLexicon;

  // Диалог (минимальный набор)
  final List<String> dialogGreetingTexts;
  final List<String> dialogRepromptTexts;
  final bool dialogAllowBargeIn;

  const ConnectorSettings({
    required this.ttsVoicePool,
    required this.ttsLexicon,
    required this.dialogGreetingTexts,
    required this.dialogRepromptTexts,
    required this.dialogAllowBargeIn,
  });

  factory ConnectorSettings.fromJson(Map<String, dynamic> json) => ConnectorSettings(
        ttsVoicePool: (json['tts']?['voice_pool'] as List?)
                ?.map((e) => TtsVoice.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const <TtsVoice>[],
        ttsLexicon: (json['tts']?['lexicon'] as List?)
                ?.map((e) => LexiconRule.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const <LexiconRule>[],
        dialogGreetingTexts:
            (json['dialog']?['greeting_texts'] as List?)?.map((e) => '$e').toList() ?? const <String>[],
        dialogRepromptTexts:
            (json['dialog']?['reprompt_texts'] as List?)?.map((e) => '$e').toList() ?? const <String>[],
        dialogAllowBargeIn: json['dialog']?['allow_barge_in'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'tts': {
          'voice_pool': ttsVoicePool.map((e) => e.toJson()).toList(),
          'lexicon': ttsLexicon.map((e) => e.toJson()).toList(),
        },
        'dialog': {
          'greeting_texts': dialogGreetingTexts,
          'reprompt_texts': dialogRepromptTexts,
          'allow_barge_in': dialogAllowBargeIn,
        },
      };
}

@immutable
class Connector {
  final String id; // UUID (строка)
  final String type; // telephony
  final String name;
  final bool isActive;
  final ConnectorSettings settings;

  const Connector({
    required this.id,
    required this.type,
    required this.name,
    required this.isActive,
    required this.settings,
  });

  Connector copyWith({
    String? id,
    String? type,
    String? name,
    bool? isActive,
    ConnectorSettings? settings,
  }) => Connector(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        settings: settings ?? this.settings,
      );

  factory Connector.fromJson(Map<String, dynamic> json) => Connector(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'telephony',
        name: json['name'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        settings: ConnectorSettings.fromJson(Map<String, dynamic>.from(json['settings'] as Map? ?? {})),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'is_active': isActive,
        'settings': settings.toJson(),
      };
}

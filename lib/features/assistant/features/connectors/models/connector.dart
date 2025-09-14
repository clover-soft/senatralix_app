import 'package:flutter/foundation.dart';

@immutable
class ConnectorDialogSettings {
  final List<String> greetingTexts;
  final String greetingSelectionStrategy; // first | round_robin | random
  final List<String> repromptTexts;
  final String repromptSelectionStrategy; // first | round_robin | random
  final bool allowBargeIn;
  final int maxTurns;
  final int noinputRetries;
  final bool hangupOnNoinput;
  final int maxCallDurationSec;
  final bool repeatPromptOnInterrupt;
  final int interruptMaxRetries;
  final String interruptFinalText;
  final String noinputFinalText;
  final String maxTurnsFinalText;
  final String maxCallDurationFinalText;

  const ConnectorDialogSettings({
    required this.greetingTexts,
    required this.greetingSelectionStrategy,
    required this.repromptTexts,
    required this.repromptSelectionStrategy,
    required this.allowBargeIn,
    required this.maxTurns,
    required this.noinputRetries,
    required this.hangupOnNoinput,
    required this.maxCallDurationSec,
    required this.repeatPromptOnInterrupt,
    required this.interruptMaxRetries,
    required this.interruptFinalText,
    required this.noinputFinalText,
    required this.maxTurnsFinalText,
    required this.maxCallDurationFinalText,
  });

  factory ConnectorDialogSettings.fromJson(Map<String, dynamic> json) =>
      ConnectorDialogSettings(
        greetingTexts:
            (json['greeting_texts'] as List?)?.map((e) => '$e').toList() ??
            const <String>[],
        greetingSelectionStrategy:
            json['greeting_selection_strategy'] as String? ?? 'first',
        repromptTexts:
            (json['reprompt_texts'] as List?)?.map((e) => '$e').toList() ??
            const <String>[],
        repromptSelectionStrategy:
            json['reprompt_selection_strategy'] as String? ?? 'round_robin',
        allowBargeIn: json['allow_barge_in'] as bool? ?? true,
        maxTurns: json['max_turns'] as int? ?? 20,
        noinputRetries: json['noinput_retries'] as int? ?? 3,
        hangupOnNoinput: json['hangup_on_noinput'] as bool? ?? false,
        maxCallDurationSec: json['max_call_duration_sec'] as int? ?? 1800,
        repeatPromptOnInterrupt:
            json['repeat_prompt_on_interrupt'] as bool? ?? true,
        interruptMaxRetries: json['interrupt_max_retries'] as int? ?? 0,
        interruptFinalText: json['interrupt_final_text'] as String? ?? '',
        noinputFinalText: json['noinput_final_text'] as String? ?? '',
        maxTurnsFinalText: json['max_turns_final_text'] as String? ?? '',
        maxCallDurationFinalText:
            json['max_call_duration_final_text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'greeting_texts': greetingTexts,
    'greeting_selection_strategy': greetingSelectionStrategy,
    'reprompt_texts': repromptTexts,
    'reprompt_selection_strategy': repromptSelectionStrategy,
    'allow_barge_in': allowBargeIn,
    'max_turns': maxTurns,
    'noinput_retries': noinputRetries,
    'hangup_on_noinput': hangupOnNoinput,
    'max_call_duration_sec': maxCallDurationSec,
    'repeat_prompt_on_interrupt': repeatPromptOnInterrupt,
    'interrupt_max_retries': interruptMaxRetries,
    'interrupt_final_text': interruptFinalText,
    'noinput_final_text': noinputFinalText,
    'max_turns_final_text': maxTurnsFinalText,
    'max_call_duration_final_text': maxCallDurationFinalText,
  };
}

@immutable
class ConnectorAssistantSettings {
  final List<String> fillerTextList;
  final String fillerSelectionStrategy; // first | round_robin | random
  final int softTimeoutMs;
  final String dictor; // идентификатор диктора/голоса
  final double speed; // скорость речи 0.5..2.0

  const ConnectorAssistantSettings({
    required this.fillerTextList,
    required this.fillerSelectionStrategy,
    required this.softTimeoutMs,
    required this.dictor,
    required this.speed,
  });

  factory ConnectorAssistantSettings.fromJson(Map<String, dynamic> json) =>
      ConnectorAssistantSettings(
        fillerTextList:
            (json['filler_text_list'] as List?)?.map((e) => '$e').toList() ??
            const <String>[],
        fillerSelectionStrategy:
            json['filler_selection_strategy'] as String? ?? 'round_robin',
        softTimeoutMs: json['soft_timeout_ms'] as int? ?? 2500,
        dictor: json['dictor'] as String? ?? 'oksana',
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
    'filler_text_list': fillerTextList,
    'filler_selection_strategy': fillerSelectionStrategy,
    'soft_timeout_ms': softTimeoutMs,
    'dictor': dictor,
    'speed': speed,
  };
}

@immutable
class ConnectorSettings {
  final ConnectorDialogSettings dialog;
  final ConnectorAssistantSettings assistant;
  final bool allowDelete; // разрешено ли удаление на бэкенде
  final bool allowUpdate; // разрешено ли обновление на бэкенде

  const ConnectorSettings({
    required this.dialog,
    required this.assistant,
    this.allowDelete = true,
    this.allowUpdate = true,
  });

  factory ConnectorSettings.fromJson(
    Map<String, dynamic> json,
  ) => ConnectorSettings(
    dialog: ConnectorDialogSettings.fromJson(
      Map<String, dynamic>.from(json['dialog'] as Map? ?? {}),
    ),
    // Бэкенд отдаёт dictor/speed на корневом уровне settings, а остальные поля ассистента — внутри 'assistant'
    assistant: ConnectorAssistantSettings.fromJson({
      ...Map<String, dynamic>.from(json['assistant'] as Map? ?? {}),
      if (json.containsKey('dictor')) 'dictor': json['dictor'],
      if (json.containsKey('speed')) 'speed': json['speed'],
    }),
    allowDelete: json['allow_delete'] as bool? ?? true,
    allowUpdate: json['allow_update'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'dialog': dialog.toJson(),
    // В assistant отправляем только поля, которые реально ожидает бэкенд внутри 'assistant'
    'assistant': {
      'filler_text_list': assistant.fillerTextList,
      'filler_selection_strategy': assistant.fillerSelectionStrategy,
      'soft_timeout_ms': assistant.softTimeoutMs,
    },
    // dictor и speed — на корневом уровне settings
    'dictor': assistant.dictor,
    'speed': assistant.speed,
    // allow_delete / allow_update — также на корневом уровне settings
    'allow_delete': allowDelete,
    'allow_update': allowUpdate,
  };
}

@immutable
class Connector {
  final String id; // UUID (строка)
  final String type; // telephony (пока опускается в JSON)
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
    settings: ConnectorSettings.fromJson(
      Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    'is_active': isActive,
    'settings': settings.toJson(),
  };
}

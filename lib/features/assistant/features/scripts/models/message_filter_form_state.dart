import 'package:flutter/foundation.dart';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';

/// Состояние подформы фильтра по сообщениям
@immutable
class MessageFilterFormState {
  final Set<MessageRole> roles;
  final MessageFilterType type;
  final String textOrPattern;
  final List<String> flags; // для regex

  const MessageFilterFormState({
    required this.roles,
    required this.type,
    required this.textOrPattern,
    required this.flags,
  });

  factory MessageFilterFormState.initial() => const MessageFilterFormState(
    roles: {MessageRole.user},
    type: MessageFilterType.icontains,
    textOrPattern: '',
    flags: ['i'],
  );

  MessageFilterFormState copyWith({
    Set<MessageRole>? roles,
    MessageFilterType? type,
    String? textOrPattern,
    List<String>? flags,
  }) => MessageFilterFormState(
    roles: roles ?? this.roles,
    type: type ?? this.type,
    textOrPattern: textOrPattern ?? this.textOrPattern,
    flags: flags ?? this.flags,
  );
}

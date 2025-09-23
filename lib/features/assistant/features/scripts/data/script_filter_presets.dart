// Пресеты фильтров команд и вспомогательные перечисления
import 'package:flutter/material.dart';

enum ScriptFilterPreset { startCall, endCall, message, custom }

extension ScriptFilterPresetTitle on ScriptFilterPreset {
  String get title {
    switch (this) {
      case ScriptFilterPreset.startCall:
        return 'Начало звонка';
      case ScriptFilterPreset.endCall:
        return 'Конец звонка';
      case ScriptFilterPreset.message:
        return 'Сообщение';
      case ScriptFilterPreset.custom:
        return 'Произвольный (ручной JSON)';
    }
  }
}

extension ScriptFilterPresetIcon on ScriptFilterPreset {
  IconData get icon {
    switch (this) {
      case ScriptFilterPreset.startCall:
        return Icons.call;
      case ScriptFilterPreset.endCall:
        return Icons.call_end;
      case ScriptFilterPreset.message:
        return Icons.message;
      case ScriptFilterPreset.custom:
        return Icons.code;
    }
  }
}

/// Тип фильтра текста сообщения
enum MessageFilterType { exact, contains, icontains, regex }

extension MessageFilterTypeTitle on MessageFilterType {
  String get title {
    switch (this) {
      case MessageFilterType.exact:
        return 'Полное соответствие';
      case MessageFilterType.contains:
        return 'Вхождение (регистрозависимо)';
      case MessageFilterType.icontains:
        return 'Вхождение (без регистра)';
      case MessageFilterType.regex:
        return 'Регулярное выражение';
    }
  }
}

/// Роли сообщений
enum MessageRole { user, assistant, system }

extension MessageRoleTitle on MessageRole {
  String get title {
    switch (this) {
      case MessageRole.user:
        return 'Пользователь';
      case MessageRole.assistant:
        return 'Ассистент';
      case MessageRole.system:
        return 'Система';
    }
  }
}

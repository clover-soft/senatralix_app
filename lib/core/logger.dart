import 'package:flutter/foundation.dart';

/// Простой логгер с возможностью отключения в релизе.
/// По умолчанию включён в Debug/Profile, отключён в Release.
class AppLogger {
  static bool enabled = !kReleaseMode;

  static String _fmt(String level, String tag, String message) {
    if (tag.isNotEmpty) {
      return '[$level][$tag] $message';
    }
    return '[$level] $message';
  }

  static void d(String message, {String tag = ''}) {
    if (!enabled) return;
    debugPrint(_fmt('D', tag, message));
  }

  static void i(String message, {String tag = ''}) {
    if (!enabled) return;
    debugPrint(_fmt('I', tag, message));
  }

  static void w(String message, {String tag = ''}) {
    if (!enabled) return;
    debugPrint(_fmt('W', tag, message));
  }

  static void e(String message, {String tag = ''}) {
    // Ошибки можно не отключать. Если хотите также отключать — снимите комментарий.
    // if (!enabled) return;
    debugPrint(_fmt('E', tag, message));
  }
}

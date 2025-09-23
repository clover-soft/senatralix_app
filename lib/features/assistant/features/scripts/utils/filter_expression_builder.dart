import 'dart:convert';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/message_filter_form_state.dart';

/// Построитель JSON-структуры фильтра. Возвращает Map для последующей сериализации в строку.
Map<String, dynamic> buildStartCallFilter() => {
  'all_of': [
    {'path': 'THREAD_EVENT_TYPE', 'op': 'eq', 'value': 'create'},
    {'path': 'THREAD_TYPE', 'op': 'eq', 'value': 'voip'},
  ],
};

Map<String, dynamic> buildEndCallFilter() => {
  'all_of': [
    {'path': 'THREAD_EVENT_TYPE', 'op': 'eq', 'value': 'close'},
    {'path': 'THREAD_TYPE', 'op': 'eq', 'value': 'voip'},
  ],
};

Map<String, dynamic> buildMessageFilter(MessageFilterFormState st) {
  final List<Map<String, dynamic>> conditions = [
    {'path': 'THREAD_EVENT_TYPE', 'op': 'eq', 'value': 'message'},
  ];

  // Роли
  if (st.roles.isNotEmpty) {
    if (st.roles.length == 1) {
      final role = st.roles.first.name; // 'user' | 'assistant' | 'system'
      conditions.add({'path': 'MESSAGE_ROLE', 'op': 'eq', 'value': role});
    } else {
      final list = st.roles.map((r) => r.name).toList();
      conditions.add({'path': 'MESSAGE_ROLE', 'op': 'in', 'value': list});
    }
  }

  // Текст/регэксп
  if (st.textOrPattern.trim().isNotEmpty) {
    switch (st.type) {
      case MessageFilterType.exact:
        conditions.add({
          'path': 'MESSAGE_TEXT',
          'op': 'eq',
          'value': st.textOrPattern,
        });
        break;
      case MessageFilterType.contains:
        conditions.add({
          'path': 'MESSAGE_TEXT',
          'op': 'contains',
          'value': st.textOrPattern,
        });
        break;
      case MessageFilterType.icontains:
        conditions.add({
          'path': 'MESSAGE_TEXT',
          'op': 'icontains',
          'value': st.textOrPattern,
        });
        break;
      case MessageFilterType.regex:
        conditions.add({
          'path': 'MESSAGE_TEXT',
          'op': 'regex',
          'value': st.textOrPattern,
          if (st.flags.isNotEmpty) 'flags': st.flags,
        });
        break;
    }
  }

  return {'all_of': conditions};
}

/// Удобная сериализация Map -> JSON-строки (красивый вывод по желанию)
String stringifyFilter(Map<String, dynamic> map, {bool pretty = false}) {
  if (!pretty) return jsonEncode(map);
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(map);
}

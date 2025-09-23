import 'dart:convert';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/message_filter_form_state.dart';

class ParsedFilter {
  final ScriptFilterPreset preset;
  final MessageFilterFormState? message;
  const ParsedFilter({required this.preset, this.message});
}

Map<String, dynamic>? _asJsonMap(dynamic input) {
  if (input == null) return null;
  if (input is String) {
    try {
      final v = jsonDecode(input);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
  if (input is Map) {
    return Map<String, dynamic>.from(input);
  }
  return null;
}

List<Map<String, dynamic>> _collectConditions(Map<String, dynamic> root) {
  final List<Map<String, dynamic>> conds = [];
  void walk(dynamic node) {
    if (node is Map) {
      if (node['path'] != null && node['op'] != null) {
        conds.add(Map<String, dynamic>.from(node));
      }
      for (final v in node.values) {
        if (v is List) {
          for (final e in v) {
            walk(e);
          }
        } else if (v is Map) {
          walk(v);
        }
      }
    }
  }

  if (root['all_of'] is List) {
    for (final e in (root['all_of'] as List)) {
      walk(e);
    }
  } else if (root['any_of'] is List) {
    for (final e in (root['any_of'] as List)) {
      walk(e);
    }
  } else {
    walk(root);
  }
  return conds;
}

bool _hasCondition(
  List<Map<String, dynamic>> conds,
  String path,
  String op,
  dynamic value,
) {
  return conds.any(
    (c) => (c['path'] == path && c['op'] == op && c['value'] == value),
  );
}

ParsedFilter parseFilterExpression(dynamic filterExpression) {
  final json = _asJsonMap(filterExpression);
  if (json == null) {
    return const ParsedFilter(preset: ScriptFilterPreset.custom);
  }

  final conds = _collectConditions(json);

  // Start call preset
  final isStart =
      _hasCondition(conds, 'THREAD_EVENT_TYPE', 'eq', 'create') &&
      _hasCondition(conds, 'THREAD_TYPE', 'eq', 'voip');
  if (isStart) return const ParsedFilter(preset: ScriptFilterPreset.startCall);

  // End call preset
  final isEnd =
      _hasCondition(conds, 'THREAD_EVENT_TYPE', 'eq', 'close') &&
      _hasCondition(conds, 'THREAD_TYPE', 'eq', 'voip');
  if (isEnd) return const ParsedFilter(preset: ScriptFilterPreset.endCall);

  // Message preset
  final isMessage = _hasCondition(conds, 'THREAD_EVENT_TYPE', 'eq', 'message');
  if (isMessage) {
    // roles
    final roles = <MessageRole>{};
    for (final c in conds) {
      if (c['path'] == 'MESSAGE_ROLE') {
        final op = (c['op'] ?? '').toString();
        if (op == 'eq') {
          final v = (c['value'] ?? '').toString();
          switch (v) {
            case 'user':
              roles.add(MessageRole.user);
              break;
            case 'assistant':
              roles.add(MessageRole.assistant);
              break;
            case 'system':
              roles.add(MessageRole.system);
              break;
          }
        } else if (op == 'in') {
          final val = c['value'];
          if (val is List) {
            for (final r in val) {
              final v = (r ?? '').toString();
              switch (v) {
                case 'user':
                  roles.add(MessageRole.user);
                  break;
                case 'assistant':
                  roles.add(MessageRole.assistant);
                  break;
                case 'system':
                  roles.add(MessageRole.system);
                  break;
              }
            }
          }
        }
      }
    }
    if (roles.isEmpty) roles.add(MessageRole.user);

    // text matching
    MessageFilterType type = MessageFilterType.icontains;
    String text = '';
    List<String> flags = const ['i'];
    for (final c in conds) {
      if (c['path'] == 'MESSAGE_TEXT') {
        final op = (c['op'] ?? '').toString();
        final val = c['value'];
        if (val is String) text = val;
        switch (op) {
          case 'eq':
            type = MessageFilterType.exact;
            break;
          case 'contains':
            type = MessageFilterType.contains;
            break;
          case 'icontains':
            type = MessageFilterType.icontains;
            break;
          case 'regex':
            type = MessageFilterType.regex;
            final fs = c['flags'];
            if (fs is List) {
              flags = fs.map((e) => e.toString()).toList();
            }
            break;
        }
      }
    }

    return ParsedFilter(
      preset: ScriptFilterPreset.message,
      message: MessageFilterFormState(
        roles: roles,
        type: type,
        textOrPattern: text,
        flags: flags,
      ),
    );
  }

  return const ParsedFilter(preset: ScriptFilterPreset.custom);
}

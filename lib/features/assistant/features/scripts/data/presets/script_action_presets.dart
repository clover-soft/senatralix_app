import 'script_action_preset.dart';
import 'create_message_preset.dart';
import 'http_request_preset.dart';
import 'normalize_phone_number_preset.dart';
import 'select_template_preset.dart';
import 'sleep_preset.dart';

/// Регистр всех доступных пресетов действий скрипта
const List<ScriptActionPreset> kScriptActionPresets = <ScriptActionPreset>[
  normalizePhoneNumberPreset,
  sleepPreset,
  httpRequestPreset,
  selectTemplatePreset,
  createMessagePreset,
];

/// Быстрый поиск пресета по имени действия
ScriptActionPreset? findScriptActionPreset(String? actionName) {
  if (actionName == null || actionName.isEmpty) return null;
  for (final preset in kScriptActionPresets) {
    if (preset.actionName == actionName) return preset;
  }
  return null;
}

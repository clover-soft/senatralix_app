import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';

/// Состояние редактора скрипта (для Riverpod контроллера)
class ScriptEditState {
  ScriptEditState({
    required this.name,
    required this.enabled,
    required this.trigger,
    required this.params,
    required this.steps,
  });

  final String name;
  final bool enabled;
  final ScriptTrigger trigger;
  final List<String> params; // только ключи параметров
  final List<ScriptStep> steps;

  ScriptEditState copy({
    String? name,
    bool? enabled,
    ScriptTrigger? trigger,
    List<String>? params,
    List<ScriptStep>? steps,
  }) => ScriptEditState(
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        trigger: trigger ?? this.trigger,
        params: params ?? this.params,
        steps: steps ?? this.steps,
      );
}

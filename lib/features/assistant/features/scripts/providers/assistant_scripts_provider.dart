import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_list_item.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_command_step.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
/// Загрузка списка скриптов (thread-commands) из бэкенда для ассистента
final assistantScriptsProvider = FutureProvider.family
    .autoDispose<List<ScriptListItem>, String>((ref, assistantId) async {
  // Дождемся базовой инициализации
  await ref.watch(assistantBootstrapProvider.future);

  final api = ref.read(assistantApiProvider);
  final resp = await api.fetchScriptCommands(assistantId: assistantId);
  final list = resp
      .map((e) => ScriptListItem.fromJson(e))
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  ref.read(scriptListProvider.notifier).replaceAll(assistantId, list);
  return list;
});

/// Загрузка шагов скрипта из бэкенда для ассистента
final scriptStepsProvider = FutureProvider.family
    .autoDispose<List<ScriptCommandStep>, int>((ref, commandId) async {
  final api = ref.read(assistantApiProvider);
  final resp = await api.fetchThreadCommandSteps(commandId: commandId);
  return resp
      .map((e) => ScriptCommandStep.fromJson(e))
      .toList()
    ..sort((a, b) => a.priority.compareTo(b.priority));
});

final scriptStepsReorderProvider = FutureProvider.family
    .autoDispose<void, ({int commandId, List<int> stepIds})>(
  (ref, payload) async {
    final api = ref.read(assistantApiProvider);
    await api.reorderThreadCommandSteps(
      commandId: payload.commandId,
      orderedStepIds: payload.stepIds,
    );
  },
);

final scriptStepDeleteProvider = FutureProvider.family
    .autoDispose<void, int>((ref, stepId) async {
  final api = ref.read(assistantApiProvider);
  await api.deleteThreadCommandStep(stepId);
});

final scriptStepActiveProvider = FutureProvider.family
    .autoDispose<void, ({int stepId, bool isActive})>((ref, payload) async {
  final api = ref.read(assistantApiProvider);
  await api.setThreadCommandStepActive(
    stepId: payload.stepId,
    isActive: payload.isActive,
  );
});

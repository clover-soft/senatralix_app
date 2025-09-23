import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_list_item.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Загрузка списка скриптов (thread-commands) из бэкенда для ассистента
final assistantScriptsProvider = FutureProvider.family<void, String>(
  (ref, assistantId) async {
    // Дождемся базовой инициализации
    await ref.watch(assistantBootstrapProvider.future);

    final api = ref.read(assistantApiProvider);
    final raw = await api.fetchScriptCommands(assistantId: assistantId);
    final items = raw.map((e) => ScriptListItem.fromJson(e)).toList();

    // Сохраняем в состояние для указанного ассистента
    ref.read(scriptListProvider.notifier).replaceAll(assistantId, items);
  },
);

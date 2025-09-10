import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/api_client_provider.dart';
import 'package:sentralix_app/features/assistant/api/assistant_api.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_tools_provider.dart';

/// DI: API клиента надфичи Assistant
final assistantApiProvider = Provider<AssistantApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AssistantApi(apiClient);
});

/// Разовая загрузка настроек и списка ассистентов при входе в надфичу
final assistantBootstrapProvider = FutureProvider<void>((ref) async {
  final api = ref.read(assistantApiProvider);

  // Параллельные запросы
  final settingsF = api.fetchFeatureSettings();
  final listF = api.fetchAssistants();

  final settings = await settingsF;
  final List<Assistant> assistants = await listF;

  // Сохранить в состояние
  ref.read(assistantFeatureSettingsProvider.notifier).set(settings);
  ref.read(assistantListProvider.notifier).replaceAll(assistants);

  // Прокинуть индивидуальные настройки ассистентов (если пришли)
  final settingsNotifier = ref.read(assistantSettingsProvider.notifier);
  final toolsNotifier = ref.read(assistantToolsProvider.notifier);
  for (final a in assistants) {
    if (a.settings != null) {
      settingsNotifier.save(a.id, a.settings!);
      // Синхронизация инструментов в отдельный провайдер для UI
      if (a.settings!.tools.isNotEmpty) {
        toolsNotifier.replaceAll(a.id, a.settings!.tools);
      }
    }
  }
});

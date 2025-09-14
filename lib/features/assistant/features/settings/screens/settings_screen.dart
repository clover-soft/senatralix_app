import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/settings/widgets/assistant_settings_form.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

class AssistantSettingsScreen extends ConsumerWidget {
  const AssistantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final boot = ref.watch(assistantBootstrapProvider);
    if (boot.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(assistantId: id, subfeatureTitle: 'Настройки'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (boot.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(assistantId: id, subfeatureTitle: 'Настройки'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки данных'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(assistantBootstrapProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AssistantAppBar(assistantId: id, subfeatureTitle: 'Настройки'),
      body: AssistantSettingsForm(assistantId: id),
    );
  }
}

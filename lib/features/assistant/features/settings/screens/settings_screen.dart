import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/settings/widgets/assistant_settings_form.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_fab.dart';
import 'package:sentralix_app/features/assistant/features/settings/providers/settings_edit_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';

class AssistantSettingsScreen extends ConsumerStatefulWidget {
  const AssistantSettingsScreen({super.key});

  @override
  ConsumerState<AssistantSettingsScreen> createState() =>
      _AssistantSettingsScreenState();
}

class _AssistantSettingsScreenState
    extends ConsumerState<AssistantSettingsScreen> {
  final GlobalKey<AssistantSettingsFormState> _formKey =
      GlobalKey<AssistantSettingsFormState>();

  @override
  Widget build(BuildContext context) {
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final boot = ref.watch(assistantBootstrapProvider);
    // Подготовим initial и подпишемся на состояние редактирования,
    // чтобы реактивно пересобирался FAB при изменениях формы
    final initial =
        ref.read(assistantSettingsProvider.notifier).getFor(id);
    // Подписка на провайдер нужна только для пересборки
    // (значение здесь не используется напрямую)
    final editState = ref.watch(settingsEditProvider(initial));
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
    // Подготовим tooltip и причину дизейбла FAB
    final name = (ref.watch(assistantListProvider).byId(id)?.name ?? '').trim();
    final reasons = <String>[];
    if (name.isEmpty) reasons.add('Введите имя ассистента');
    if (editState.maxTokens < 1) reasons.add('Max tokens >= 1');
    if (editState.instruction.trim().length < 10) {
      reasons.add('Инструкция минимум 10 символов');
    }
    if (editState.temperature < 0.0 || editState.temperature > 1.0) {
      reasons.add('Температура 0..1.0');
    }
    final bool fabEnabled = reasons.isEmpty && (_formKey.currentState?.canSave ?? true);
    final String fabTooltip = reasons.isEmpty
        ? 'Сохранить настройки'
        : 'Нельзя сохранить: ${reasons.join(' • ')}';

    return Scaffold(
      appBar: AssistantAppBar(assistantId: id, subfeatureTitle: 'Настройки'),
      floatingActionButton: AssistantActionFab(
        icon: Icons.save,
        tooltip: fabTooltip,
        onPressed: fabEnabled
            ? () => _formKey.currentState?.saveIfValid()
            : null,
      ),
      body: AssistantSettingsForm(key: _formKey, assistantId: id),
    );
  }
}

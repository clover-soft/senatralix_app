import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';
import 'package:sentralix_app/features/assistant/features/settings/providers/settings_edit_provider.dart';

/// Форма настроек ассистента (ConsumerWidget + локальный провайдер состояния)
class AssistantSettingsForm extends ConsumerWidget {
  const AssistantSettingsForm({super.key, required this.assistantId});

  final String assistantId;

  String? _validateMaxTokens(String? v) {
    if (v == null || v.trim().isEmpty) return 'Укажите maxTokens';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Введите целое число > 0';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = ref.read(assistantSettingsProvider.notifier).getFor(assistantId);
    final state = ref.watch(settingsEditProvider(initial));
    final ctrl = ref.read(settingsEditProvider(initial).notifier);

    final models = ['yandexgpt', 'gpt-4o-mini', 'llama3'];
    final isDirty = state.model != initial.model ||
        state.modelVersion != initial.modelVersion ||
        state.instruction != initial.instruction ||
        state.temperature != initial.temperature ||
        state.maxTokens != initial.maxTokens;

    final formKey = GlobalKey<FormState>();

    void onSave() {
      if (!formKey.currentState!.validate()) return;
      final data = ctrl.buildResult();
      ref.read(assistantSettingsProvider.notifier).save(assistantId, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }

    void onCancel() {
      // Сбросить провайдер к initial
      ref.invalidate(settingsEditProvider(initial));
    }

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Модель
          DropdownButtonFormField<String>(
            value: models.contains(state.model) ? state.model : models.first,
            items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) {
              if (val != null) ctrl.setModel(val);
            },
            decoration: const InputDecoration(labelText: 'Модель', helperText: 'Например: yandexgpt'),
          ),

          const SizedBox(height: 12),

          // Версия модели
          TextFormField(
            initialValue: state.modelVersion,
            decoration: const InputDecoration(labelText: 'Версия модели', helperText: 'Например: latest'),
            onChanged: ctrl.setModelVersion,
          ),

          const SizedBox(height: 12),

          // Инструкция (системный промпт)
          TextFormField(
            initialValue: state.instruction,
            decoration: const InputDecoration(
              labelText: 'Инструкция (system prompt)',
              helperText: 'Рекомендуется краткость; предупреждение при > 5000 символов',
            ),
            maxLines: 8,
            onChanged: ctrl.setInstruction,
          ),
          if (state.instruction.length > 5000)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Предупреждение: очень длинная инструкция (>5000 символов)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),

          const SizedBox(height: 16),

          // Температура
          Text('Температура: ${state.temperature.toStringAsFixed(1)}', style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: state.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: state.temperature.toStringAsFixed(1),
            onChanged: (v) => ctrl.setTemperature(double.parse(v.toStringAsFixed(1))),
          ),

          const SizedBox(height: 8),

          // Max tokens
          TextFormField(
            initialValue: state.maxTokens.toString(),
            decoration: const InputDecoration(labelText: 'Max tokens'),
            keyboardType: TextInputType.number,
            validator: _validateMaxTokens,
            onChanged: (v) {
              final n = int.tryParse(v.trim());
              if (n != null) ctrl.setMaxTokens(n);
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              FilledButton.icon(
                onPressed: !isDirty ? null : onSave,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: isDirty ? onCancel : null,
                icon: const Icon(Icons.undo),
                label: const Text('Отмена'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

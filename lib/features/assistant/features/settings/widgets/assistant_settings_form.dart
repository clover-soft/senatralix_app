import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';
import 'package:sentralix_app/features/assistant/features/settings/providers/settings_edit_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';

/// Форма настроек ассистента (ConsumerWidget + локальный провайдер состояния)
class AssistantSettingsForm extends ConsumerStatefulWidget {
  const AssistantSettingsForm({super.key, required this.assistantId});

  final String assistantId;

  @override
  ConsumerState<AssistantSettingsForm> createState() =>
      _AssistantSettingsFormState();
}

class _AssistantSettingsFormState extends ConsumerState<AssistantSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instructionCtrl;

  String? _validateMaxTokens(String? v) {
    if (v == null || v.trim().isEmpty) return 'Укажите maxTokens';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Введите целое число > 0';
    return null;
  }

  @override
  void initState() {
    super.initState();
    final initial = ref
        .read(assistantSettingsProvider.notifier)
        .getFor(widget.assistantId);
    _instructionCtrl = TextEditingController(text: initial.instruction);
  }

  @override
  void dispose() {
    _instructionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = ref
        .read(assistantSettingsProvider.notifier)
        .getFor(widget.assistantId);
    final state = ref.watch(settingsEditProvider(initial));
    final ctrl = ref.read(settingsEditProvider(initial).notifier);

    final allowedModels = ref
        .watch(assistantFeatureSettingsProvider)
        .settings
        .allowedModels;
    // Фолбэк: если список пуст, позволяем текущее значение
    final models = allowedModels.isNotEmpty ? allowedModels : [state.model];
    final isDirty =
        state.model != initial.model ||
        state.instruction != initial.instruction ||
        state.temperature != initial.temperature ||
        state.maxTokens != initial.maxTokens;

    void onSave() {
      if (!_formKey.currentState!.validate()) return;
      final data = ctrl.buildResult();
      ref
          .read(assistantSettingsProvider.notifier)
          .save(widget.assistantId, data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
    }

    void onCancel() {
      // Сбросить провайдер к initial
      ref.invalidate(settingsEditProvider(initial));
      _instructionCtrl.text = initial.instruction;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Модель
          DropdownButtonFormField<String>(
            value: models.contains(state.model) ? state.model : models.first,
            items: models
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              if (val != null) ctrl.setModel(val);
            },
            decoration: const InputDecoration(
              labelText: 'Модель',
              helperText: 'Выбор из разрешённых моделей',
            ),
          ),

          const SizedBox(height: 16),

          // Температура
          Text(
            'Температура: ${state.temperature.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: state.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: state.temperature.toStringAsFixed(1),
            onChanged: (v) =>
                ctrl.setTemperature(double.parse(v.toStringAsFixed(1))),
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

          const SizedBox(height: 16),

          // Инструкция (системный промпт)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 240),
            child: TextFormField(
              controller: _instructionCtrl,
              decoration: const InputDecoration(
                labelText: 'Инструкция (system prompt)',
                helperText:
                    'Рекомендуется краткость; предупреждение при > 5000 символов',
                alignLabelWithHint: true,
              ),
              maxLines: null,
              minLines: 10,
              onChanged: ctrl.setInstruction,
            ),
          ),
          if (state.instruction.length > 5000)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Предупреждение: очень длинная инструкция (>5000 символов)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
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

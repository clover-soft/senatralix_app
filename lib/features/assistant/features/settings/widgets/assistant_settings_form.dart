import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';

/// Форма настроек ассистента (инкапсулирует состояние и работу с провайдерами)
class AssistantSettingsForm extends ConsumerStatefulWidget {
  const AssistantSettingsForm({super.key, required this.assistantId});

  final String assistantId;

  @override
  ConsumerState<AssistantSettingsForm> createState() => _AssistantSettingsFormState();
}

class _AssistantSettingsFormState extends ConsumerState<AssistantSettingsForm> {
  final _formKey = GlobalKey<FormState>();

  late AssistantSettings _initial;

  // Контроллеры формы
  late TextEditingController _modelCtrl;
  late TextEditingController _modelVersionCtrl;
  late TextEditingController _instructionCtrl;
  double _temperature = 0.7;
  int _maxTokens = 512;

  bool _isSaving = false;

  // Пресеты моделей (моки)
  final List<String> _models = const ['yandexgpt', 'gpt-4o-mini', 'llama3'];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(assistantSettingsProvider.notifier).getFor(widget.assistantId);
    _initial = settings;
    _modelCtrl = TextEditingController(text: settings.model);
    _modelVersionCtrl = TextEditingController(text: settings.modelVersion);
    _instructionCtrl = TextEditingController(text: settings.instruction);
    _temperature = settings.temperature;
    _maxTokens = settings.maxTokens;
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _modelVersionCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _modelCtrl.text != _initial.model ||
        _modelVersionCtrl.text != _initial.modelVersion ||
        _instructionCtrl.text != _initial.instruction ||
        _temperature != _initial.temperature ||
        _maxTokens != _initial.maxTokens;
  }

  String? _validateMaxTokens(String? v) {
    if (v == null || v.trim().isEmpty) return 'Укажите maxTokens';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Введите целое число > 0';
    return null;
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final data = AssistantSettings(
      model: _modelCtrl.text.trim(),
      modelVersion: _modelVersionCtrl.text.trim(),
      instruction: _instructionCtrl.text,
      temperature: _temperature,
      maxTokens: _maxTokens,
    );
    ref.read(assistantSettingsProvider.notifier).save(widget.assistantId, data);
    setState(() {
      _initial = data;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  void _onCancel() {
    _modelCtrl.text = _initial.model;
    _modelVersionCtrl.text = _initial.modelVersion;
    _instructionCtrl.text = _initial.instruction;
    setState(() {
      _temperature = _initial.temperature;
      _maxTokens = _initial.maxTokens;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Модель
          DropdownButtonFormField<String>(
            value: _models.contains(_modelCtrl.text) ? _modelCtrl.text : _models.first,
            items: _models
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _modelCtrl.text = val);
            },
            decoration: const InputDecoration(labelText: 'Модель', helperText: 'Например: yandexgpt'),
          ),

          const SizedBox(height: 12),

          // Версия модели
          TextFormField(
            controller: _modelVersionCtrl,
            decoration: const InputDecoration(labelText: 'Версия модели', helperText: 'Например: latest'),
          ),

          const SizedBox(height: 12),

          // Инструкция (системный промпт)
          TextFormField(
            controller: _instructionCtrl,
            decoration: const InputDecoration(
              labelText: 'Инструкция (system prompt)',
              helperText: 'Рекомендуется краткость; предупреждение при > 5000 символов',
            ),
            maxLines: 8,
          ),
          if (_instructionCtrl.text.length > 5000)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Предупреждение: очень длинная инструкция (>5000 символов)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),

          const SizedBox(height: 16),

          // Температура
          Text('Температура: ${_temperature.toStringAsFixed(1)}', style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: _temperature.toStringAsFixed(1),
            onChanged: (v) => setState(() => _temperature = double.parse(v.toStringAsFixed(1))),
          ),

          const SizedBox(height: 8),

          // Max tokens
          TextFormField(
            initialValue: _maxTokens.toString(),
            decoration: const InputDecoration(labelText: 'Max tokens'),
            keyboardType: TextInputType.number,
            validator: _validateMaxTokens,
            onChanged: (v) {
              final n = int.tryParse(v.trim());
              if (n != null) setState(() => _maxTokens = n);
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              FilledButton.icon(
                onPressed: _isSaving || !_isDirty ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _isDirty ? _onCancel : null,
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

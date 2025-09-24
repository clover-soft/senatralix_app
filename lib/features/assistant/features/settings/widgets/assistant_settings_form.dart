import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_settings_provider.dart';
import 'package:sentralix_app/features/assistant/features/settings/providers/settings_edit_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';
import 'package:sentralix_app/features/assistant/models/assistant_settings.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:remixicon/remixicon.dart';

/// Форма настроек ассистента (ConsumerWidget + локальный провайдер состояния)
class AssistantSettingsForm extends ConsumerStatefulWidget {
  const AssistantSettingsForm({super.key, required this.assistantId});

  final String assistantId;

  @override
  ConsumerState<AssistantSettingsForm> createState() =>
      AssistantSettingsFormState();
}

class AssistantSettingsFormState extends ConsumerState<AssistantSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instructionCtrl;
  late AssistantSettings _initial;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  String? _validateMaxTokens(String? v) {
    if (v == null || v.trim().isEmpty) return 'Укажите maxTokens';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Введите целое число > 0';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initial = ref
        .read(assistantSettingsProvider.notifier)
        .getFor(widget.assistantId);
    _instructionCtrl = TextEditingController(text: _initial.instruction);
  }

  @override
  void dispose() {
    _instructionCtrl.dispose();
    super.dispose();
  }

  // Публичный геттер: есть ли несохранённые изменения
  bool get isDirty {
    final st = ref.read(settingsEditProvider(_initial));
    return st.model != _initial.model ||
        st.instruction != _initial.instruction ||
        st.temperature != _initial.temperature ||
        st.maxTokens != _initial.maxTokens;
  }

  /// Можно ли сохранять: имя не пустое, maxTokens >= 1, инструкция длиной >= 10, температура в [0..1.0]
  bool get canSave {
    final st = ref.read(settingsEditProvider(_initial));
    final name =
        (ref.read(assistantListProvider).byId(widget.assistantId)?.name ?? '')
            .trim();
    final instructionLen = st.instruction.trim().length;
    final validName = name.isNotEmpty;
    final validTokens = st.maxTokens >= 1;
    final validInstruction = instructionLen >= 10;
    final validTemp = st.temperature >= 0.0 && st.temperature <= 1.0;
    return validName && validTokens && validInstruction && validTemp;
  }

  // Публичный метод: сохранить, если форма валидна
  void saveIfValid() {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверьте обязательные поля')),
      );
      return;
    }
    final ctrl = ref.read(settingsEditProvider(_initial).notifier);
    final data = ctrl.buildResult();
    final api = ref.read(assistantApiProvider);
    final assistantsNotifier = ref.read(assistantListProvider.notifier);
    final settingsNotifier = ref.read(assistantSettingsProvider.notifier);
    () async {
      try {
        final updated = await api.updateAssistantCore(
          assistantId: widget.assistantId,
          name: ref.read(assistantListProvider).byId(widget.assistantId)?.name ?? '',
          description: ref.read(assistantListProvider).byId(widget.assistantId)?.description,
          settings: data,
        );
        // Обновим список ассистентов и настройки по ответу сервера
        assistantsNotifier.rename(updated.id, updated.name,
            description: updated.description);
        if (updated.settings != null) {
          settingsNotifier.save(updated.id, updated.settings!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Настройки сохранены')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сохранения: $e')),
          );
        }
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsEditProvider(_initial));
    final ctrl = ref.read(settingsEditProvider(_initial).notifier);

    final allowedModels = ref
        .watch(assistantFeatureSettingsProvider)
        .settings
        .allowedModels;
    // Фолбэк: если список пуст, позволяем текущее значение
    final models = allowedModels.isNotEmpty ? allowedModels : [state.model];

    return Form(
      key: _formKey,
      autovalidateMode: _autoValidateMode,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Шапка: редактирование имени ассистента и описания
          Builder(builder: (context) {
            final assistants = ref.watch(assistantListProvider).items;
            final idx = assistants.indexWhere((a) => a.id == widget.assistantId);
            final assistant = idx >= 0 ? assistants[idx] : null;
            final name = assistant?.name ?? '';
            final description = assistant?.description ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      RemixIcons.robot_2_line,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Имя ассистента',
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Введите имя';
                          if (t.length < 2) return 'Минимум 2 символа';
                          return null;
                        },
                        onChanged: (v) {
                          final t = v.trim();
                          if (assistant != null && t.isNotEmpty) {
                            ref
                                .read(assistantListProvider.notifier)
                                .rename(widget.assistantId, t,
                                    description: description);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Описание ассистента (до 280 символов)',
                  ),
                  onChanged: (v) {
                    final d = v.trim();
                    if (assistant != null) {
                      ref
                          .read(assistantListProvider.notifier)
                          .rename(widget.assistantId, assistant.name,
                              description: d);
                    }
                  },
                ),
              ],
            );
          }),

          // Модель
          DropdownButtonFormField<String>(
            initialValue:
                models.contains(state.model) ? state.model : models.first,
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
            value: state.temperature.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: state.temperature.toStringAsFixed(1),
            onChanged: (v) => ctrl.setTemperature(
              double.parse(v.toStringAsFixed(1)),
            ),
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
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 10) return 'Минимум 10 символов';
                return null;
              },
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
        ],
      ),
    );
  }
}

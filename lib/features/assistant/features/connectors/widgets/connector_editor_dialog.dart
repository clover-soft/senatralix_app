import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';

/// Диалог редактирования коннектора (type=telephony на этом шаге)
class ConnectorEditorDialog extends StatefulWidget {
  const ConnectorEditorDialog({super.key, required this.initial});

  final Connector initial;

  @override
  State<ConnectorEditorDialog> createState() => _ConnectorEditorDialogState();
}

class _ConnectorEditorDialogState extends State<ConnectorEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late bool _isActive;

  // Мини‑настройки (tts/asr/dialog) — упрощённые поля
  // Берём только первый голос из пула для простоты на шаге
  late TextEditingController _voice;
  double _voiceSpeed = 1.0;
  

  late TextEditingController _greetingTexts;
  late TextEditingController _repromptTexts;
  bool _allowBargeIn = true;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name = TextEditingController(text: c.name);
    _isActive = c.isActive;

    final settings = c.settings;
    final v = settings.ttsVoicePool.isNotEmpty
        ? settings.ttsVoicePool.first
        : const TtsVoice(voice: 'oksana', speed: 1.0);
    _voice = TextEditingController(text: v.voice);
    _voiceSpeed = v.speed;

    _greetingTexts = TextEditingController(text: settings.dialogGreetingTexts.join(', '));
    _repromptTexts = TextEditingController(text: settings.dialogRepromptTexts.join(', '));
    _allowBargeIn = settings.dialogAllowBargeIn;
  }

  @override
  void dispose() {
    _name.dispose();
    _voice.dispose();
    _greetingTexts.dispose();
    _repromptTexts.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final prev = widget.initial.settings;
    final updated = widget.initial.copyWith(
      name: _name.text.trim(),
      isActive: _isActive,
      settings: ConnectorSettings(
        ttsVoicePool: [
          TtsVoice(
            voice: _voice.text.trim(),
            speed: _voiceSpeed,
          ),
        ],
        ttsLexicon: prev.ttsLexicon,
        dialogGreetingTexts: _greetingTexts.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        dialogRepromptTexts: _repromptTexts.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        dialogAllowBargeIn: _allowBargeIn,
      ),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Коннектор (telephony)'),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Имя коннектора'),
                  validator: _req,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Включен'),
                ),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('TTS', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _voice,
                  decoration: const InputDecoration(labelText: 'voice'),
                  validator: _req,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('speed: ${_voiceSpeed.toStringAsFixed(1)}'),
                          Slider(
                            value: _voiceSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            onChanged: (v) => setState(() => _voiceSpeed = double.parse(v.toStringAsFixed(1))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Dialog', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _greetingTexts,
                  decoration: const InputDecoration(
                    labelText: 'greeting_texts (через запятую)'
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _repromptTexts,
                  decoration:
                      const InputDecoration(labelText: 'reprompt_texts (через запятую)'),
                ),
                SwitchListTile(
                  value: _allowBargeIn,
                  onChanged: (v) => setState(() => _allowBargeIn = v),
                  title: const Text('allow_barge_in'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _onSave, child: const Text('Сохранить')),
      ],
    );
  }
}

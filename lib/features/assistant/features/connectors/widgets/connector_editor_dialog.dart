import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/connector_edit_provider.dart';

/// Диалог редактирования коннектора (telephony)
class ConnectorEditorDialog extends ConsumerWidget {
  const ConnectorEditorDialog({super.key, required this.initial});
  final Connector initial;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  void _onSave(BuildContext context, WidgetRef ref) {
    final updated = ref.read(connectorEditProvider(initial).notifier).buildResult(initial);
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(connectorEditProvider(initial));
    final ctrl = ref.read(connectorEditProvider(initial).notifier);
    return AlertDialog(
      title: const Text('Коннектор (telephony)'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: st.name,
                decoration: const InputDecoration(labelText: 'Имя коннектора'),
                validator: _req,
                onChanged: ctrl.setName,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: st.isActive,
                onChanged: ctrl.setActive,
                title: const Text('Включен'),
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('TTS', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: st.voice,
                decoration: const InputDecoration(labelText: 'voice'),
                validator: _req,
                onChanged: ctrl.setVoice,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('speed: ${st.voiceSpeed.toStringAsFixed(1)}'),
                        Slider(
                          value: st.voiceSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: (v) => ctrl.setVoiceSpeed(double.parse(v.toStringAsFixed(1))),
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
                initialValue: st.greetingTexts,
                decoration: const InputDecoration(labelText: 'greeting_texts (через запятую)'),
                onChanged: ctrl.setGreetingTexts,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: st.repromptTexts,
                decoration: const InputDecoration(labelText: 'reprompt_texts (через запятую)'),
                onChanged: ctrl.setRepromptTexts,
              ),
              SwitchListTile(
                value: st.allowBargeIn,
                onChanged: ctrl.setAllowBargeIn,
                title: const Text('allow_barge_in'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: () => _onSave(context, ref), child: const Text('Сохранить')),
      ],
    );
  }
}

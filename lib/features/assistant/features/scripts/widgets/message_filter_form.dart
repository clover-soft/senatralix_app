import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/message_filter_form_state.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_command_edit_provider.dart';

class MessageFilterForm extends ConsumerWidget {
  final AutoDisposeStateNotifierProvider<
    MessageFilterFormController,
    MessageFilterFormState
  > provider;
  final VoidCallback onChanged;
  const MessageFilterForm({
    super.key,
    required this.provider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(provider);
    final ctrl = ref.read(provider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Роли сообщения', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          children: [
            FilterChip(
              label: const Text('Пользователь'),
              selected: st.roles.contains(MessageRole.user),
              onSelected: (v) {
                ctrl.toggleRole(MessageRole.user, v);
                onChanged();
              },
            ),
            FilterChip(
              label: const Text('Ассистент'),
              selected: st.roles.contains(MessageRole.assistant),
              onSelected: (v) {
                ctrl.toggleRole(MessageRole.assistant, v);
                onChanged();
              },
            ),
            FilterChip(
              label: const Text('Система'),
              selected: st.roles.contains(MessageRole.system),
              onSelected: (v) {
                ctrl.toggleRole(MessageRole.system, v);
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Тип фильтрации текста',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Полное соответствие'),
              selected: st.type == MessageFilterType.exact,
              onSelected: (v) {
                if (!v) return;
                ctrl.setType(MessageFilterType.exact);
                onChanged();
              },
            ),
            ChoiceChip(
              label: const Text('Вхождение'),
              selected: st.type == MessageFilterType.contains,
              onSelected: (v) {
                if (!v) return;
                ctrl.setType(MessageFilterType.contains);
                onChanged();
              },
            ),
            ChoiceChip(
              label: const Text('Вхождение (без регистра)'),
              selected: st.type == MessageFilterType.icontains,
              onSelected: (v) {
                if (!v) return;
                ctrl.setType(MessageFilterType.icontains);
                onChanged();
              },
            ),
            ChoiceChip(
              label: const Text('Регулярное выражение'),
              selected: st.type == MessageFilterType.regex,
              onSelected: (v) {
                if (!v) return;
                ctrl.setType(MessageFilterType.regex);
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: st.textOrPattern,
          decoration: InputDecoration(
            labelText: st.type == MessageFilterType.regex
                ? 'Регулярное выражение'
                : 'Текст для поиска',
            helperText: st.type == MessageFilterType.regex
                ? 'Пример: ^(привет|здравствуйте)\\b'
                : 'Укажите подстроку или точный текст',
          ),
          onChanged: (v) {
            ctrl.setText(v);
            onChanged();
          },
        ),
      ],
    );
  }
}


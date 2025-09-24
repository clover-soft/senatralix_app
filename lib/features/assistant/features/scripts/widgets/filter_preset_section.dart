import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_command_edit_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/utils/filter_expression_builder.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/message_filter_form.dart';
import 'dart:convert';
import 'package:code_text_field/code_text_field.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/param_block_card.dart';

/// Секция выбора пресета фильтра, подформы "Сообщение" и (опционально) поля raw JSON
class FilterPresetSection extends ConsumerWidget {
  final String familyKey;
  const FilterPresetSection({super.key, required this.familyKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(scriptPresetProvider(familyKey));
    final presetCtrl = ref.read(scriptPresetProvider(familyKey).notifier);
    final msgProv = messageFilterFormProvider(familyKey);
    final msgState = ref.watch(msgProv);
    final showRaw = ref.watch(showRawJsonProvider(familyKey));
    final rawError = ref.watch(rawJsonErrorProvider(familyKey));

    final ctrl = ref.read(scriptCommandEditProvider(familyKey).notifier);

    return ParamBlockCard(
      title: 'Запускать скрипт при наступлении события',
      showTitle: true,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Адаптивный ряд: на узком экране переносим чекбокс под комбо
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final presetDropdown = DropdownButtonFormField<ScriptFilterPreset>(
              initialValue: preset,
              decoration: const InputDecoration(labelText: 'Пресет фильтра'),
              items: ScriptFilterPreset.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(p.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(p.title),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (p) {
                if (p == null) return;
                presetCtrl.state = p;
                // Пересобрать filter_expression
                switch (p) {
                  case ScriptFilterPreset.startCall: {
                    final json = stringifyFilter(buildStartCallFilter());
                    ctrl.setFilter(json);
                    final c = ref.read(filterControllerProvider(familyKey));
                    c
                      ..text = json
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: json.length),
                      );
                    break;
                  }
                  case ScriptFilterPreset.endCall: {
                    final json = stringifyFilter(buildEndCallFilter());
                    ctrl.setFilter(json);
                    final c = ref.read(filterControllerProvider(familyKey));
                    c
                      ..text = json
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: json.length),
                      );
                    break;
                  }
                  case ScriptFilterPreset.message: {
                    final map = buildMessageFilter(msgState);
                    final json = stringifyFilter(map);
                    ctrl.setFilter(json);
                    final c = ref.read(filterControllerProvider(familyKey));
                    c
                      ..text = json
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: json.length),
                      );
                    break;
                  }
                  case ScriptFilterPreset.custom:
                    // не трогаем filter_expression — пользователь редактирует вручную
                    break;
                }
              },
            );

            final rawCheckbox = CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: preset == ScriptFilterPreset.custom ? true : showRaw,
              onChanged: preset == ScriptFilterPreset.custom
                  ? null
                  : (v) => ref
                      .read(showRawJsonProvider(familyKey).notifier)
                      .state = v ?? false,
              title: const Text('Показать raw JSON (filter_expression)'),
              controlAffinity: ListTileControlAffinity.leading,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  presetDropdown,
                  const SizedBox(height: 8),
                  rawCheckbox,
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(flex: 4, child: presetDropdown),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: rawCheckbox),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 12),

        // Подформа "Сообщение"
        if (preset == ScriptFilterPreset.message)
          MessageFilterForm(
            provider: msgProv,
            onChanged: () {
              final map = buildMessageFilter(ref.read(msgProv));
              final json = stringifyFilter(map);
              ctrl.setFilter(json);
              final c = ref.read(filterControllerProvider(familyKey));
              c
                ..text = json
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: json.length),
                );
            },
          ),
        if (preset == ScriptFilterPreset.message) const SizedBox(height: 12),

        // (чекбокс перенесён вверх, второй экземпляр удалён)
        if (preset == ScriptFilterPreset.custom || showRaw)
          const SizedBox(height: 8),

        // Поле raw JSON (только при showRaw)
        if (preset == ScriptFilterPreset.custom || showRaw)
          Builder(builder: (context) {
            final st = ref.watch(scriptCommandEditProvider(familyKey));
            final code = ref.watch(codeControllerProvider(familyKey));
            final focusNode = ref.watch(codeFocusNodeProvider(familyKey));
            // Синхронизация текста из состояния в редактор (только если реально отличается)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Не затираем ввод, если сейчас пользователь печатает в редакторе
              if (focusNode.hasFocus) return;
              if (code.text != st.filterExpression) {
                final baseOffset = st.filterExpression.length;
                code
                  ..text = st.filterExpression
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: baseOffset),
                  );
              }
            });

            final hasError = rawError != null && rawError.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasError ? Theme.of(context).colorScheme.error : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: CodeField(
                    controller: code,
                    focusNode: focusNode,
                    minLines: 2,
                    maxLines: 2,
                    enabled: preset == ScriptFilterPreset.custom,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                    onChanged: (v) {
                      if (preset != ScriptFilterPreset.custom) return;
                      // Валидация JSON
                      String? err;
                      try {
                        final decoded = jsonDecode(v);
                        if (decoded is! Map<String, dynamic>) {
                          err = 'Ожидается JSON-объект';
                        }
                      } catch (e) {
                        err = 'Ошибка JSON: $e';
                      }
                      ref.read(rawJsonErrorProvider(familyKey).notifier).state = err;
                      if (err != null) return;
                      // Сохранение (без авто-переключения пресета во время ручного ввода)
                      ctrl.setFilter(v);
                    },
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    rawError,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

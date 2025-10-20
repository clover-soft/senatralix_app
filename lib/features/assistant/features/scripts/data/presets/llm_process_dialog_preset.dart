import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия LLMProcessDialog
const llmProcessDialogPreset = ScriptActionPreset(
  actionName: 'LLMProcessDialog',
  title: 'Саммари диалога (LLM)',
  description:
      'Формирует краткую выжимку диалога для CRM с указанием намерения и ключевых деталей.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'model',
      label: 'Модель',
      type: ScriptActionFieldType.text,
      defaultValue: ScriptActionValue(literal: 'yandexgpt'),
    ),
    ScriptActionInputFieldSchema(
      key: 'max_tokens',
      label: 'Max tokens',
      type: ScriptActionFieldType.number,
      defaultValue: ScriptActionValue(literal: 350),
    ),
    ScriptActionInputFieldSchema(
      key: 'temperature',
      label: 'Temperature',
      type: ScriptActionFieldType.number,
      defaultValue: ScriptActionValue(literal: 0.3),
    ),
    ScriptActionInputFieldSchema(
      key: 'prompt',
      label: 'Промпт',
      type: ScriptActionFieldType.template,
      defaultValue: ScriptActionValue(
        literal:
            'Суммаризируй диалог кратко и по делу для CRM. Укажи суть намерения и ключевые детали.',
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'system_message',
      label: 'Системное сообщение',
      type: ScriptActionFieldType.template,
      defaultValue: ScriptActionValue(
        literal: 'Ты — ассистент отдела продаж. Формируй лаконичные конспекты.',
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'last_n_messages',
      label: 'Количество последних сообщений',
      type: ScriptActionFieldType.number,
      defaultValue: ScriptActionValue(literal: 50),
    ),
    ScriptActionInputFieldSchema(
      key: 'include_roles',
      label: 'Включать роли в контекст',
      type: ScriptActionFieldType.boolean,
      defaultValue: ScriptActionValue(literal: true),
    ),
    ScriptActionInputFieldSchema(
      key: 'wrap_dialog_as_user',
      label: 'Оборачивать диалог как от пользователя',
      type: ScriptActionFieldType.boolean,
      defaultValue: ScriptActionValue(literal: false),
    ),
  ],
  outputFields: <ScriptActionOutputFieldSchema>[
    ScriptActionOutputFieldSchema(
      key: 'to',
      label: 'Сохранить в слот',
      type: ScriptActionFieldType.text,
      defaultValue: 'DIALOG_SUMMARY',
    ),
  ],
  optionFields: <ScriptActionOptionFieldSchema>[
    ScriptActionOptionFieldSchema(
      key: 'on_error',
      label: 'Поведение при ошибке',
      type: ScriptActionFieldType.select,
      allowedValues: <String>['skip', 'fail'],
      defaultValue: 'skip',
    ),
  ],
);

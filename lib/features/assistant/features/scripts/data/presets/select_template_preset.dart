import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия SelectTemplate
const selectTemplatePreset = ScriptActionPreset(
  actionName: 'SelectTemplate',
  title: 'Формирование текстового шаблона',
  description:
      'Выбирает подходящий текстовый шаблон в зависимости от доступных переменных.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'templates',
      label: 'Список шаблонов',
      type: ScriptActionFieldType.list,
      description: 'Шаблоны и требуемые переменные для каждого из них.',
      required: true,
      defaultValue: ScriptActionValue(
        literal: <Map<String, dynamic>>[
          <String, dynamic>{
            'template': 'пользователя зовут {CRM_USER_NAME} {CRM_USER_SECOND_NAME}',
            'required': <String>['CRM_USER_NAME', 'CRM_USER_SECOND_NAME'],
          },
          <String, dynamic>{
            'template': 'пользователя зовут {CRM_USER_NAME}',
            'required': <String>['CRM_USER_NAME'],
          },
          <String, dynamic>{
            'template': 'имя пользователя неизвестно',
            'required': <String>[],
          },
        ],
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'missing_value',
      label: 'Значение по умолчанию',
      type: ScriptActionFieldType.text,
      defaultValue: ScriptActionValue(literal: ''),
    ),
  ],
  outputFields: <ScriptActionOutputFieldSchema>[
    ScriptActionOutputFieldSchema(
      key: 'to',
      label: 'Переменная результата',
      type: ScriptActionFieldType.text,
      defaultValue: 'TMP_USER_NAME_PHRASE',
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

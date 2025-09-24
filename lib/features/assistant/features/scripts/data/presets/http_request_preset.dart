import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия HttpRequest
const httpRequestPreset = ScriptActionPreset(
  actionName: 'HttpRequest',
  title: 'HTTP-запрос',
  description: 'Выполняет HTTP-запрос к внешнему сервису.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'method',
      label: 'Метод',
      type: ScriptActionFieldType.select,
      allowedValues: <String>['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      defaultValue: ScriptActionValue(literal: 'POST'),
    ),
    ScriptActionInputFieldSchema(
      key: 'url',
      label: 'URL',
      type: ScriptActionFieldType.text,
      required: true,
      defaultValue: ScriptActionValue(
        literal:
            'https://talatu.bitrix24.ru/rest/332/21vzu3i3q08rasml/crm.contact.list.json',
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'headers',
      label: 'Заголовки',
      type: ScriptActionFieldType.map,
      defaultValue: ScriptActionValue(
        literal: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'body_template',
      label: 'Шаблон тела',
      type: ScriptActionFieldType.template,
      defaultValue: ScriptActionValue(
        literal:
            '{\n  "filter": {"PHONE": "{NORMALIZED_PHONE}"},\n  "select": ["ID", "NAME", "LAST_NAME", "SECOND_NAME", "PHONE"]\n}',
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'timeout',
      label: 'Таймаут (сек)',
      type: ScriptActionFieldType.number,
      defaultValue: ScriptActionValue(literal: 2),
    ),
  ],
  outputFields: <ScriptActionOutputFieldSchema>[
    ScriptActionOutputFieldSchema(
      key: 'extract_jsonpath',
      label: 'JSONPath результата',
      type: ScriptActionFieldType.text,
      defaultValue: r'$.json.result[0]',
    ),
    ScriptActionOutputFieldSchema(
      key: 'map',
      label: 'Сопоставление полей',
      type: ScriptActionFieldType.map,
      defaultValue: <String, String>{
        'NAME': 'CRM_USER_NAME',
        'SECOND_NAME': 'CRM_USER_SECOND_NAME',
      },
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

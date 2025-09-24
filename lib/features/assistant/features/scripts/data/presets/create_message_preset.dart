import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия CreateMessage
const createMessagePreset = ScriptActionPreset(
  actionName: 'CreateMessage',
  title: 'Создание системного сообщения',
  description: 'Формирует сообщение для последующих шагов сценария.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'role',
      label: 'Роль',
      type: ScriptActionFieldType.select,
      allowedValues: <String>['system', 'user', 'assistant'],
      defaultValue: ScriptActionValue(literal: 'system'),
    ),
    ScriptActionInputFieldSchema(
      key: 'template',
      label: 'Шаблон сообщения',
      type: ScriptActionFieldType.template,
      description:
          'Используйте переменные в фигурных скобках для подстановки значений.',
      required: true,
      defaultValue: ScriptActionValue(
        literal: 'Это входящий звонок с номера {NORMALIZED_PHONE}, {TMP_USER_NAME_PHRASE}',
      ),
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

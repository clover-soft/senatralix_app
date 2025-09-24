import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия NormalizePhoneNumber
const normalizePhoneNumberPreset = ScriptActionPreset(
  actionName: 'NormalizePhoneNumber',
  title: 'Нормализация номера телефона',
  description:
      'Удаляет нечисловые символы и формирует номер в стандартизованном формате.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'phone',
      label: 'Номер телефона',
      type: ScriptActionFieldType.text,
      description: 'Исходный номер телефона. Можно взять из Caller ID.',
      required: true,
      defaultValue: ScriptActionValue(
        literal: null,
        from: 'THREAD_CALLERID_NUM',
        transform: 'strip',
      ),
    ),
  ],
  outputFields: <ScriptActionOutputFieldSchema>[
    ScriptActionOutputFieldSchema(
      key: 'to',
      label: 'Сохранить в переменную',
      type: ScriptActionFieldType.text,
      defaultValue: 'NORMALIZED_PHONE',
    ),
  ],
  optionFields: <ScriptActionOptionFieldSchema>[
    ScriptActionOptionFieldSchema(
      key: 'required_inputs',
      label: 'Обязательные входы',
      type: ScriptActionFieldType.list,
      defaultValue: <String>['phone'],
    ),
    ScriptActionOptionFieldSchema(
      key: 'on_error',
      label: 'Поведение при ошибке',
      type: ScriptActionFieldType.select,
      allowedValues: <String>['skip', 'fail'],
      defaultValue: 'skip',
    ),
  ],
);

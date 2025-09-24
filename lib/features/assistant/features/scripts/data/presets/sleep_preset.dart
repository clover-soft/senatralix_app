import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия Sleep
const sleepPreset = ScriptActionPreset(
  actionName: 'Sleep',
  title: 'Ожидание',
  description: 'Приостанавливает выполнение шага на заданное количество секунд.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'seconds',
      label: 'Секунды ожидания',
      type: ScriptActionFieldType.number,
      description: 'Длительность паузы в секундах.',
      required: true,
      defaultValue: ScriptActionValue(literal: '0.01'),
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

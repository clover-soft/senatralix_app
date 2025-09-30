import '../../models/script_action_config.dart';
import 'script_action_preset.dart';

/// Пресет действия GenerateSlotsSystemMessage
/// Формирует системное сообщение-инструкцию для генерации слотов.
const generateSlotsSystemMessagePreset = ScriptActionPreset(
  actionName: 'GenerateSlotsSystemMessage',
  title: 'Системное сообщение (слоты)',
  description:
      'Создаёт системное сообщение с инструкцией для слотов. Используйте этот шаг, чтобы подготовить подсказку для модели.',
  inputFields: <ScriptActionInputFieldSchema>[
    ScriptActionInputFieldSchema(
      key: 'instruction',
      label: 'Инструкция',
      type: ScriptActionFieldType.text,
      description:
          'Текст системной инструкции. Будет использован как есть (literal).',
      required: true,
      defaultValue: ScriptActionValue(
        literal:
            'Используй только эти слоты. Никогда не придумывай новые slot_id. Если слота нет в этом списке — он недоступен.',
      ),
    ),
    ScriptActionInputFieldSchema(
      key: 'pretty',
      label: 'Форматировать вывод (pretty)',
      type: ScriptActionFieldType.boolean,
      description: 'Включить красивое форматирование результата.',
      required: false,
      defaultValue: ScriptActionValue(literal: true),
    ),
  ],
);

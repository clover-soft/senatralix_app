import 'package:flutter/foundation.dart';

/// Пресет Function-tool для ассистента.
@immutable
class ToolPreset {
  const ToolPreset({
    required this.key,
    required this.title,
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String key;
  final String title;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
}

/// Список доступных пресетов инструментов.
const List<ToolPreset> kToolPresets = [
  ToolPreset(
    key: 'transferCall',
    title: 'Перевод звонка',
    name: 'transferCall',
    description:
        'Переводит текущий звонок на указанного сотрудника и произносит прощальную фразу.',
    parameters: {
      'type': 'object',
      'properties': {
        'employee_extension': {
          'type': 'string',
          'description':
              'Внутренний номер сотрудника компании, на который нужно перевести звонок',
        },
        'farewell_phrase': {
          'type': 'string',
          'description':
              'Фраза, которую необходимо произнести абоненту перед переводом звонка',
        },
      },
      'required': ['employee_extension', 'farewell_phrase'],
    },
  ),
  ToolPreset(
    key: 'hangupCall',
    title: 'Завершение звонка',
    name: 'hangupCall',
    description:
        'Инструмент для прощания с абонентом и завершения звонка голосом ассистента.',
    parameters: {
      'type': 'object',
      'properties': {
        'farewell_phrase': {
          'type': 'string',
          'description':
              'Фраза прощания (на естественном русском языке), произносимая перед завершением звонка.',
        },
      },
      'required': ['farewell_phrase'],
    },
  ),
  ToolPreset(
    key: 'new',
    title: 'Пустой Function',
    name: 'newFunction',
    description: 'Заготовка для создания нового function-tool с пустой схемой.',
    parameters: {
      'type': 'object',
      'properties': <String, dynamic>{},
      'required': <String>[],
    },
  ),
];

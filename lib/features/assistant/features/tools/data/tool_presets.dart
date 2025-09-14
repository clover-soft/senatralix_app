// Пресеты Function-tools для ассистента.
// Хранятся отдельно от UI, чтобы экран оставался "тонким".

const Map<String, Map<String, dynamic>> kFunctionToolPresets = {
  'transferCall': {
    'function': {
      'name': 'transferCall',
      'description':
          'Переводит текущий звонок на указанного сотрудника и произносит прощальную фразу',
      'parameters': {
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
    },
  },
  'hangupCall': {
    'function': {
      'name': 'hangupCall',
      'description': 'Инструмент для завершения звонка',
      'parameters': {
        'type': 'object',
        'properties': {
          'farewell_phrase': {
            'type': 'string',
            'description': 'Фраза прощания (на естественном русском языке)',
          },
        },
        'required': ['farewell_phrase'],
      },
    },
  },
  'new': {
    'function': {
      'name': 'newFunction',
      'description': 'Описание',
      'parameters': {'type': 'object', 'properties': {}, 'required': []},
    },
  },
};

Map<String, dynamic>? getFunctionToolPreset(String key) {
  final raw = kFunctionToolPresets[key];
  if (raw == null) return null;
  // Глубокая копия не требуется на данном шаге — структура иммутабельна.
  return raw;
}

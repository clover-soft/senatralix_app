final Map<String, Map<String, dynamic>> kScriptPresets = {
  'empty_start': {
    'id': '',
    'name': 'Новый скрипт (start)',
    'enabled': true,
    'trigger': 'on_dialog_start',
    'params': {},
    'steps': [],
  },
  'empty_end': {
    'id': '',
    'name': 'Новый скрипт (end)',
    'enabled': true,
    'trigger': 'on_dialog_end',
    'params': {},
    'steps': [],
  },
  'start_get_warmup': {
    'id': '',
    'name': 'Старт: GET /warmup',
    'enabled': true,
    'trigger': 'on_dialog_start',
    'params': {},
    'steps': [
      {
        'id': 'step1',
        'title': 'GET /warmup',
        'spec':
            '{"when": {"jsonpath": "\$.dialog.state"}, "action": {"type": "http_get", "http": {"url": "https://api.example.com/warmup", "headers": {}, "query": {}}}}',
      },
    ],
  },
  'end_post_summary': {
    'id': '',
    'name': 'Завершение: POST /summary',
    'enabled': true,
    'trigger': 'on_dialog_end',
    'params': {},
    'steps': [
      {
        'id': 'step1',
        'title': 'POST /summary',
        'spec':
            '{"when": {"jsonpath": "\$.dialog.summary"}, "action": {"type": "http_post", "http": {"url": "https://api.example.com/summary", "headers": {"Content-Type": "application/json"}, "body_template": "\${dialog.summary}"}}}',
      },
    ],
  },
};

Map<String, dynamic>? getScriptPreset(String key) => kScriptPresets[key];

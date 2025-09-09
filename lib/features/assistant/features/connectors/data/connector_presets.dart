/// Пресеты коннекторов. Пока поддерживается только тип "telephony".
/// Держим отдельно от UI, чтобы экран оставался "тонким".
library connector_presets;

const Map<String, Map<String, dynamic>> kConnectorPresets = {
  'telephony': {
    'id': '',
    'type': 'telephony',
    'name': 'Новый телеком‑коннектор',
    'is_active': true,
    'domain_id': 'default',
    'settings': {
      'tts': {
        'voice_pool': [
          {
            'voice': 'oksana',
            'language': 'ru-RU',
            'vendor': 'yandex',
            'role': 'default',
            'speed': 1.0
          }
        ],
        'voice_selection_strategy': 'first',
        'cache_enable': true,
        'lexicon': []
      },
      'asr': {
        'language': 'ru-RU',
        'model': 'default'
      },
      'dialog': {
        'greeting_texts': ['Здравствуйте! Чем могу помочь?'],
        'greeting_selection_strategy': 'first',
        'reprompt_texts': ['Вы на линии?'],
        'reprompt_selection_strategy': 'first',
        'allow_barge_in': true
      }
    }
  },
};

Map<String, dynamic>? getConnectorPreset(String key) => kConnectorPresets[key];

import 'package:flutter/foundation.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/selection_options.dart';

@immutable
class DictorBase {
  final String code; // например, 'alena'
  final String display; // например, 'Алёна'
  final String gender; // 'M' | 'F'
  final List<String> styles; // e.g. ['neutral','good']
  const DictorBase({
    required this.code,
    required this.display,
    required this.gender,
    required this.styles,
  });
}

class DictorStyleLabels {
  static const Map<String, String> base = {
    'neutral': 'нейтральный',
    'good': 'радостный',
    'evil': 'раздражённый',
    'strict': 'строгий',
    'friendly': 'дружелюбный',
    'whisper': 'шёпот',
  };

  static String label(String style, String gender) {
    // Для женского рода меняем окончания некоторых прилагательных
    if (gender == 'F') {
      switch (style) {
        case 'neutral':
          return 'нейтральная';
        case 'good':
          return 'радостная';
        case 'evil':
          return 'раздражённая';
        case 'strict':
          return 'строгая';
        case 'friendly':
          return 'дружелюбная';
        case 'whisper':
          return 'шёпот';
      }
    } else {
      switch (style) {
        case 'neutral':
          return 'нейтральный';
        case 'good':
          return 'радостный';
        case 'evil':
          return 'раздражённый';
        case 'strict':
          return 'строгий';
        case 'friendly':
          return 'дружелюбный';
        case 'whisper':
          return 'шёпот';
      }
    }
    return base[style] ?? style;
  }
}

class DictorOptions {
  // База дикторов ru-RU из вашего списка
  static const List<DictorBase> _ru = [
    DictorBase(
      code: 'alena',
      display: 'Алёна',
      gender: 'F',
      styles: ['neutral', 'good'],
    ),
    DictorBase(
      code: 'filipp',
      display: 'Филипп',
      gender: 'M',
      styles: ['neutral'],
    ),
    DictorBase(
      code: 'ermil',
      display: 'Ермил',
      gender: 'M',
      styles: ['neutral', 'good'],
    ),
    DictorBase(
      code: 'jane',
      display: 'Джейн',
      gender: 'F',
      styles: ['neutral', 'good', 'evil'],
    ),
    DictorBase(
      code: 'omazh',
      display: 'Омаж',
      gender: 'F',
      styles: ['neutral', 'evil'],
    ),
    DictorBase(
      code: 'zahar',
      display: 'Захар',
      gender: 'M',
      styles: ['neutral', 'good'],
    ),
    DictorBase(
      code: 'dasha',
      display: 'Даша',
      gender: 'F',
      styles: ['neutral', 'good', 'friendly'],
    ),
    DictorBase(
      code: 'julia',
      display: 'Юлия',
      gender: 'F',
      styles: ['neutral', 'strict'],
    ),
    DictorBase(
      code: 'lera',
      display: 'Лера',
      gender: 'F',
      styles: ['neutral', 'friendly'],
    ),
    DictorBase(
      code: 'masha',
      display: 'Маша',
      gender: 'F',
      styles: ['good', 'strict', 'friendly'],
    ),
    DictorBase(
      code: 'marina',
      display: 'Марина',
      gender: 'F',
      styles: ['neutral', 'whisper', 'friendly'],
    ),
    DictorBase(
      code: 'alexander',
      display: 'Александр',
      gender: 'M',
      styles: ['neutral', 'good'],
    ),
    DictorBase(
      code: 'kirill',
      display: 'Кирилл',
      gender: 'M',
      styles: ['neutral', 'strict', 'good'],
    ),
    DictorBase(
      code: 'anton',
      display: 'Антон',
      gender: 'M',
      styles: ['neutral', 'good'],
    ),
    DictorBase(
      code: 'madi_ru',
      display: 'Мади',
      gender: 'M',
      styles: ['neutral'],
    ),
    DictorBase(
      code: 'saule_ru',
      display: 'Сауле',
      gender: 'F',
      styles: ['neutral', 'strict', 'whisper'],
    ),
    DictorBase(
      code: 'zamira_ru',
      display: 'Замира',
      gender: 'F',
      styles: ['neutral', 'strict', 'friendly'],
    ),
    DictorBase(
      code: 'zhanar_ru',
      display: 'Жанар',
      gender: 'F',
      styles: ['neutral', 'strict', 'friendly'],
    ),
    DictorBase(
      code: 'yulduz_ru',
      display: 'Юлдуз',
      gender: 'F',
      styles: ['neutral', 'strict', 'friendly', 'whisper'],
    ),
  ];

  /// Полный список опций со стилями в формате value = `${code}_${style}`
  static List<SelectorOption> ruOptions() {
    final List<SelectorOption> out = [];
    for (final d in _ru) {
      for (final s in d.styles) {
        final value = '${d.code}_$s';
        final label = '${d.display} (${DictorStyleLabels.label(s, d.gender)})';
        out.add(SelectorOption(value: value, label: label));
      }
    }
    return out;
  }

  /// Найти первую опцию по базовому коду диктора (например, alena -> alena_neutral),
  /// либо вернуть null, если такого диктора нет.
  static SelectorOption? firstByCode(String code) {
    try {
      final d = _ru.firstWhere((e) => e.code == code);
      final s = d.styles.isNotEmpty ? d.styles.first : 'neutral';
      return SelectorOption(
        value: '${d.code}_$s',
        label: '${d.display} (${DictorStyleLabels.label(s, d.gender)})',
      );
    } catch (_) {
      return null;
    }
  }
}

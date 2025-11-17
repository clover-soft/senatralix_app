import 'package:flutter/foundation.dart';

/// Универсальная модель опции селектора: хранит техническое значение и человеко-читаемую метку.
@immutable
class SelectorOption {
  final String value;
  final String label;
  const SelectorOption({required this.value, required this.label});
}

/// Наборы опций для стратегий выбора фраз (greeting/reprompt/filler)
class SelectionStrategyOptions {
  static const first = SelectorOption(value: 'first', label: 'Первый');
  static const roundRobin = SelectorOption(
    value: 'round_robin',
    label: 'По кругу',
  );
  static const random = SelectorOption(value: 'random', label: 'Случайно');
  static const llm = SelectorOption(value: 'llm', label: 'LLM (модель)');

  /// Универсальный список стратегий выбора
  static const List<SelectorOption> common = <SelectorOption>[
    first,
    roundRobin,
    random,
  ];

  /// Стратегии выбора для филлеров (включает режим LLM)
  static const List<SelectorOption> filler = <SelectorOption>[
    first,
    roundRobin,
    random,
    llm,
  ];
}

/// Хелперы для конвертации произвольных строковых списков в опции
class SelectorOptionUtils {
  /// Формирует опции на основе значений. По умолчанию метка совпадает со значением.
  static List<SelectorOption> fromValues(
    List<String> values, {
    Map<String, String>? labels,
  }) {
    return values
        .where((e) => e.trim().isNotEmpty)
        .map((v) => SelectorOption(value: v, label: labels?[v] ?? v))
        .toList(growable: false);
  }
}

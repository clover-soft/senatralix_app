import 'package:flutter/foundation.dart';

/// Информация о типе слота для комбобоксов и подсказок
@immutable
class SlotTypeInfo {
  final String key; // машинное имя: string, enum, repeatable, ...
  final String label; // человекочитаемое имя
  final String description; // краткое описание правил валидации

  const SlotTypeInfo({required this.key, required this.label, required this.description});
}

/// Поддерживаемые типы слотов и их описания (синхронизировано с бэкендом)
/// См. правила валидации в UpdateSlotTool._validate_value() на бэкенде.
const List<SlotTypeInfo> kSupportedSlotTypes = [
  SlotTypeInfo(
    key: 'string',
    label: 'Строка',
    description:
        'Произвольная строка. Доп. валидация длины через metadata.min_len / metadata.max_len (если заданы).',
  ),
  SlotTypeInfo(
    key: 'enum',
    label: 'Перечень',
    description: 'Значение должно входить в options слота.',
  ),
  SlotTypeInfo(
    key: 'repeatable',
    label: 'Список',
    description: 'Ожидается список (list).',
  ),
  SlotTypeInfo(
    key: 'digit',
    label: 'Целое (digit)',
    description: 'Должно приводиться к целому числу (int).',
  ),
  SlotTypeInfo(
    key: 'integer',
    label: 'Целое (integer)',
    description: 'Должно приводиться к целому числу (int).',
  ),
  SlotTypeInfo(
    key: 'number',
    label: 'Число (float)',
    description: 'Должно приводиться к числу с плавающей точкой (float).',
  ),
  SlotTypeInfo(
    key: 'boolean',
    label: 'Булево',
    description:
        'Булево значение. Допускаются строковые/числовые эквиваленты: "true"|"false"|"1"|"0"|"yes"|"no", 0|1.',
  ),
  SlotTypeInfo(
    key: 'email',
    label: 'E-mail',
    description: 'Проверка по регулярному выражению EMAIL_RE.',
  ),
  SlotTypeInfo(
    key: 'phone',
    label: 'Телефон',
    description: 'Проверка по регулярному выражению PHONE_RE (простая маска).',
  ),
  SlotTypeInfo(
    key: 'date',
    label: 'Дата',
    description:
        'ISO-дата YYYY-MM-DD. Доп. правило: metadata.allow_past (по умолчанию True).',
  ),
  SlotTypeInfo(
    key: 'datetime',
    label: 'Дата/время',
    description: 'ISO-дата-время (datetime.fromisoformat(...)).',
  ),
  SlotTypeInfo(
    key: 'json',
    label: 'JSON',
    description: 'Любое JSON-сериализуемое значение.',
  ),
];

/// Быстрый доступ к описанию по ключу типа
final Map<String, String> kSlotTypeDescriptions = {
  for (final t in kSupportedSlotTypes) t.key: t.description,
};

/// Список ключей типов для валидации/селектов
final List<String> kSlotTypeKeys = [
  for (final t in kSupportedSlotTypes) t.key,
];

/// Соответствие ключа типа и русского лейбла для отображения в UI
final Map<String, String> kSlotTypeLabels = {
  for (final t in kSupportedSlotTypes) t.key: t.label,
};

/// Скрытые в UI типы (временное ограничение)
const Set<String> kHiddenSlotTypeKeys = {'repeatable'};

/// Список типов, доступных для выбора пользователем (без скрытых)
final List<SlotTypeInfo> kSelectableSlotTypes = [
  for (final t in kSupportedSlotTypes)
    if (!kHiddenSlotTypeKeys.contains(t.key)) t,
];

/// Проверка: тип доступен к выбору?
bool isSlotTypeSelectable(String key) => !kHiddenSlotTypeKeys.contains(key);

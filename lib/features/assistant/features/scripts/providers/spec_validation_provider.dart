import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Локальная валидация JSON spec для шага скрипта
/// Ключом используем stepId (для нового шага можно передать 'new')
final specErrorProvider = StateProvider.autoDispose.family<String?, String>((ref, stepId) {
  return null;
});

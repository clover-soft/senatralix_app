import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер выбранного скрипта на экране (по assistantId)
final selectedScriptIdProvider = StateProvider.autoDispose
    .family<String?, String>((ref, assistantId) {
      return null; // по умолчанию ничего не выбрано
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Возвращает множество external_id коннекторов, подключенных к ассистенту
final assistantAttachedConnectorsProvider =
    FutureProvider.family<Set<String>, String>((ref, assistantId) async {
  // Дождёмся bootstrap (токен/куки и т.п.)
  await ref.watch(assistantBootstrapProvider.future);
  final api = ref.read(assistantApiProvider);
  final set = await api.fetchAssistantAttachedConnectors(assistantId);
  return set;
});

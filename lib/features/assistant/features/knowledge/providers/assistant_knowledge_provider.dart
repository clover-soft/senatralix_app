import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Загрузка списка баз знаний из бэкенда и помещение в состояние текущего ассистента
final assistantKnowledgeProvider = FutureProvider.family<void, String>((
  ref,
  assistantId,
) async {
  // Убедимся, что базовый bootstrap прошёл
  await ref.watch(assistantBootstrapProvider.future);

  final api = ref.read(assistantApiProvider);
  final List<KnowledgeBaseItem> items = await api.fetchKnowledgeList();

  // Положим элементы для указанного ассистента
  ref.read(knowledgeProvider.notifier).replaceAll(assistantId, items);
});

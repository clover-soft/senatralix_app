import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/thread_item.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/sessions_filter_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Провайдер списка тредов с учётом фильтра и assistantId
final sessionsThreadsProvider = FutureProvider.family<List<ThreadItem>, String>(
  (ref, assistantId) async {
    // Подпишемся на фильтр, чтобы обновлять список при изменениях
    final filter = ref.watch(sessionsFilterProvider);
    final api = ref.read(assistantApiProvider);

    final list = await api.fetchAssistantThreads(
      assistantId: assistantId,
      limit: filter.limit,
      offset: 0,
      createdFrom: filter.createdFrom,
      createdTo: filter.createdTo,
    );
    return list.map((e) => ThreadItem.fromJson(e)).toList();
  },
);

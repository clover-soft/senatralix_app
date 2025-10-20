import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/timeline_entry.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Загрузка таймлайна по internalId треда
final timelineProvider = FutureProvider.family<List<TimelineEntry>, String>(
  (ref, internalId) async {
    final api = ref.read(assistantApiProvider);
    final raw = await api.fetchThreadTimeline(internalId);
    return TimelineEntry.fromTimelineJson(raw);
  },
);

/// Вычисление простого саммари из последнего ThreadSlots (context)
final timelineSummaryContextProvider = Provider.family<Map<String, dynamic>, String>(
  (ref, internalId) {
    final async = ref.watch(timelineProvider(internalId));
    return async.maybeWhen(
      data: (list) {
        for (int i = list.length - 1; i >= 0; i--) {
          final e = list[i];
          if (e.type == TimelineEntryType.threadSlots) {
            final ts = e.data as ThreadSlotsEntry;
            return ts.context;
          }
        }
        return const <String, dynamic>{};
      },
      orElse: () => const <String, dynamic>{},
    );
  },
);

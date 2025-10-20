import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/timeline_entry.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

// Оффсет для корректировки таймингов первого события
const Duration kTimelineFirstEventOffset = Duration(seconds: 4);

/// Загрузка таймлайна по internalId треда
final timelineProvider = FutureProvider.family<List<TimelineEntry>, String>(
  (ref, internalId) async {
    final api = ref.read(assistantApiProvider);
    final raw = await api.fetchThreadTimeline(internalId);
    final list = TimelineEntry.fromTimelineJson(raw);

    if (list.isEmpty) return list;

    // Сдвигаем первое событие на константный оффсет, чтобы синхронизировать голос/текст
    final first = list.first;
    final shifted = () {
      switch (first.type) {
        case TimelineEntryType.assistantMessage:
          final d = first.data as AssistantMessageEntry;
          final nd = AssistantMessageEntry(
            id: d.id,
            threadId: d.threadId,
            role: d.role,
            content: d.content,
            payload: d.payload,
            tokens: d.tokens,
            status: d.status,
            createdAt: d.createdAt.add(kTimelineFirstEventOffset),
          );
          return TimelineEntry(type: first.type, data: nd, sortTime: nd.createdAt);
        case TimelineEntryType.toolCallLog:
          final d = first.data as ToolCallLogEntry;
          final nd = ToolCallLogEntry(
            id: d.id,
            toolName: d.toolName,
            assistantId: d.assistantId,
            threadId: d.threadId,
            domainId: d.domainId,
            startedAt: d.startedAt.add(kTimelineFirstEventOffset),
            finishedAt: d.finishedAt,
            durationMs: d.durationMs,
            status: d.status,
            input: d.input,
            output: d.output,
            error: d.error,
          );
          return TimelineEntry(type: first.type, data: nd, sortTime: nd.startedAt);
        case TimelineEntryType.assistantRun:
          final d = first.data as AssistantRunEntry;
          final nd = AssistantRunEntry(
            id: d.id,
            threadId: d.threadId,
            assistantId: d.assistantId,
            externalId: d.externalId,
            status: d.status,
            inputTokens: d.inputTokens,
            outputTokens: d.outputTokens,
            cost: d.cost,
            createdAt: d.createdAt.add(kTimelineFirstEventOffset),
            completedAt: d.completedAt,
          );
          return TimelineEntry(type: first.type, data: nd, sortTime: nd.createdAt);
        case TimelineEntryType.threadSlots:
          // Для контекста слотов оставим как есть (не влияет на подсветку сообщений)
          return TimelineEntry(type: first.type, data: first.data, sortTime: first.sortTime.add(kTimelineFirstEventOffset));
      }
    }();

    // Возвращаем новый список с модифицированным первым элементом, порядок сохраняем
    return [shifted, ...list.skip(1)];
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

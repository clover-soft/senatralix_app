import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/timeline_provider.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/timeline_player_bar.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/timeline_message_bubble.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/timeline_event_banner.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/timeline_summary_panel.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/timeline_entry.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/sessions/styles/subfeature_styles.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/timeline_title_bar.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/sessions_threads_provider.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/player_controller.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final internalId =
        GoRouterState.of(context).pathParameters['internalId'] ?? '';

    final async = ref.watch(timelineProvider(internalId));
    final playerState = ref.watch(playerControllerProvider(internalId));

    // Дата/время начала звонка из таймлайна
    DateTime? callStart;
    callStart = async.maybeWhen(
      data: (entries) => entries.isNotEmpty ? entries.first.sortTime : null,
      orElse: () => null,
    );
    // Текущее абсолютное время звонка = callStart + позиция плеера
    final DateTime? currentAbsTime = (callStart != null)
        ? callStart.add(playerState.position)
        : null;
    // Заголовок треда берём из списка тредов ассистента
    final threadsAsync = ref.watch(sessionsThreadsProvider(assistantId));
    final threadTitle = threadsAsync.maybeWhen(
      data: (threads) {
        String? title;
        for (final t in threads) {
          if (t.internalId == internalId) {
            title = t.title;
            break;
          }
        }
        return title ?? (threads.isNotEmpty ? threads.first.title : 'Тред');
      },
      orElse: () => 'Тред',
    );
    // Длительность пока не используем в заголовке; при необходимости добавим позже

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Таймлайн',
        backPath: '/assistant/$assistantId/sessions',
        backTooltip: 'К списку тредов',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фон чата из стилей (картинка + градиент)
          SubfeatureStyles.of(context).buildChatBackground(),
          // Контент экрана
          Column(
            children: [
              TimelineTitleBar(title: threadTitle, callStart: callStart),
              TimelinePlayerBar(internalId: internalId),
              Expanded(
                child: async.when(
                  data: (entries) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1000;
                        final list = ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          itemCount: entries.length,
                          itemBuilder: (ctx, i) {
                            final e = entries[i];
                            switch (e.type) {
                              case TimelineEntryType.assistantMessage:
                                final msg = e.data as AssistantMessageEntry;
                                // Найдём время следующего сообщения, чтобы выделить интервал [msg.createdAt, nextMsgTime)
                                DateTime? nextMsgTime;
                                for (int j = i + 1; j < entries.length; j++) {
                                  if (entries[j].type ==
                                      TimelineEntryType.assistantMessage) {
                                    final next =
                                        entries[j].data
                                            as AssistantMessageEntry;
                                    nextMsgTime = next.createdAt;
                                    break;
                                  }
                                }
                                final start = msg.createdAt;
                                final end = nextMsgTime ?? DateTime(9999);
                                final isActive =
                                    currentAbsTime != null &&
                                    (currentAbsTime.isAfter(start) ||
                                        currentAbsTime.isAtSameMomentAs(
                                          start,
                                        )) &&
                                    currentAbsTime.isBefore(end);
                                return TimelineMessageBubble(
                                  message: msg,
                                  highlight: isActive,
                                );
                              case TimelineEntryType.toolCallLog:
                                final log = e.data as ToolCallLogEntry;
                                return TimelineEventBanner.tool(log: log);
                              case TimelineEntryType.assistantRun:
                                // Скрываем события Assistant Run
                                return const SizedBox.shrink();
                              case TimelineEntryType.threadSlots:
                                // Скрываем сообщение контекста/слотов в таймлайне
                                return const SizedBox.shrink();
                            }
                          },
                        );

                        if (!wide) {
                          // Мобильная/узкая: только лента, саммари снизу
                          return Column(
                            children: [
                              Expanded(child: list),
                              const Divider(height: 1),
                              SizedBox(
                                height: 220,
                                child: TimelineSummaryPanel(
                                  internalId: internalId,
                                ),
                              ),
                            ],
                          );
                        }

                        // Десктоп: двухпанельный
                        return Row(
                          children: [
                            Expanded(child: list),
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: 340,
                              child: TimelineSummaryPanel(
                                internalId: internalId,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Ошибка загрузки таймлайна'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.refresh(timelineProvider(internalId)),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

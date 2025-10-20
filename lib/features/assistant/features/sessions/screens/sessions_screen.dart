import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/sessions_threads_provider.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/sessions_filter_bar.dart';
import 'package:sentralix_app/features/assistant/features/sessions/widgets/thread_card.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantSessionsScreen extends ConsumerWidget {
  const AssistantSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';

    final threadsAsync = ref.watch(sessionsThreadsProvider(assistantId));

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'История чатов',
      ),
      body: Column(
        children: [
          const SessionsFilterBar(),
          Expanded(
            child: threadsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Нет тредов за выбранный период'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    return ThreadCard(
                      item: it,
                      onTap: () {
                        context.go(
                          '/assistant/$assistantId/sessions/${it.internalId}/timeline',
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Ошибка загрузки'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.refresh(sessionsThreadsProvider(assistantId)),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

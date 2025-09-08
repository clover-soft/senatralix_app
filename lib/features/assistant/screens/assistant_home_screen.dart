import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';

/// Локальное меню подфич ассистента
class AssistantHomeScreen extends ConsumerWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final listState = ref.watch(assistantListProvider);
    final name = listState.byId(id)?.name ?? 'Unknown';

    final items = <_SubItem>[
      _SubItem('Settings', 'Модель, температура, токены, промпт…', Icons.tune, '/assistant/$id/settings'),
      _SubItem('Tools', 'Инструменты, которые ассистент может вызывать', Icons.extension, '/assistant/$id/tools'),
      _SubItem('Knowledge', 'База знаний: загрузка и управление', Icons.storage, '/assistant/$id/knowledge'),
      _SubItem('Connectors', 'VOIP, Telegram, Avito, WhatsApp…', Icons.link, '/assistant/$id/connectors'),
      _SubItem('Scripts', 'События и действия: вход/выход, триггеры', Icons.schedule, '/assistant/$id/scripts'),
      _SubItem('Chat', 'Тестовый диалог с ассистентом', Icons.smart_toy, '/assistant/$id/chat'),
      _SubItem('Sessions', 'Сессии/треды, история', Icons.history, '/assistant/$id/sessions'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Assistant ($name)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w <= 480
                ? 1
                : (w <= 900
                    ? 2
                    : 3);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.9,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return Card(
                  color: scheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go(it.route),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(it.icon, color: scheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(it.title, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  it.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  _SubItem(this.title, this.subtitle, this.icon, this.route);
}

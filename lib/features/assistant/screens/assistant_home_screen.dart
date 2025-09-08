import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Локальное меню подфич ассистента
class AssistantHomeScreen extends StatelessWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';

    final items = <_SubItem>[
      _SubItem('Settings', Icons.tune, '/assistant/$id/settings'),
      _SubItem('Tools', Icons.extension, '/assistant/$id/tools'),
      _SubItem('Knowledge', Icons.storage, '/assistant/$id/knowledge'),
      _SubItem('Connectors', Icons.link, '/assistant/$id/connectors'),
      _SubItem('Scripts', Icons.schedule, '/assistant/$id/scripts'),
      _SubItem('Chat', Icons.smart_toy, '/assistant/$id/chat'),
      _SubItem('Sessions', Icons.history, '/assistant/$id/sessions'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Assistant ($id)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final crossAxisCount = isWide ? 3 : 2;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
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
                        children: [
                          Icon(it.icon, color: scheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              it.title,
                              style: Theme.of(context).textTheme.titleMedium,
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
  final IconData icon;
  final String route;
  _SubItem(this.title, this.icon, this.route);
}

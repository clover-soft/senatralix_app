// Экран надфичи Assistant: навигационное меню по подфичам (заглушки)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tiles = <_AssistantTile>[
      _AssistantTile('Settings', '/assistant/settings', Icons.tune),
      _AssistantTile('Tools', '/assistant/tools', Icons.extension),
      _AssistantTile('Knowledge', '/assistant/knowledge', Icons.storage),
      _AssistantTile('Connectors', '/assistant/connectors', Icons.link),
      _AssistantTile('Scripts', '/assistant/scripts', Icons.schedule),
      _AssistantTile('Chat', '/assistant/chat', Icons.smart_toy),
      _AssistantTile('Sessions', '/assistant/sessions', Icons.history),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final t = tiles[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(t.title),
            leading: Icon(t.icon, color: scheme.secondary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(t.route),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: tiles.length,
      ),
    );
  }
}

class _AssistantTile {
  final String title;
  final String route;
  final IconData icon;
  _AssistantTile(this.title, this.route, this.icon);
}

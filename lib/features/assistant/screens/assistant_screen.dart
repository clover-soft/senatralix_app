// Экран надфичи Assistant: выбор ассистента (список) + CRUD (заглушки)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final listState = ref.watch(assistantListProvider);
    final notifier = ref.read(assistantListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant — выбор ассистента'),
        actions: [
          IconButton(
            tooltip: 'Добавить ассистента',
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Простая заглушка: просим имя, по умолчанию Екатерина N
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  final ctrl = TextEditingController(text: 'Екатерина');
                  return AlertDialog(
                    title: const Text('Новый ассистент'),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Отмена'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                        child: const Text('Создать'),
                      ),
                    ],
                  );
                },
              );
              if (name != null && name.isNotEmpty) {
                notifier.add(name);
              }
            },
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final a = listState.items[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(a.name),
            subtitle: Text(a.id, style: Theme.of(context).textTheme.labelSmall),
            leading: Icon(Icons.smart_toy, color: scheme.secondary),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Переименовать',
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (ctx) {
                        final ctrl = TextEditingController(text: a.name);
                        return AlertDialog(
                          title: const Text('Переименовать ассистента'),
                          content: TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(labelText: 'Имя'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                              child: const Text('Сохранить'),
                            ),
                          ],
                        );
                      },
                    );
                    if (newName != null && newName.isNotEmpty) {
                      notifier.rename(a.id, newName);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить ассистента?'),
                        content: Text('Будет удалён "${a.name}"'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) notifier.remove(a.id);
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.go('/assistant/${a.id}'),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: listState.items.length,
      ),
    );
  }
}

// Экран надфичи Assistant: выбор ассистента (список) + CRUD (заглушки)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_list_item.dart';

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(assistantBootstrapProvider);
    final listState = ref.watch(assistantListProvider);
    final notifier = ref.read(assistantListProvider.notifier);

    if (boot.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Асистенты')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (boot.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Асистенты')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки данных'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(assistantBootstrapProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Асистенты'),
        actions: [
          IconButton(
            tooltip: 'Добавление ассистента временно недоступно',
            icon: const Icon(Icons.add),
            onPressed: null,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final a = listState.items[i];
          return AssistantListItem(
            assistant: a,
            onTap: () => context.go('/assistant/${a.id}'),
            onEdit: () async {
              await _showEditDialog(
                context,
                notifier,
                a.id,
                a.name,
                a.description,
              );
            },
            onDelete: null,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: listState.items.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Добавление ассистента временно недоступно',
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showEditDialog(
  BuildContext context,
  AssistantListNotifier notifier,
  String id,
  String currentName,
  String? currentDesc,
) async {
  final nameCtrl = TextEditingController(text: currentName);
  final descCtrl = TextEditingController(text: currentDesc ?? '');
  String? nameError;
  String? descError;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          void validate() {
            final n = nameCtrl.text.trim();
            final d = descCtrl.text.trim();
            nameError = (n.isEmpty || n.length < 2 || n.length > 40)
                ? 'Имя: 2–40 символов'
                : null;
            descError = (d.isNotEmpty && d.length > 280)
                ? 'Описание: до 280 символов'
                : null;
            setState(() {});
          }

          return AlertDialog(
            title: const Text('Редактировать ассистента'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    errorText: nameError,
                  ),
                  onChanged: (_) => validate(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Описание',
                    helperText: 'До 280 символов',
                    errorText: descError,
                  ),
                  onChanged: (_) => validate(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  validate();
                  if (nameError == null && descError == null) {
                    notifier.rename(
                      id,
                      nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      );
    },
  );
}

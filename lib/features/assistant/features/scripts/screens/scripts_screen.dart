import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_list_item.dart';
import 'package:sentralix_app/features/assistant/features/scripts/utils/filter_expression_parser.dart';
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/assistant_scripts_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_feature_list_item.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_fab.dart';

class AssistantScriptsScreen extends ConsumerWidget {
  const AssistantScriptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';

    final loader = ref.watch(assistantScriptsProvider(assistantId));
    final boot = ref.watch(assistantBootstrapProvider);
    final items = ref.watch(
      scriptListProvider.select(
        (s) => s.byAssistantId[assistantId] ?? const [],
      ),
    );
    // Снимок списка на текущий кадр, чтобы не было рассинхронизации при DnD (Web)
    final itemsLocal = List<ScriptListItem>.from(items);

    void openDetails(ScriptListItem item) {
      context.go('/assistant/$assistantId/scripts/${item.id}');
    }

    if (loader.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Скрипты',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (loader.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Скрипты',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки данных'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.refresh(assistantScriptsProvider(assistantId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (boot.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Скрипты',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (boot.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Скрипты',
        ),
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
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Скрипты',
      ),
      floatingActionButton: AssistantActionFab(
        icon: Icons.add,
        tooltip: 'Добавить команду',
        onPressed: () => context.go('/assistant/$assistantId/scripts/new'),
      ),
      body: ReorderableListView(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.all(16),
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 6,
            color: Colors.transparent,
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          // Корректируем newIndex как это делает ReorderableListView внутри
          int adjustedNewIndex = newIndex;
          if (adjustedNewIndex > oldIndex) adjustedNewIndex -= 1;
          if (adjustedNewIndex == oldIndex) return; // no-op
          // На Web переносим обновление состояния на следующий кадр,
          // чтобы избежать ошибок движка при завершении DnD
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 1) Локально переставим
            ref.read(scriptListProvider.notifier).reorder(
                  assistantId,
                  oldIndex,
                  newIndex,
                );
            // 2) Синхронизируем изменившиеся order на бэкенде (простой вариант)
            Future.microtask(() async {
              final api = ref.read(assistantApiProvider);
              final after = ref
                  .read(scriptListProvider)
                  .byAssistantId[assistantId] ??
                  const <ScriptListItem>[];
              for (final it in after) {
                final before = itemsLocal.firstWhere(
                  (x) => x.id == it.id,
                  orElse: () => it,
                );
                if (before.order != it.order) {
                  try {
                    await api.updateThreadCommandRaw(
                      id: it.id,
                      assistantId: it.assistantId,
                      order: it.order,
                      name: it.name,
                      description: it.description,
                      filterExpression: it.filterExpression,
                      isActive: it.isActive,
                    );
                  } catch (_) {
                    // На первом шаге просто игнорируем ошибку; можно добавить Snackbar
                  }
                }
              }
            });
          });
        },
        children: [
          for (int index = 0; index < itemsLocal.length; index++)
            () {
              final it = itemsLocal[index];
              final subtitle = it.description.trim();
              final parsed = parseFilterExpression(it.filterExpression);
              return AssistantFeatureListItem(
                key: ValueKey('script-${it.id}'),
                onTap: () => openDetails(it),
                leadingIcon: Icon(
                  RemixIcons.flow_chart,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                switchValue: it.isActive,
                switchTooltip: it.isActive
                    ? 'Выключить скрипт'
                    : 'Включить скрипт',
                onSwitchChanged: (v) {
                  ref
                      .read(scriptListProvider.notifier)
                      .toggleActive(assistantId, it.id, v);
                },
                title: it.name.isEmpty ? 'Без имени' : it.name,
                subtitle: subtitle,
                metaWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'порядок: ${it.order}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      parsed.preset.icon,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      parsed.preset.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                showDelete: true,
                onDeletePressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Удалить скрипт?'),
                      content: const Text(
                        'Действие необратимо. Скрипт будет удалён без возможности восстановления.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(ctx).colorScheme.error,
                          ),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  final api = ref.read(assistantApiProvider);
                  try {
                    await api.deleteThreadCommand(it.id);
                  } catch (e) {
                    // Если 404 — считаем, что элемент уже удалён
                  }
                  // Локально удалим из списка
                  ref.read(scriptListProvider.notifier).remove(assistantId, it.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Скрипт удалён')),
                    );
                  }
                },
                showChevron: true,
                tilePadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                showReorderHandle: true,
                reorderIndex: index,
                reorderTooltip: 'Перетащите, чтобы изменить порядок',
                reorderHandleFirst: true,
              );
            }(),
        ],
      ),
    );
  }
}

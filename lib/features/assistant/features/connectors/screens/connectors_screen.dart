import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/connector_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/assistant_connectors_provider.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/assistant_attached_connectors_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_feature_settings_provider.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/app_list_item.dart';
import 'package:remixicon/remixicon.dart';

class AssistantConnectorsScreen extends ConsumerStatefulWidget {
  const AssistantConnectorsScreen({super.key});

  @override
  ConsumerState<AssistantConnectorsScreen> createState() =>
      _AssistantConnectorsScreenState();
}

class _AssistantConnectorsScreenState
    extends ConsumerState<AssistantConnectorsScreen> {
  late String _assistantId;
  final Set<String> _toggling = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  Future<void> _createConnector() async {
    // Защита по лимиту перед показом диалога
    final maxAllowed = ref
        .read(assistantFeatureSettingsProvider)
        .settings
        .connectors
        .maxConnectorItems;
    final currentCount = ref.read(
      connectorsProvider.select(
        (s) => s.byAssistantId[_assistantId]?.length ?? 0,
      ),
    );
    if (maxAllowed > 0 && currentCount >= maxAllowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Достигнут лимит коннекторов: $maxAllowed')),
        );
      }
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый коннектор'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Имя коннектора'),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      final api = ref.read(assistantApiProvider);
      final created = await api.createConnector(name: name);
      // Обновить локальный список и перейти в детали
      ref.read(connectorsProvider.notifier).add(_assistantId, created);
      if (mounted)
        context.go('/assistant/$_assistantId/connectors/${created.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка создания: $e')));
    }
  }

  void _edit(Connector c) {
    context.go('/assistant/$_assistantId/connectors/${c.id}');
  }

  void _remove(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить коннектор?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final api = ref.read(assistantApiProvider);
        await api.deleteConnector(id);
        if (!mounted) return;
        ref.read(connectorsProvider.notifier).remove(_assistantId, id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Удалено')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(assistantBootstrapProvider);
    final loader = ref.watch(assistantConnectorsProvider(_assistantId));
    final attachedSet = ref.watch(
      assistantAttachedConnectorsProvider(_assistantId),
    );
    final featureSettings = ref
        .watch(assistantFeatureSettingsProvider)
        .settings;
    final items = ref.watch(
      connectorsProvider.select(
        (s) => s.byAssistantId[_assistantId] ?? const [],
      ),
    );
    final maxAllowed = featureSettings.connectors.maxConnectorItems;
    if (loader.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: _assistantId,
          subfeatureTitle: 'Коннекторы',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (loader.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: _assistantId,
          subfeatureTitle: 'Коннекторы',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки коннекторов'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.refresh(assistantConnectorsProvider(_assistantId)),
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
          assistantId: _assistantId,
          subfeatureTitle: 'Коннекторы',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (boot.hasError) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: _assistantId,
          subfeatureTitle: 'Коннекторы',
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
        assistantId: _assistantId,
        subfeatureTitle: 'Коннекторы',
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: (maxAllowed > 0 && items.length >= maxAllowed)
            ? 'Коннекторы: ${items.length} из $maxAllowed. Лимит коннекторов достигнут'
            : 'Создать коннектор (${items.length}${maxAllowed > 0 ? ' / $maxAllowed' : ''})',
        onPressed: (maxAllowed > 0 && items.length >= maxAllowed)
            ? null
            : _createConnector,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final it = items[index];
          final bool isAttached = attachedSet.maybeWhen(
            data: (s) =>
                s.contains(it.id), // external_id совпадает с it.id (UUID)
            orElse: () => false,
          );
          final bool isBusy =
              _toggling.contains(it.id) || attachedSet.isLoading;
          return AppListItem(
            onTap: () => _edit(it),
            leadingIcon: Icon(
              RemixIcons.phone_line,
              color: Theme.of(context).colorScheme.secondary,
            ),
            switchValue: isAttached,
            switchTooltip: isAttached
                ? 'Отключить коннектор от ассистента'
                : 'Подключить коннектор к ассистенту',
            onSwitchChanged: isBusy
                ? null
                : (v) async {
                    setState(() => _toggling.add(it.id));
                    try {
                      final api = ref.read(assistantApiProvider);
                      if (v) {
                        await api.assignConnectorToAssistant(
                          assistantId: _assistantId,
                          externalId: it.id,
                          type: 'voip',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Коннектор подключён')));
                        }
                      } else {
                        await api.unassignConnectorFromAssistant(
                          assistantId: _assistantId,
                          externalId: it.id,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Коннектор отключён')));
                        }
                      }
                      // Обновим набор подключённых
                      ref.invalidate(assistantAttachedConnectorsProvider);
                      await ref.read(assistantAttachedConnectorsProvider(_assistantId).future);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      }
                    } finally {
                      if (mounted) setState(() => _toggling.remove(it.id));
                    }
                  },
            title: it.name.isEmpty ? 'Без имени' : it.name,
            subtitle: it.id,
            meta: isAttached ? 'Подключён к ассистенту' : 'Не подключён',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Редактировать',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(it),
                ),
                IconButton(
                  tooltip: it.settings.allowDelete
                      ? 'Удалить'
                      : 'Удаление запрещено',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: it.settings.allowDelete
                      ? () => _remove(it.id)
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

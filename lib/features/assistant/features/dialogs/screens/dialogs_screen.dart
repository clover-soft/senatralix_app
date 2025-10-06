import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_tree_panel.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';

/// Экран-заготовка подфичи "Сценарии" (dialogs)
class AssistantDialogsScreen extends ConsumerWidget {
  const AssistantDialogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    // Гарантируем, что список ассистентов загружен, чтобы в AppBar было имя, а не id
    ref.watch(assistantBootstrapProvider);
    final configsAsync = ref.watch(dialogConfigsProvider);
    final selectedId = ref.watch(selectedDialogConfigIdProvider);

    final cfg = ref.watch(dialogsConfigControllerProvider);
    final subTitle = cfg.name.isNotEmpty ? 'Сценарии — ${cfg.name}' : 'Сценарии';

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: id,
        subfeatureTitle: subTitle,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: configsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 8),
                Text('Не удалось загрузить конфиги сценариев: $e'),
              ],
            ),
          ),
          data: (configs) {
            if (configs.isEmpty) {
              final scheme = Theme.of(context).colorScheme;
              return Center(
                child: SizedBox(
                  width: 360,
                  height: 200,
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6), width: 1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        final nameCtrl = TextEditingController();
                        final descCtrl = TextEditingController();
                        final formKey = GlobalKey<FormState>();

                        final createdId = await showDialog<int?>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Новая конфигурация сценария'),
                            content: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Название сценария',
                                    ),
                                    autofocus: true,
                                    validator: (v) {
                                      final s = (v ?? '').trim();
                                      if (s.length < 2) return 'Минимум 2 символа';
                                      if (s.length > 64) return 'Максимум 64 символа';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: descCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Описание сценария (необязательно)'
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(null),
                                child: const Text('Отмена'),
                              ),
                              FilledButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить сценарий'),
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ?? false)) return;
                                  final createdId = await ref
                                      .read(dialogsConfigControllerProvider.notifier)
                                      .createConfigWithWelcomeStep(
                                        name: nameCtrl.text.trim(),
                                        description: descCtrl.text.trim(),
                                      );
                                  if (!ctx.mounted) return;
                                  Navigator.of(ctx).pop(createdId);
                                },
                              ),
                            ],
                          ),
                        );

                        if (createdId != null) {
                          ref.invalidate(dialogConfigsProvider);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref.read(selectedDialogConfigIdProvider.notifier).state = createdId;
                            ref
                                .read(dialogsConfigControllerProvider.notifier)
                                .selectConfig(createdId);
                          });
                        }
                      },
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(Icons.add, size: 32, color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Добавить сценарий',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            // Вычислим selectedIndex по selectedId (или 0, если нет/не найден)
            int selectedIndex = 0;
            if (selectedId != null) {
              final idx = configs.indexWhere((c) => c.id == selectedId);
              if (idx >= 0) {
                selectedIndex = idx;
              } else {
                selectedIndex = 0;
              }
            }
            // Если выбранный id не задан или отсутствует в списке — выставим корректный id
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final currentSel = ref.read(selectedDialogConfigIdProvider);
              if (currentSel == null ||
                  configs.indexWhere((c) => c.id == currentSel) < 0) {
                final fixId = configs[selectedIndex].id;
                ref.read(selectedDialogConfigIdProvider.notifier).state = fixId;
                ref.read(dialogsConfigControllerProvider.notifier).selectConfig(fixId);
              }
            });

            // Ключ на основе состава вкладок и выбранного индекса — гарантирует пересоздание контроллера
            final tabsKey = ValueKey(
              '${configs.map((e) => e.id).join(',')}:$selectedIndex',
            );
            return DefaultTabController(
              key: tabsKey,
              length: configs.length,
              initialIndex: selectedIndex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          onTap: (i) {
                            final idSel = configs[i].id;
                            ref.read(selectedDialogConfigIdProvider.notifier).state = idSel;
                            // Инициируем загрузку деталей в бизнес-контроллере
                            ref.read(dialogsConfigControllerProvider.notifier).selectConfig(idSel);
                          },
                          tabs: [for (final c in configs) Tab(text: c.name)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Добавить сценарий',
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final nameCtrl = TextEditingController();
                            final descCtrl = TextEditingController();
                            final formKey = GlobalKey<FormState>();

                            final createdId = await showDialog<int?>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Новая конфигурация сценария'),
                                content: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: nameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Название сценария',
                                        ),
                                        autofocus: true,
                                        validator: (v) {
                                          final s = (v ?? '').trim();
                                          if (s.length < 2) return 'Минимум 2 символа';
                                          if (s.length > 64) return 'Максимум 64 символа';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: descCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Описание сценария (необязательно)'
                                        ),
                                        maxLines: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(null),
                                    child: const Text('Отмена'),
                                  ),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Добавить сценарий'),
                                    onPressed: () async {
                                      if (!(formKey.currentState?.validate() ?? false)) return;
                                      final createdId = await ref
                                          .read(dialogsConfigControllerProvider.notifier)
                                          .createConfigWithWelcomeStep(
                                            name: nameCtrl.text.trim(),
                                            description: descCtrl.text.trim(),
                                          );
                                      if (!ctx.mounted) return;
                                      Navigator.of(ctx).pop(createdId);
                                    },
                                  ),
                                ],
                              ),
                            );

                            if (createdId != null) {
                              // Обновляем список вкладок и выбираем новую, инициируем загрузку деталей
                              ref.invalidate(dialogConfigsProvider);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(selectedDialogConfigIdProvider.notifier).state = createdId;
                                ref.read(dialogsConfigControllerProvider.notifier).selectConfig(createdId);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final c in configs) _DialogConfigTab(config: c),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DialogConfigTab extends ConsumerWidget {
  const _DialogConfigTab({required this.config});
  final DialogConfigShort config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(dialogConfigDetailsProvider(config.id));
    return detailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Ошибка загрузки: $e')),
      data: (details) {
        return _DialogEditor(details: details);
      },
    );
  }
}

/// Простейший редактор: Canvas + правая панель свойств + клик-клик для установки next
class _DialogEditor extends ConsumerStatefulWidget {
  const _DialogEditor({required this.details});
  final DialogConfigDetails details;
  @override
  ConsumerState<_DialogEditor> createState() => _DialogEditorState();
}

class _DialogEditorState extends ConsumerState<_DialogEditor> {
  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: outline),
        // без скруглений
      ),
      child: const DialogsTreePanel(),
    );
  }
}

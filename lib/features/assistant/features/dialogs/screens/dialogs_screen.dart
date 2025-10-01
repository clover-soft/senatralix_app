import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_tree_panel.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';

/// Экран-заготовка подфичи "Сценарии" (dialogs)
class AssistantDialogsScreen extends ConsumerWidget {
  const AssistantDialogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final configsAsync = ref.watch(dialogConfigsProvider);
    final selectedId = ref.watch(selectedDialogConfigIdProvider);

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: id,
        subfeatureTitle: 'Сценарии',
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
                Text('Не удалось загрузить конфиги диалогов: $e'),
              ],
            ),
          ),
          data: (configs) {
            if (configs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forum_outlined, size: 48),
                    const SizedBox(height: 8),
                    const Text('Конфигурации диалогов отсутствуют'),
                  ],
                ),
              );
            }

            // Вычислим initialIndex по selectedId, если он задан, иначе 0
            int initialIndex = 0;
            if (selectedId != null) {
              final idx = configs.indexWhere((c) => c.id == selectedId);
              if (idx >= 0) initialIndex = idx;
            } else {
              // Установим выбранный после окончания билда, чтобы не менять провайдер в build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ref.read(selectedDialogConfigIdProvider) == null &&
                    configs.isNotEmpty) {
                  ref.read(selectedDialogConfigIdProvider.notifier).state =
                      configs.first.id;
                }
              });
            }

            return DefaultTabController(
              length: configs.length,
              initialIndex: initialIndex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          onTap: (i) => ref
                              .read(selectedDialogConfigIdProvider.notifier)
                              .state = configs[i].id,
                          tabs: [for (final c in configs) Tab(text: c.name)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Добавить диалог',
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final nameCtrl = TextEditingController();
                            final descCtrl = TextEditingController();
                            final formKey = GlobalKey<FormState>();

                            final createdId = await showDialog<int?>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Новая конфигурация диалога'),
                                content: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: nameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Название',
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
                                          labelText: 'Описание (необязательно)'
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
                                    label: const Text('Добавить'),
                                    onPressed: () async {
                                      if (!(formKey.currentState?.validate() ?? false)) return;
                                      final api = ref.read(assistantApiProvider);
                                      final json = await api.createDialogConfig(
                                        name: nameCtrl.text.trim(),
                                        description: descCtrl.text.trim(),
                                      );
                                      final id = int.tryParse('${json['id']}');
                                      Navigator.of(ctx).pop(id);
                                    },
                                  ),
                                ],
                              ),
                            );

                            if (createdId != null) {
                              // Обновляем список вкладок и выбираем новую
                              ref.invalidate(dialogConfigsProvider);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(selectedDialogConfigIdProvider.notifier).state = createdId;
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
        // Инициализируем контроллер шагами после завершения текущего кадра,
        // чтобы избежать модификации провайдера во время build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctrl = ref.read(dialogsEditorControllerProvider.notifier);
          ctrl.setSteps(details.steps);
        });
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
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
      appBar: AssistantAppBar(assistantId: id),
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
                          onTap: (i) =>
                              ref
                                  .read(selectedDialogConfigIdProvider.notifier)
                                  .state = configs[i]
                                  .id,
                          tabs: [for (final c in configs) Tab(text: c.name)],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Обновить',
                        onPressed: () => ref.invalidate(dialogConfigsProvider),
                        icon: const Icon(Icons.refresh),
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

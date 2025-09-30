import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_node.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';

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
      data: (details) => _DialogEditor(details: details),
    );
  }
}

/// Простейший редактор: Canvas + правая панель свойств + клик-клик для установки next
class _DialogEditor extends StatefulWidget {
  const _DialogEditor({required this.details});
  final DialogConfigDetails details;

  @override
  State<_DialogEditor> createState() => _DialogEditorState();
}

class _DialogEditorState extends State<_DialogEditor> {
  int? _selectedStepId;
  int? _linkStartStepId; // если задан, следующий клик по узлу установит next
  late List<DialogStep> _steps; // локальная копия для UI-оверрайдов next

  // GraphView структуры
  final Graph _graph = Graph()..isTree = false;
  final Map<int, Node> _nodeById = {};

  @override
  void initState() {
    super.initState();
    _steps = List<DialogStep>.from(widget.details.steps);
    _rebuildGraph();
  }

  @override
  void didUpdateWidget(covariant _DialogEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.details.steps, widget.details.steps)) {
      _steps = List<DialogStep>.from(widget.details.steps);
      _rebuildGraph();
      _selectedStepId = null;
      _linkStartStepId = null;
    }
  }

  void _onNodeTap(int tappedId) {
    if (_linkStartStepId != null && _linkStartStepId != tappedId) {
      // установить next
      setState(() {
        final idx = _steps.indexWhere((e) => e.id == _linkStartStepId);
        if (idx >= 0) {
          final s = _steps[idx];
          _steps[idx] = DialogStep(
            id: s.id,
            name: s.name,
            label: s.label,
            instructions: s.instructions,
            requiredSlotsIds: s.requiredSlotsIds,
            optionalSlotsIds: s.optionalSlotsIds,
            next: tappedId,
            branchLogic: s.branchLogic,
          );
        }
        _selectedStepId = _linkStartStepId;
        _linkStartStepId = null;
        _rebuildGraph();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Связь next обновлена')));
      }
    } else {
      setState(() {
        _selectedStepId = tappedId;
      });
    }
  }

  void _rebuildGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();
    _nodeById.clear();
    // узлы
    for (final s in _steps) {
      final n = Node.Id(s.id);
      _nodeById[s.id] = n;
      _graph.addNode(n);
    }
    // рёбра next
    for (final s in _steps) {
      if (s.next != null) {
        final from = _nodeById[s.id];
        final to = _nodeById[s.next!];
        if (from != null && to != null) {
          _graph.addEdge(from, to);
        }
      }
    }
    // рёбра ветвлений (branch_logic): slotId -> {value: stepId}
    final branchPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final s in _steps) {
      if (s.branchLogic.isEmpty) continue;
      for (final mapping in s.branchLogic.values) {
        for (final entry in mapping.entries) {
          final toId = entry.value;
          if (toId <= 0) continue; // пропускаем некорректные
          final from = _nodeById[s.id];
          final to = _nodeById[toId];
          if (from != null && to != null) {
            _graph.addEdge(from, to, paint: branchPaint);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rightPanelW = 340.0;
    final sg = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
      ..nodeSeparation = 20
      ..levelSeparation = 80;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Двойной скролл + «loose»-холст, как в примерах graphview
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints.loose(Size(2400, 1800)),
                      child: GraphView(
                        graph: _graph,
                        algorithm: SugiyamaAlgorithm(sg),
                        builder: (Node n) {
                          final id = n.key!.value as int; // Node.Id(s.id)
                          final step = _steps.firstWhere((e) => e.id == id);
                          final isSelected =
                              _selectedStepId == id || _linkStartStepId == id;
                          return GestureDetector(
                            onTap: () => _onNodeTap(id),
                            child: StepNode(step: step, selected: isSelected),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Right panel
          SizedBox(
            width: rightPanelW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Свойства шага',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: _linkStartStepId == null
                            ? 'Назначить next: выберите узел-источник'
                            : 'Кликните по целевому узлу',
                        onPressed: _selectedStepId == null
                            ? null
                            : () {
                                setState(() {
                                  _linkStartStepId = _selectedStepId;
                                });
                              },
                        icon: Icon(
                          Icons.call_merge,
                          color: _linkStartStepId == null
                              ? null
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedStepId == null
                      ? const Center(child: Text('Выберите шаг на графе'))
                      : StepProps(
                          step: _steps.firstWhere(
                            (e) => e.id == _selectedStepId,
                          ),
                          allSteps: _steps,
                          onUpdate: (updated) {
                            final idx = _steps.indexWhere(
                              (e) => e.id == updated.id,
                            );
                            if (idx >= 0) {
                              setState(() {
                                _steps[idx] = updated;
                                _rebuildGraph();
                              });
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

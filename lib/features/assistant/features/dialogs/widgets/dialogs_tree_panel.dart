import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_tree_canvas.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_node.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_toolbar_panel.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';
import 'package:sentralix_app/core/logger.dart';

/// Левая панель: дерево сценария
class DialogsTreePanel extends ConsumerStatefulWidget {
  const DialogsTreePanel({super.key});

  @override
  ConsumerState<DialogsTreePanel> createState() => _DialogsTreePanelState();
}

class _DialogsTreePanelState extends ConsumerState<DialogsTreePanel> {
  final TransformationController _tc = TransformationController();
  final GlobalKey _contentKey = GlobalKey();
  final Map<int, GlobalKey> _nodeKeys = {};
  bool _didAutoFit = false;
  Size? _lastViewportSize;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTcChanged);
    // Слушаем изменения редактора: при любом апдейте шагов пересобираем/рефитим граф
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listen(dialogsEditorControllerProvider, (prev, next) {
        if (!mounted) return;
        setState(() {
          _didAutoFit = false;
          _lastViewportSize = null;
        });
      });
    });
  }

  void _onTcChanged() {
    if (!mounted) return;
    // Обновляем UI (в частности, положение слайдера) при изменении масштаба/матрицы
    setState(() {});
  }

  @override
  void dispose() {
    _tc.removeListener(_onTcChanged);
    _tc.dispose();
    super.dispose();
  }

  /// Открыть модалку настроек диалога (редактирование имени и описания)
  Future<void> _openDialogSettings() async {
    final id = ref.read(selectedDialogConfigIdProvider);
    if (id == null) return;
    final details = await ref.read(dialogConfigDetailsProvider(id).future);
    final nameCtrl = TextEditingController(text: details.name);
    final descCtrl = TextEditingController(text: details.description);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Настройки диалога'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название'),
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
                  labelText: 'Описание (необязательно)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final api = ref.read(assistantApiProvider);
              await api.updateDialogConfig(
                id: id,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );

    if (saved == true) {
      ref.invalidate(dialogConfigsProvider);
      ref.invalidate(dialogConfigDetailsProvider(id));
      setState(() {
        _didAutoFit = false;
        _lastViewportSize = null;
      });
    }
  }

  /// Расчёт реальных границ графа по позициям нод в системе координат контента
  Rect? _computeNodesBounds() {
    final contentCtx = _contentKey.currentContext;
    if (contentCtx == null) return null;
    final contentBox = contentCtx.findRenderObject() as RenderBox?;
    if (contentBox == null || !contentBox.hasSize) return null;

    Rect? bounds;
    for (final entry in _nodeKeys.entries) {
      final nodeCtx = entry.value.currentContext;
      if (nodeCtx == null) continue;
      final nodeBox = nodeCtx.findRenderObject() as RenderBox?;
      if (nodeBox == null || !nodeBox.hasSize) continue;
      final topLeft = nodeBox.localToGlobal(Offset.zero, ancestor: contentBox);
      final rect = topLeft & nodeBox.size;
      final b = bounds;
      bounds = b == null ? rect : b.expandToInclude(rect);
    }
    AppLogger.d(
      '[TreePanel] _computeNodesBounds: nodes=${_nodeKeys.length}, bounds=$bounds',
      tag: 'DialogsTree',
    );
    return bounds;
  }

  void _setScale(double newScale) {
    // Ограничиваем масштаб в допустимых границах и центрируем контент
    newScale = newScale.clamp(0.5, 2.5);
    _centerWithScale(newScale);
  }

  /// Центрирует граф в пределах окна для заданного масштаба, не подбирая масштаб
  void _centerWithScale(double scale) {
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize) return;
    final viewportSize = viewportBox.size;

    final nodesBounds = _computeNodesBounds();
    if (nodesBounds == null) return;

    // Центрируем прямоугольник графа
    final rectCenter = nodesBounds.center;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final tx = viewportCenter.dx - rectCenter.dx * scale;
    final ty = viewportCenter.dy - rectCenter.dy * scale;

    setState(() {
      _tc.value = Matrix4.identity()
        ..translateByVector3(vm.Vector3(tx, ty, 0))
        ..scaleByVector3(vm.Vector3(scale, scale, 1));
    });
  }

  void _fitAndCenter(Size viewportSize) {
    // Рассчёт по реальным границам графа (нод)
    final nodesBounds = _computeNodesBounds();
    if (nodesBounds == null || nodesBounds.isEmpty) return;
    final contentW = nodesBounds.width;
    final contentH = nodesBounds.height;
    if (contentW <= 0 || contentH <= 0) return;

    // Рассчитываем масштаб, чтобы вписать оба измерения в окно
    final scaleX = viewportSize.width / contentW;
    final scaleY = viewportSize.height / contentH;
    // Чуть уменьшим, чтобы не прилипало к краям
    var targetScale = (scaleX < scaleY ? scaleX : scaleY) * 0.9;
    // Не даём выйти за пределы InteractiveViewer
    targetScale = targetScale.clamp(0.5, 2.5);

    // Центруем прямоугольник графа
    final rectCenter = nodesBounds.center;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final tx = viewportCenter.dx - rectCenter.dx * targetScale;
    final ty = viewportCenter.dy - rectCenter.dy * targetScale;

    setState(() {
      _tc.value = Matrix4.identity()
        ..translateByVector3(vm.Vector3(tx, ty, 0))
        ..scaleByVector3(vm.Vector3(targetScale, targetScale, 1));
    });
  }

  void _centerOnNode(int id) {
    final nodeKey = _nodeKeys[id];
    if (nodeKey == null) {
      AppLogger.d(
        '[TreePanel] _centerOnNode: nodeKey for id=$id is null (keys=${_nodeKeys.keys.toList()})',
        tag: 'DialogsTree',
      );
      return;
    }
    final nodeCtx = nodeKey.currentContext;
    final contentCtx = _contentKey.currentContext;
    if (nodeCtx == null || contentCtx == null) {
      AppLogger.d(
        '[TreePanel] _centerOnNode: contexts missing (nodeCtx=${nodeCtx != null}, contentCtx=${contentCtx != null}) for id=$id',
        tag: 'DialogsTree',
      );
      return;
    }

    final nodeBox = nodeCtx.findRenderObject() as RenderBox?;
    final contentBox = contentCtx.findRenderObject() as RenderBox?;
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (nodeBox == null || contentBox == null || viewportBox == null) {
      AppLogger.d(
        '[TreePanel] _centerOnNode: boxes missing (nodeBox=${nodeBox != null}, contentBox=${contentBox != null}, viewportBox=${viewportBox != null})',
        tag: 'DialogsTree',
      );
      return;
    }
    if (!nodeBox.hasSize || !contentBox.hasSize || !viewportBox.hasSize) {
      AppLogger.d(
        '[TreePanel] _centerOnNode: no size (node=${nodeBox.hasSize}, content=${contentBox.hasSize}, viewport=${viewportBox.hasSize})',
        tag: 'DialogsTree',
      );
      return;
    }

    // Координаты ноды в системе контента (до трансформации)
    final nodeTopLeft = nodeBox.localToGlobal(
      Offset.zero,
      ancestor: contentBox,
    );
    final nodeSize = nodeBox.size;
    final nodeCenter =
        nodeTopLeft + Offset(nodeSize.width / 2, nodeSize.height / 2);

    // Текущий масштаб
    var currentScale = _tc.value.getMaxScaleOnAxis();
    currentScale = currentScale.clamp(0.5, 2.5);
    final viewportSize = viewportBox.size;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    // Хотим: nodeCenter * scale + translate = viewportCenter
    final tx = viewportCenter.dx - nodeCenter.dx * currentScale;
    final ty = viewportCenter.dy - nodeCenter.dy * currentScale;

    AppLogger.d(
      '[TreePanel] _centerOnNode: id=$id center=$nodeCenter scale=$currentScale translate=($tx,$ty) viewport=$viewportSize',
      tag: 'DialogsTree',
    );
    setState(() {
      _tc.value = Matrix4.identity()
        ..translateByVector3(vm.Vector3(tx, ty, 0))
        ..scaleByVector3(vm.Vector3(currentScale, currentScale, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final graph = ref.watch(graphProvider);
    final algorithm = GraphStyle.sugiyamaTopBottom(
      nodeSeparation: 20,
      levelSeparation: 80,
    ).buildAlgorithm();
    final editor = ref.watch(dialogsEditorControllerProvider);

    return ClipRect(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          // Авто-вписывание: один раз после первой загрузки и при заметном ресайзе
          final viewportSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          // Динамический размер холста на основе фактических границ нод
          const double pad = 300.0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final bounds = _computeNodesBounds();
            if (bounds != null && bounds.isFinite) {
              final w = bounds.width + pad;
              final h = bounds.height + pad;
              final proposed = Size(
                w < viewportSize.width ? viewportSize.width : w,
                h < viewportSize.height ? viewportSize.height : h,
              );
              if ((_canvasSize.width - proposed.width).abs() > 1 ||
                  (_canvasSize.height - proposed.height).abs() > 1) {
                if (mounted) setState(() => _canvasSize = proposed);
              }
            } else {
              final proposed = viewportSize;
              if ((_canvasSize.width - proposed.width).abs() > 1 ||
                  (_canvasSize.height - proposed.height).abs() > 1) {
                if (mounted) setState(() => _canvasSize = proposed);
              }
            }
          });
          final hasSteps = ref
              .read(dialogsEditorControllerProvider)
              .steps
              .isNotEmpty;
          final sizeChanged =
              _lastViewportSize == null ||
              (viewportSize.width - (_lastViewportSize!.width)).abs() > 8 ||
              (viewportSize.height - (_lastViewportSize!.height)).abs() > 8;
          if (hasSteps && (!_didAutoFit || sizeChanged)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitAndCenter(viewportSize);
              _didAutoFit = true;
              _lastViewportSize = viewportSize;
            });
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Статичный фон/сетка, привязанная к окну, а не графу
                CustomPaint(
                  painter: _StaticDotsPainter(
                    dotSpacing: 34, // было 24
                    dotRadius: 1, // было 1.2
                    dotColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.9),
                    bgColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.08),
                    veilOpacity: Theme.of(context).brightness == Brightness.dark
                        ? 0.08
                        : 0.5,
                  ),
                ),
                // Сам холст с графом
                DialogsTreeCanvas(
                  graph: graph,
                  algorithm: algorithm,
                  canvasSize: _canvasSize == Size.zero
                      ? viewportSize
                      : _canvasSize,
                  transformationController: _tc,
                  contentKey: _contentKey,
                  nodeBuilder: (Node n) {
                    final id = n.key!.value as int;
                    final step = editor.steps.firstWhere((e) => e.id == id);
                    final isSelected =
                        editor.selectedStepId == id ||
                        editor.linkStartStepId == id;
                    final key = _nodeKeys.putIfAbsent(id, () => GlobalKey());
                    return Material(
                      key: key,
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref
                            .read(dialogsEditorControllerProvider.notifier)
                            .onNodeTap(id),
                        onDoubleTap: () => _centerOnNode(id),
                        child: StepNode(
                          step: step,
                          selected: isSelected,
                          onAddNext: () {
                            final notifier = ref.read(
                              dialogsEditorControllerProvider.notifier,
                            );
                            final newId = notifier.addNextStep(id);
                            AppLogger.d(
                              '[TreePanel] Node action: addNext from=$id -> newId=$newId',
                              tag: 'DialogsTree',
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _centerOnNode(newId);
                            });
                          },
                          onSettings: () async {
                            ref
                                .read(dialogsEditorControllerProvider.notifier)
                                .selectStep(id);
                            AppLogger.d(
                              '[TreePanel] Node action: opening settings for id=$id',
                              tag: 'DialogsTree',
                            );
                            await showDialog<bool>(
                              context: context,
                              builder: (ctx) => StepProps(stepId: id),
                            );
                          },
                          onDelete: () {
                            AppLogger.w(
                              '[TreePanel] Node action: delete requested for id=$id (not implemented)',
                              tag: 'DialogsTree',
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // Панель управления справа
                Positioned(
                  right: 20,
                  top: 20,
                  child: DialogsToolbarPanel(
                    onFitPressed: () {
                      final rb = context.findRenderObject() as RenderBox?;
                      if (rb == null || !rb.hasSize) return;
                      final viewportSize = rb.size;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _fitAndCenter(viewportSize);
                      });
                    },
                    currentScale: _tc.value.getMaxScaleOnAxis().clamp(0.5, 2.5),
                    onScaleChanged: (v) => _setScale(v),
                    onSettingsPressed: _openDialogSettings,
                    onRefreshPressed: () {
                      final selectedId = ref.read(
                        selectedDialogConfigIdProvider,
                      );
                      if (selectedId != null) {
                        ref.invalidate(dialogConfigDetailsProvider(selectedId));
                      } else {
                        ref.invalidate(dialogConfigsProvider);
                      }
                      setState(() {
                        _didAutoFit = false;
                        _lastViewportSize = null;
                      });
                    },
                    onAddPressed: () {
                      final editorState = ref.read(
                        dialogsEditorControllerProvider,
                      );
                      AppLogger.d(
                        '[TreePanel] onAddPressed: selectedStepId=${editorState.selectedStepId}',
                        tag: 'DialogsTree',
                      );
                      final notifier = ref.read(
                        dialogsEditorControllerProvider.notifier,
                      );
                      int newId;
                      if (editorState.selectedStepId != null) {
                        newId = notifier.addNextStep(
                          editorState.selectedStepId!,
                        );
                        AppLogger.d(
                          '[TreePanel] onAddPressed: addNextStep -> newId=$newId',
                          tag: 'DialogsTree',
                        );
                        // Логируем все шаги после добавления
                        final steps = ref
                            .read(dialogsEditorControllerProvider)
                            .steps;
                        for (final step in steps) {
                          AppLogger.d(
                            '[TreePanel] step: id=${step.id}, name=${step.name}, next=${step.next}',
                            tag: 'DialogsTree',
                          );
                        }
                        AppLogger.d(
                          '[TreePanel] steps (json): ${steps.map((e) => e.toString()).join(", ")}',
                          tag: 'DialogsTree',
                        );
                      } else {
                        notifier.addStep();
                        final steps = ref
                            .read(dialogsEditorControllerProvider)
                            .steps;
                        if (steps.isEmpty) return;
                        newId = steps
                            .map((e) => e.id)
                            .reduce((a, b) => a > b ? a : b);
                        AppLogger.d(
                          '[TreePanel] onAddPressed: addStep -> newId=$newId',
                          tag: 'DialogsTree',
                        );
                        // Логируем все шаги после добавления
                        AppLogger.d(
                          '[TreePanel] steps after addStep:',
                          tag: 'DialogsTree',
                        );
                        for (final step in steps) {
                          AppLogger.d(
                            '[TreePanel] step: id=${step.id}, name=${step.name}, next=${step.next}',
                            tag: 'DialogsTree',
                          );
                        }
                        AppLogger.d(
                          '[TreePanel] steps (json): ${steps.map((e) => e.toString()).join(", ")}',
                          tag: 'DialogsTree',
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        AppLogger.d(
                          '[TreePanel] onAddPressed: centering on newId=$newId',
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Статичный точечный фон, рисуется на размер окна панели
class _StaticDotsPainter extends CustomPainter {
  _StaticDotsPainter({
    required this.dotSpacing,
    required this.dotRadius,
    required this.dotColor,
    required this.bgColor,
    required this.veilOpacity,
  }) : super();

  final double dotSpacing;
  final double dotRadius;
  final Color dotColor;
  final Color bgColor;
  final double veilOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Заливка бэкграундом
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bgPaint);
    // Лёгкая белая вуаль для осветления и смешения с темой (зависит от темы)
    final veil = Paint()..color = Colors.white.withValues(alpha: veilOpacity);
    canvas.drawRect(Offset.zero & size, veil);

    // Точки сетки
    final dotPaint = Paint()..color = dotColor;
    final r = dotRadius;
    for (double y = 0; y <= size.height; y += dotSpacing) {
      for (double x = 0; x <= size.width; x += dotSpacing) {
        canvas.drawCircle(Offset(x, y), r, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaticDotsPainter oldDelegate) {
    return dotSpacing != oldDelegate.dotSpacing ||
        dotRadius != oldDelegate.dotRadius ||
        dotColor != oldDelegate.dotColor ||
        bgColor != oldDelegate.bgColor;
  }
}

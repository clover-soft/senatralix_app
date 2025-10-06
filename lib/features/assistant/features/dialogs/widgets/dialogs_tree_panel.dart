import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/dialogs_graph_builder.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_tree_canvas.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_node.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_toolbar_panel.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';
import 'package:sentralix_app/core/logger.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/utils/graph_cycles.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/back_edges/back_edge_route.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/back_edges/route_side_by_side.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/back_edges/route_side_by_side_left.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/back_edges/route_top_right_bypass.dart';

/// Левая панель: дерево сценария
class DialogsTreePanel extends ConsumerStatefulWidget {
  const DialogsTreePanel({super.key});

  @override
  ConsumerState<DialogsTreePanel> createState() => _DialogsTreePanelState();
}

/// Рисует обратные рёбра (back-edges), исключённые из GraphView, поверх холста.
class _BackEdgesPainter extends CustomPainter {
  _BackEdgesPainter({
    required this.backEdges,
    required this.nodeKeys,
    required this.contentKey,
    required this.color,
  });

  final List<MapEntry<int, int>> backEdges;
  final Map<int, GlobalKey> nodeKeys;
  final GlobalKey contentKey;
  final Color color;

  // helpers удалены (не используются)

  @override
  void paint(Canvas canvas, Size size) {
    final contentCtx = contentKey.currentContext;
    if (contentCtx == null) return;
    final contentBox = contentCtx.findRenderObject() as RenderBox?;
    if (contentBox == null || !contentBox.hasSize) return;

    final edgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Rect? _nodeRect(GlobalKey key) {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: contentBox);
      return topLeft & box.size;
    }

    // Общие границы графа и список прямоугольников нод (для детектора маршрута)
    Rect? allBounds;
    final List<Rect> allNodeRects = [];
    for (final key in nodeKeys.values) {
      final r = _nodeRect(key);
      if (r == null) continue;
      allBounds = allBounds == null ? r : allBounds.expandToInclude(r);
      allNodeRects.add(r);
    }
    final double routeX = (allBounds?.right ?? 0) + 20.0;
    const double cornerRBase = 0;

    // Предрасчёт осей для вертикальных участков, чтобы параллельные рёбра не накладывались:
    // группируем по базовой оси (для правых обходов это routeX, для крайних правых таргетов — right+20),
    // сортируем по высоте источника и смещаем каждое следующее на +20px вправо
    final Map<String, double> axisXForEdge = {};
    final List<Map<String, dynamic>> items = [];
    for (final e in backEdges) {
      final fromKey = nodeKeys[e.key];
      final toKey = nodeKeys[e.value];
      if (fromKey == null || toKey == null) continue;
      final fromRect = _nodeRect(fromKey);
      final toRect = _nodeRect(toKey);
      if (fromRect == null || toRect == null) continue;
      final double xRight = toRect.right;
      final bool isRightmostTarget = xRight >= ((allBounds?.right ?? xRight) - 0.5);
      final double baseX = isRightmostTarget ? (xRight + 20.0) : routeX;
      final String edgeKey = '${e.key}->${e.value}';
      items.add({
        'key': edgeKey,
        'baseX': baseX,
        'p0y': fromRect.center.dy,
      });
    }
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final it in items) {
      final String gk = (it['baseX'] as double).toStringAsFixed(1);
      (groups[gk] ??= []).add(it);
    }
    for (final entry in groups.entries) {
      final list = entry.value;
      list.sort((a, b) => (a['p0y'] as double).compareTo(b['p0y'] as double));
      for (var i = 0; i < list.length; i++) {
        final double base = list[i]['baseX'] as double;
        axisXForEdge[list[i]['key'] as String] = base + 20.0 * i;
      }
    }

    // Отрисовка всех back-edges выбранными маршрутами
    for (final e in backEdges) {
      final fromKey = nodeKeys[e.key];
      final toKey = nodeKeys[e.value];
      if (fromKey == null || toKey == null) continue;
      final fromRect = _nodeRect(fromKey);
      final toRect = _nodeRect(toKey);
      if (fromRect == null || toRect == null) continue;

      final route = detectBackEdgeRoute(
        fromRect: fromRect,
        toRect: toRect,
        allBounds: allBounds,
        nodeRects: allNodeRects,
      );
      if (route == BackEdgeRoute.sideBySide) {
        drawBackEdgeSideBySide(
          canvas: canvas,
          edgePaint: edgePaint,
          fromRect: fromRect,
          toRect: toRect,
          color: color,
        );
        continue;
      } else if (route == BackEdgeRoute.sideBySideLeft) {
        drawBackEdgeSideBySideLeft(
          canvas: canvas,
          edgePaint: edgePaint,
          fromRect: fromRect,
          toRect: toRect,
          color: color,
        );
        continue;
      } else if (route == BackEdgeRoute.topRightBypass) {
        drawBackEdgeTopRightBypass(
          canvas: canvas,
          edgePaint: edgePaint,
          fromRect: fromRect,
          toRect: toRect,
          color: color,
          allBounds: allBounds,
          nodeRects: allNodeRects,
        );
        continue;
      } else {
        // По умолчанию — обход через верх и вправо (topRightBypass)
        drawBackEdgeTopRightBypass(
          canvas: canvas,
          edgePaint: edgePaint,
          fromRect: fromRect,
          toRect: toRect,
          color: color,
          allBounds: allBounds,
          nodeRects: allNodeRects,
        );
        continue;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackEdgesPainter oldDelegate) {
    if (identical(backEdges, oldDelegate.backEdges) &&
        identical(nodeKeys, oldDelegate.nodeKeys) &&
        color == oldDelegate.color) {
      return false;
    }
    return true;
  }
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
    // Слушаем изменения бизнес-состояния (steps): при любом апдейте пересобираем/рефитим граф
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listen(dialogsConfigControllerProvider, (prev, next) {
        if (!mounted) return;
        // Если список шагов изменился (по длине или ссылке) — сбрасываем автофит
        final prevLen = prev?.steps.length ?? -1;
        final nextLen = next.steps.length;
        if (identical(prev?.steps, next.steps) && prevLen == nextLen) return;
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
    // Берём текущее имя/описание из бизнес-состояния
    final cfg = ref.read(dialogsConfigControllerProvider);
    final nameCtrl = TextEditingController(text: cfg.name);
    final descCtrl = TextEditingController(text: cfg.description);
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
              await ref
                  .read(dialogsConfigControllerProvider.notifier)
                  .updateNameDescription(
                    nameCtrl.text.trim(),
                    descCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );

    if (saved == true) {
      // Обновим список вкладок, чтобы заголовок отобразился с новым именем
      ref.invalidate(dialogConfigsProvider);
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
    // Строим граф сверху-вниз всегда (Sugiyama). Если есть циклы — исключаем обратные рёбра
    final cfg = ref.watch(dialogsConfigControllerProvider);
    final style = GraphStyle.sugiyamaTopBottom(
      nodeSeparation: 20,
      levelSeparation: 80,
    );
    final builder = DialogsGraphBuilder(style: style);
    final bool cyclic = hasDialogCycles(cfg.steps);
    Graph graph;
    List<MapEntry<int, int>> backEdges = const [];
    if (cyclic) {
      backEdges = selectEdgesToOmit(cfg.steps);
      final omit = backEdges.map((e) => '${e.key}->${e.value}').toSet();
      graph = builder.buildFiltered(cfg.steps, omitEdges: omit);
    } else {
      graph = builder.build(cfg.steps);
    }
    if (backEdges.isNotEmpty) {
      AppLogger.d(
        '[TreePanel] omitEdges=${backEdges.map((e) => '${e.key}->${e.value}').join(', ')}',
        tag: 'DialogsTree',
      );
    }
    final Algorithm algorithm = style.buildAlgorithm();
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
          final hasSteps = cfg.steps.isNotEmpty;
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
                  interactive: true,
                  foregroundPainter: backEdges.isNotEmpty
                      ? _BackEdgesPainter(
                          backEdges: backEdges,
                          nodeKeys: _nodeKeys,
                          contentKey: _contentKey,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  nodeBuilder: (Node n) {
                    final id = n.key!.value as int;
                    final step = cfg.steps.firstWhere((e) => e.id == id);
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
                          onDelete: () async {
                            final steps = ref
                                .read(dialogsConfigControllerProvider)
                                .steps;
                            if (steps.length == 1) {
                              // Диалог состоит из одного шага: подтверждение удаления всего диалога
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Удалить диалог?'),
                                  content: const Text(
                                    'В диалоге только один шаг. Будет удалён ВЕСЬ диалог. Действие необратимо.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Отмена'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Удалить диалог'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ref
                                    .read(
                                      dialogsConfigControllerProvider.notifier,
                                    )
                                    .deleteDialog();
                                // Обновим список вкладок и сбросим выбранный id
                                ref.invalidate(dialogConfigsProvider);
                                ref
                                        .read(
                                          selectedDialogConfigIdProvider
                                              .notifier,
                                        )
                                        .state =
                                    null;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Диалог удалён'),
                                    ),
                                  );
                                }
                              }
                              return;
                            }

                            // Обычное удаление шага
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Удалить шаг?'),
                                content: Text(
                                  'Шаг #$id будет удалён. Все переходы на этот шаг будут очищены.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Отмена'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Удалить шаг'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              // Удаляем через бизнес-контроллер и сохраняем с дебаунсом
                              ref
                                  .read(
                                    dialogsConfigControllerProvider.notifier,
                                  )
                                  .deleteStep(id);
                              ref
                                  .read(
                                    dialogsConfigControllerProvider.notifier,
                                  )
                                  .saveFullDebounced();
                              // Сброс автофита
                              setState(() {
                                _didAutoFit = false;
                                _lastViewportSize = null;
                              });
                            }
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
                    onRefreshPressed: () async {
                      final selectedId = ref.read(
                        selectedDialogConfigIdProvider,
                      );
                      if (selectedId != null) {
                        ref.invalidate(dialogConfigDetailsProvider(selectedId));
                        // Дополнительно синхронизируем бизнес-состояние с бэкендом
                        await ref
                            .read(dialogsConfigControllerProvider.notifier)
                            .loadDetails(selectedId);
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
                            .read(dialogsConfigControllerProvider)
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
                            .read(dialogsConfigControllerProvider)
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

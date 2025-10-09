import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_node.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_toolbar_panel.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_props.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';
// import 'package:sentralix_app/features/assistant/features/dialogs/utils/graph_cycles.dart';
// back-edges отрисовка больше не используется в центрированной раскладке
import 'package:sentralix_app/features/assistant/features/dialogs/graph/centered_layered_layout.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_centered_canvas.dart';

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
  int? _lastFittedStepsCount;
  bool _userInteracted = false; // Пользователь двигал/масштабировал граф
  bool _isProgrammaticTransform =
      false; // Внутреннее изменение матрицы (не считать за взаимодействие)

  // Данные центрированной раскладки
  CenteredLayoutResult? _lastComputedLayout;
  Size _nodeSize = const Size(240, 120);

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
      // При смене выбранного сценария — также сбрасываем автофит, чтобы вписать новый граф
      ref.listen(selectedDialogConfigIdProvider, (prev, next) {
        if (!mounted) return;
        setState(() {
          _didAutoFit = false;
          _lastViewportSize = null;
          _lastFittedStepsCount = null;
          _userInteracted = false;
        });
      });
    });
  }

  void _onTcChanged() {
    if (!mounted) return;
    // Если это пользовательское изменение матрицы — фиксируем факт взаимодействия
    if (!_isProgrammaticTransform) {
      _userInteracted = true;
    }
    // Обновляем UI (например, положение слайдера)
    setState(() {});
  }

  @override
  void dispose() {
    _tc.removeListener(_onTcChanged);
    _tc.dispose();
    super.dispose();
  }

  /// Открыть модалку настроек сценария (редактирование имени и описания)
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
        title: const Text('Настройки сценария'),
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
                  labelText: 'Описание сценария (необязательно)',
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
    // В новой раскладке считаем границы логически из координат layout
    if (_lastComputedLayout == null) return null;
    final layout = _lastComputedLayout!;
    Rect? bounds;
    layout.positions.forEach((_, pos) {
      final rect = pos & _nodeSize;
      bounds = bounds == null ? rect : bounds!.expandToInclude(rect);
    });
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

    _isProgrammaticTransform = true;
    setState(() {
      _tc.value = Matrix4.identity()
        ..translateByVector3(vm.Vector3(tx, ty, 0))
        ..scaleByVector3(vm.Vector3(scale, scale, 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isProgrammaticTransform = false;
    });
  }

  void _fitAndCenter(Size viewportSize, {bool force = false}) {
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

    if (force || !_userInteracted) {
      _isProgrammaticTransform = true;
      setState(() {
        _tc.value = Matrix4.identity()
          ..translateByVector3(vm.Vector3(tx, ty, 0))
          ..scaleByVector3(vm.Vector3(targetScale, targetScale, 1));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isProgrammaticTransform = false;
      });
    }
    // Зафиксируем, что автофит выполнен для текущего состояния
    _didAutoFit = true;
    _lastViewportSize = viewportSize;
    _lastFittedStepsCount = ref
        .read(dialogsConfigControllerProvider)
        .steps
        .length;
  }

  void _centerOnNode(int id) {
    if (_userInteracted) return;
    final nodeKey = _nodeKeys[id];
    if (nodeKey == null) {
      return;
    }
    final nodeCtx = nodeKey.currentContext;
    final contentCtx = _contentKey.currentContext;
    if (nodeCtx == null || contentCtx == null) {
      return;
    }

    final nodeBox = nodeCtx.findRenderObject() as RenderBox?;
    final contentBox = contentCtx.findRenderObject() as RenderBox?;
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (nodeBox == null || contentBox == null || viewportBox == null) {
      return;
    }
    if (!nodeBox.hasSize || !contentBox.hasSize || !viewportBox.hasSize) {
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

    _isProgrammaticTransform = true;
    setState(() {
      _tc.value = Matrix4.identity()
        ..translateByVector3(vm.Vector3(tx, ty, 0))
        ..scaleByVector3(vm.Vector3(currentScale, currentScale, 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isProgrammaticTransform = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Центрированная построчная раскладка (наш алгоритм)
    final cfg = ref.watch(dialogsConfigControllerProvider);
    // Размер ноды подгоняем под StepNode (увеличена высота для избежания overflow)
    const nodeSize = Size(240, 180);
    final centered = computeCenteredLayout(
      cfg.steps,
      nodeSize: nodeSize,
      nodeSeparation: 32,
      levelSeparation: 120,
      padding: 80,
    );
    _lastComputedLayout = centered;
    _nodeSize = nodeSize;
    final editor = ref.watch(dialogsEditorControllerProvider);
    // Чистим ключи старых нод, которых нет в текущем сценарии
    final currentIds = cfg.steps.map((e) => e.id).toSet();
    _nodeKeys.removeWhere((id, key) => !currentIds.contains(id));

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
            // Опираемся на рассчитанный размерами layout, чтобы избежать измерений RenderBox
            final layout = _lastComputedLayout;
            final proposed = layout == null
                ? viewportSize
                : Size(
                    math.max(layout.canvasSize.width + pad, viewportSize.width),
                    math.max(layout.canvasSize.height + pad, viewportSize.height),
                  );
            if ((_canvasSize.width - proposed.width).abs() > 1 ||
                (_canvasSize.height - proposed.height).abs() > 1) {
              if (mounted) setState(() => _canvasSize = proposed);
            }
            // Гарантированный запуск вписывания после пересчёта размеров (только до взаимодействия пользователя)
            final stepsCount = cfg.steps.length;
            if (cfg.steps.isNotEmpty &&
                !_userInteracted &&
                (!_didAutoFit || _lastFittedStepsCount != stepsCount)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitAndCenter(viewportSize);
              });
            }
          });
          final hasSteps = cfg.steps.isNotEmpty;
          final sizeChanged =
              _lastViewportSize == null ||
              (viewportSize.width - (_lastViewportSize!.width)).abs() > 8 ||
              (viewportSize.height - (_lastViewportSize!.height)).abs() > 8;
          if (hasSteps &&
              !_userInteracted &&
              (!_didAutoFit || sizeChanged || _lastFittedStepsCount != cfg.steps.length)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitAndCenter(viewportSize);
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
                DialogsCenteredCanvas(
                  layout: centered,
                  nodeSize: nodeSize,
                  transformationController: _tc,
                  contentKey: _contentKey,
                  buildNode: (int id, Key? _) {
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _centerOnNode(newId);
                            });
                          },
                          onSettings: () async {
                            ref
                                .read(dialogsEditorControllerProvider.notifier)
                                .selectStep(id);
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
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Удалить сценарий?'),
                                  content: const Text(
                                    'В сценарии только один шаг. Будет удалён ВЕСЬ сценарий. Действие необратимо.',
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
                                      child: const Text('Удалить сценарий'),
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
                                      content: Text('Сценарий удалён'),
                                    ),
                                  );
                                }
                              }
                              return;
                            }

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
                        _fitAndCenter(viewportSize, force: true);
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
                        _lastFittedStepsCount = null;
                        _userInteracted =
                            false; // разрешаем авто/принудительный фит после обновления
                      });
                      // Принудительное вписывание после обновления
                      final ctx = context; // сохранить BuildContext
                      if (!ctx.mounted) return;
                      final rb = ctx.findRenderObject() as RenderBox?;
                      if (rb != null && rb.hasSize) {
                        final viewportSize = rb.size;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!ctx.mounted) return;
                          _fitAndCenter(viewportSize, force: true);
                        });
                      }
                    },
                    onAddPressed: () {
                      final editorState = ref.read(
                        dialogsEditorControllerProvider,
                      );
                      final notifier = ref.read(
                        dialogsEditorControllerProvider.notifier,
                      );
                      int newId;
                      if (editorState.selectedStepId != null) {
                        newId = notifier.addNextStep(
                          editorState.selectedStepId!,
                        );
                        // обновление произойдёт через провайдер
                      } else {
                        notifier.addStep();
                        final steps = ref
                            .read(dialogsConfigControllerProvider)
                            .steps;
                        if (steps.isEmpty) return;
                        newId = steps
                            .map((e) => e.id)
                            .reduce((a, b) => a > b ? a : b);
                      }
                      // Перейдём камерой к новому узлу после кадра
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _centerOnNode(newId);
                        }
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

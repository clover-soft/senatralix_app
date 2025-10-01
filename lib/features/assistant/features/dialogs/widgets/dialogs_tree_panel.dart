import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_tree_canvas.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_node.dart';

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

  void _fitAndCenter(Size viewportSize) {
    // Получаем размер контента (GraphView внутри RepaintBoundary)
    final ctx = _contentKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final contentSize = box.size;
    if (contentSize.width <= 0 || contentSize.height <= 0) return;

    // Рассчитываем масштаб, чтобы вписать оба измерения
    final scaleX = viewportSize.width / contentSize.width;
    final scaleY = viewportSize.height / contentSize.height;
    // Чуть уменьшим, чтобы не прилипало к краям
    final targetScale = (scaleX < scaleY ? scaleX : scaleY) * 0.95;

    // Рассчитываем смещения для центрирования
    final scaledW = contentSize.width * targetScale;
    final scaledH = contentSize.height * targetScale;
    final dx = (viewportSize.width - scaledW) / 2;
    final dy = (viewportSize.height - scaledH) / 2;

    setState(() {
      _tc.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    });
  }

  void _centerOnNode(int id) {
    final nodeKey = _nodeKeys[id];
    if (nodeKey == null) return;
    final nodeCtx = nodeKey.currentContext;
    final contentCtx = _contentKey.currentContext;
    if (nodeCtx == null || contentCtx == null) return;

    final nodeBox = nodeCtx.findRenderObject() as RenderBox?;
    final contentBox = contentCtx.findRenderObject() as RenderBox?;
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (nodeBox == null || contentBox == null || viewportBox == null) return;
    if (!nodeBox.hasSize || !contentBox.hasSize || !viewportBox.hasSize) return;

    // Координаты ноды в системе контента (до трансформации)
    final nodeTopLeft = nodeBox.localToGlobal(
      Offset.zero,
      ancestor: contentBox,
    );
    final nodeSize = nodeBox.size;
    final nodeCenter =
        nodeTopLeft + Offset(nodeSize.width / 2, nodeSize.height / 2);

    // Текущий масштаб
    final currentScale = _tc.value.getMaxScaleOnAxis();
    final viewportSize = viewportBox.size;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    // Хотим: nodeCenter * scale + translate = viewportCenter
    final tx = viewportCenter.dx - nodeCenter.dx * currentScale;
    final ty = viewportCenter.dy - nodeCenter.dy * currentScale;

    setState(() {
      _tc.value = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(currentScale);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Верхняя панель управления холстом
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Text('Граф', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Tooltip(
                message: 'Вписать и центрировать',
                child: Builder(
                  builder: (toolbarCtx) => IconButton(
                    icon: const Icon(Icons.center_focus_strong),
                    onPressed: () {
                      // Получаем фактический размер доступной области под холст
                      final renderBox =
                          context.findRenderObject() as RenderBox?;
                      if (renderBox == null || !renderBox.hasSize) return;
                      // Высота панели инструментов уже вычтена, т.к. мы ниже в Expanded
                      final viewportSize = renderBox.size;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _fitAndCenter(viewportSize);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Холст (с обрезкой по рамке панели)
        Expanded(
          child: ClipRect(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
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
                          veilOpacity:
                              Theme.of(context).brightness == Brightness.dark
                              ? 0.4
                              : 0.5,
                        ),
                      ),
                      // Сам холст с графом
                      DialogsTreeCanvas(
                        graph: graph,
                        algorithm: algorithm,
                        transformationController: _tc,
                        contentKey: _contentKey,
                        nodeBuilder: (Node n) {
                          final id = n.key!.value as int;
                          final step = editor.steps.firstWhere(
                            (e) => e.id == id,
                          );
                          final isSelected =
                              editor.selectedStepId == id ||
                              editor.linkStartStepId == id;
                          final key = _nodeKeys.putIfAbsent(
                            id,
                            () => GlobalKey(),
                          );
                          return Material(
                            key: key,
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => ref
                                  .read(
                                    dialogsEditorControllerProvider.notifier,
                                  )
                                  .onNodeTap(id),
                              onDoubleTap: () => _centerOnNode(id),
                              child: StepNode(step: step, selected: isSelected),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
  });

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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';

// Тип идентификатора ноды (шага)
typedef NodeId = int;

enum DndActivation { immediate, longPress }

typedef CanSwap = FutureOr<bool> Function(NodeId draggedId, NodeId targetId);
typedef OnSwap = Future<void> Function(NodeId a, NodeId b);
typedef FeedbackBuilder = Widget Function(BuildContext context, Widget child);
typedef HoverDecorator =
    Widget Function(
      BuildContext context,
      Widget child,
      bool isHovered,
      bool isTargeted,
    );

class NodeDndConfig {
  final DndActivation activation;
  final Duration longPressDelay;
  final double draggedOpacity;
  final FeedbackBuilder? feedbackBuilder;
  final HoverDecorator? hoverDecorator;
  final CanSwap? canSwap;
  final OnSwap? onSwapCompleted;
  final bool optimistic;

  const NodeDndConfig({
    this.activation = DndActivation.longPress,
    this.longPressDelay = const Duration(milliseconds: 180),
    this.draggedOpacity = 0.72,
    this.feedbackBuilder,
    this.hoverDecorator,
    this.canSwap,
    this.onSwapCompleted,
    this.optimistic = true,
  });
}

abstract class NodeSwapRepository {
  Future<void> swapNodeIds(NodeId a, NodeId b);
}

/// Репозиторий по умолчанию: выполняет атомарную перестановку id (A <-> B)
/// в состоянии провайдера `dialogsConfigControllerProvider` с заменой всех ссылок.
class ProviderNodeSwapRepository implements NodeSwapRepository {
  ProviderNodeSwapRepository(this._ref);
  final WidgetRef _ref;

  @override
  Future<void> swapNodeIds(NodeId a, NodeId b) async {
    final ctrl = _ref.read(dialogsConfigControllerProvider.notifier);
    final state = _ref.read(dialogsConfigControllerProvider);
    final steps = List<DialogStep>.from(state.steps);
    if (steps.isEmpty || a == b) return;

    final swapped = _swapIdsAndReferences(steps, a, b);
    ctrl.updateSteps(swapped);
    ctrl.saveFullDebounced();
  }

  static List<DialogStep> _swapIdsAndReferences(
    List<DialogStep> steps,
    int a,
    int b,
  ) {
    // Перестановка id двух шагов и всех ссылок на них: fields id, next, branchLogic values
    DialogStep mapStep(DialogStep s) {
      final newId = s.id == a ? b : (s.id == b ? a : s.id);
      final newNext = s.next == null
          ? null
          : (s.next == a ? b : (s.next == b ? a : s.next));

      // branch_logic: Map<String, Map<String, int>> — заменяем только значения (id шагов)
      final Map<String, Map<String, int>> newBranch = {};
      s.branchLogic.forEach((slotKey, mapping) {
        final mapped = <String, int>{};
        mapping.forEach((k, v) {
          final nv = v == a ? b : (v == b ? a : v);
          mapped[k] = nv;
        });
        newBranch[slotKey] = mapped;
      });

      return DialogStep(
        id: newId,
        name: s.name,
        label: s.label,
        instructions: s.instructions,
        requiredSlotsIds: s.requiredSlotsIds,
        optionalSlotsIds: s.optionalSlotsIds,
        next: newNext,
        branchLogic: newBranch,
        onEnter: s.onEnter,
        onExit: s.onExit,
      );
    }

    return steps.map(mapStep).toList(growable: false);
  }
}

class NodeDndController extends ChangeNotifier {
  NodeDndController({
    required this.repository,
    this.config = const NodeDndConfig(),
  });

  final NodeDndConfig config;
  final NodeSwapRepository repository;

  NodeId? _draggedId;
  NodeId? _hoveredTargetId;
  bool get isDragging => _draggedId != null;
  NodeId? get activeDraggedId => _draggedId;
  NodeId? get hoveredTargetId => _hoveredTargetId;

  void startDrag(NodeId id) {
    _draggedId = id;
    notifyListeners();
  }

  Future<void> endDrag() async {
    _draggedId = null;
    _hoveredTargetId = null;
    notifyListeners();
  }

  void setHover(NodeId? id) {
    if (_hoveredTargetId == id) return;
    _hoveredTargetId = id;
    notifyListeners();
  }

  Future<void> performSwap(NodeId a, NodeId b) async {
    if (a == b) return;
    if (config.canSwap != null) {
      final ok = await config.canSwap!(a, b);
      if (!ok) return;
    }
    // Выполним swap через репозиторий
    await repository.swapNodeIds(a, b);
    if (config.onSwapCompleted != null) {
      await config.onSwapCompleted!(a, b);
    }
  }
}

class NodeDndScope extends InheritedWidget {
  const NodeDndScope({
    super.key,
    required this.controller,
    required this.config,
    required super.child,
  });

  final NodeDndController controller;
  final NodeDndConfig config;

  static NodeDndScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NodeDndScope>();
    assert(scope != null, 'NodeDndScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(NodeDndScope oldWidget) {
    return controller != oldWidget.controller || config != oldWidget.config;
  }
}

class NodeDndWrapper extends StatelessWidget {
  const NodeDndWrapper({
    super.key,
    required this.controller,
    required this.child,
  });
  final NodeDndController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NodeDndScope(
      controller: controller,
      config: controller.config,
      child: AnimatedBuilder(animation: controller, builder: (_, __) => child),
    );
  }
}

class NodeDraggable extends StatelessWidget {
  const NodeDraggable({super.key, required this.nodeId, required this.child});
  final NodeId nodeId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = NodeDndScope.of(context);
    final ctrl = scope.controller;
    final activation = scope.config.activation;
    final feedbackBuilder = scope.config.feedbackBuilder;

    Widget wrapped = Opacity(
      opacity: ctrl.activeDraggedId == nodeId ? 0.4 : 1.0,
      child: child,
    );

    Widget dragWidget = Draggable<NodeId>(
      data: nodeId,
      feedback:
          feedbackBuilder?.call(context, child) ??
          Material(
            color: Colors.transparent,
            child: Opacity(opacity: scope.config.draggedOpacity, child: child),
          ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      onDragStarted: () => ctrl.startDrag(nodeId),
      onDraggableCanceled: (_, __) => ctrl.endDrag(),
      onDragEnd: (_) => ctrl.endDrag(),
      dragAnchorStrategy: childDragAnchorStrategy,
      child: wrapped,
    );

    switch (activation) {
      case DndActivation.immediate:
        return dragWidget;
      case DndActivation.longPress:
        return LongPressDraggable<NodeId>(
          data: nodeId,
          delay: scope.config.longPressDelay,
          feedback:
              feedbackBuilder?.call(context, child) ??
              Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: scope.config.draggedOpacity,
                  child: child,
                ),
              ),
          childWhenDragging: Opacity(opacity: 0.35, child: child),
          onDragStarted: () => ctrl.startDrag(nodeId),
          onDragEnd: (_) => ctrl.endDrag(),
          onDraggableCanceled: (_, __) => ctrl.endDrag(),
          child: wrapped,
        );
    }
  }
}

class NodeDropTarget extends StatelessWidget {
  const NodeDropTarget({super.key, required this.nodeId, required this.child});
  final NodeId nodeId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = NodeDndScope.of(context);
    final ctrl = scope.controller;

    final decorated = MouseRegion(
      onEnter: (_) => ctrl.setHover(nodeId),
      onExit: (_) => ctrl.setHover(null),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (ctx, _) {
          final isHovered = ctrl.hoveredTargetId == nodeId;
          final isTargeted =
              ctrl.isDragging && ctrl.activeDraggedId != nodeId && isHovered;
          final content =
              scope.config.hoverDecorator?.call(
                ctx,
                child,
                isHovered,
                isTargeted,
              ) ??
              child;
          return content;
        },
      ),
    );

    return DragTarget<NodeId>(
      onWillAcceptWithDetails: (details) {
        if (details.data == nodeId) return false;
        return true;
      },
      onAcceptWithDetails: (details) async {
        // Полная проверка прав/логики перенесена сюда (может быть async)
        await ctrl.performSwap(details.data, nodeId);
      },
      builder: (ctx, cand, rej) {
        return decorated;
      },
    );
  }
}

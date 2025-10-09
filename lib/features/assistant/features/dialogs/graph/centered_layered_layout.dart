import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

class CenteredLayoutResult {
  final Map<int, Offset> positions; // stepId -> top-left position
  final List<MapEntry<int, int>> nextEdges;
  final List<MapEntry<int, int>> branchEdges;
  final Size canvasSize;

  const CenteredLayoutResult({
    required this.positions,
    required this.nextEdges,
    required this.branchEdges,
    required this.canvasSize,
  });
}

/// Вычисляет уровни и координаты для центрированной построчной раскладки.
CenteredLayoutResult computeCenteredLayout(
  List<DialogStep> steps, {
  Size nodeSize = const Size(240, 120),
  double nodeSeparation = 32,
  double levelSeparation = 120,
  double padding = 80,
}) {
  if (steps.isEmpty) {
    return const CenteredLayoutResult(
      positions: {},
      nextEdges: [],
      branchEdges: [],
      canvasSize: Size.zero,
    );
  }

  // Индексы
  final byId = {for (final s in steps) s.id: s};

  // Родители: кто ссылается на кого
  final parents = <int, Set<int>>{for (final s in steps) s.id: <int>{}};
  for (final s in steps) {
    if (s.next != null && s.next! > 0 && byId.containsKey(s.next)) {
      parents[s.next!]!.add(s.id);
    }
    for (final mapping in s.branchLogic.values) {
      for (final toId in mapping.values) {
        if (toId > 0 && byId.containsKey(toId)) {
          parents[toId]!.add(s.id);
        }
      }
    }
  }

  // Корни: шаги без родителей
  final roots = steps.where((s) => parents[s.id]!.isEmpty).map((e) => e.id).toList();
  if (roots.isEmpty) {
    // На случай циклов без явного корня: возьмём минимальный id как корень
    roots.add(steps.map((e) => e.id).reduce(math.min));
  }

  // Уровни: BFS с правилом level = 1 + max(parent.level)
  final level = <int, int>{};
  final q = Queue<int>();
  for (final r in roots) {
    level[r] = 0;
    q.add(r);
  }
  while (q.isNotEmpty) {
    final v = q.removeFirst();
    final s = byId[v]!;
    // Дети по next
    final children = <int>[];
    if (s.next != null && s.next! > 0 && byId.containsKey(s.next)) {
      children.add(s.next!);
    }
    // Дети по branch
    for (final mapping in s.branchLogic.values) {
      for (final toId in mapping.values) {
        if (toId > 0 && byId.containsKey(toId)) children.add(toId);
      }
    }
    for (final u in children.toSet()) {
      final parentLevel = level[v] ?? 0;
      // Назначаем уровень только один раз, чтобы избежать бесконечного повышения на циклах
      if (!level.containsKey(u)) {
        level[u] = parentLevel + 1;
        q.add(u);
      }
    }
  }
  // Невышедшие узлы (в циклах) — положим на нижний уровень
  final maxAssigned = level.values.isEmpty ? 0 : level.values.reduce(math.max);
  for (final s in steps) {
    level.putIfAbsent(s.id, () => maxAssigned);
  }

  // Группировка по уровням
  final Map<int, List<int>> byLevel = {};
  for (final e in level.entries) {
    (byLevel[e.value] ??= <int>[]).add(e.key);
  }
  final sortedLevels = byLevel.keys.toList()..sort();
  for (final l in sortedLevels) {
    byLevel[l]!.sort();
  }

  // Рассчёт ширины каждого уровня и центрирование относительно общей ширины
  // Возьмём максимальную ширину уровня и от неё центрируем остальные
  double levelMaxWidth = 0;
  final levelWidths = <int, double>{};
  for (final l in sortedLevels) {
    final n = byLevel[l]!.length;
    final width = n * nodeSize.width + (n - 1) * nodeSeparation;
    levelWidths[l] = width;
    if (width > levelMaxWidth) levelMaxWidth = width;
  }

  // Итоговые позиции
  final positions = <int, Offset>{};
  for (final l in sortedLevels) {
    final nodes = byLevel[l]!;
    final currentWidth = levelWidths[l]!;
    final startX = (levelMaxWidth - currentWidth) / 2; // центрируем ряд
    final y = padding + l * (nodeSize.height + levelSeparation);
    for (int i = 0; i < nodes.length; i++) {
      final x = padding + startX + i * (nodeSize.width + nodeSeparation);
      positions[nodes[i]] = Offset(x, y);
    }
  }

  // Рёбра
  final nextEdges = <MapEntry<int, int>>[];
  final branchEdges = <MapEntry<int, int>>[];
  for (final s in steps) {
    if (s.next != null && s.next! > 0 && byId.containsKey(s.next)) {
      nextEdges.add(MapEntry(s.id, s.next!));
    }
    for (final mapping in s.branchLogic.values) {
      for (final toId in mapping.values) {
        if (toId > 0 && byId.containsKey(toId)) {
          branchEdges.add(MapEntry(s.id, toId));
        }
      }
    }
  }

  // Размер холста
  final right = positions.values.map((o) => o.dx + nodeSize.width).fold<double>(0, math.max);
  final bottom = positions.values.map((o) => o.dy + nodeSize.height).fold<double>(0, math.max);
  final canvasSize = Size(right + padding, bottom + padding);

  return CenteredLayoutResult(
    positions: positions,
    nextEdges: nextEdges,
    branchEdges: branchEdges,
    canvasSize: canvasSize,
  );
}

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

  // Корни: шаги без родителей (начальный набор)
  final roots = steps
      .where((s) => parents[s.id]!.isEmpty)
      .map((e) => e.id)
      .toList();
  if (roots.isEmpty) {
    // На случай, если вообще нет узлов без родителей, начнём с минимального id
    roots.add(steps.map((e) => e.id).reduce(math.min));
  }

  // Рёбра (для вычисления уровней/порядка)
  final outgoing = <int, Set<int>>{for (final s in steps) s.id: <int>{}};
  for (final s in steps) {
    if (s.next != null && s.next! > 0 && byId.containsKey(s.next)) {
      outgoing[s.id]!.add(s.next!);
    }
    for (final mapping in s.branchLogic.values) {
      for (final toId in mapping.values) {
        if (toId > 0 && byId.containsKey(toId)) {
          outgoing[s.id]!.add(toId);
        }
      }
    }
  }

  // Расширим набор корней по компонентам: добавим корень для каждой недостижимой компоненты
  {
    final allIds = steps.map((e) => e.id).toSet();
    final reachable = <int>{};
    void dfs(int v) {
      if (!reachable.add(v)) return;
      final outs = outgoing[v];
      if (outs == null) return;
      for (final u in outs) {
        dfs(u);
      }
    }

    for (final r in roots) {
      dfs(r);
    }
    var remaining = allIds.difference(reachable);
    while (remaining.isNotEmpty) {
      final extraRoot = remaining.reduce((a, b) => a < b ? a : b);
      roots.add(extraRoot);
      dfs(extraRoot);
      remaining = allIds.difference(reachable);
    }
  }

  // Уровни: итеративная релаксация по правилу level(u) = 1 + max(level(parent))
  final level = <int, int>{};
  for (final r in roots) {
    level[r] = 0;
  }
  // До N итераций пытаемся проставить уровни, пока есть прогресс
  final nodeIds = steps.map((e) => e.id).toList();
  for (int iter = 0; iter < nodeIds.length; iter++) {
    bool changed = false;
    for (final u in nodeIds) {
      final ps = parents[u] ?? const <int>{};
      if (ps.isEmpty) {
        // корень уже установлен в 0
        continue;
      }
      int? maxParent;
      for (final p in ps) {
        final lp = level[p];
        if (lp != null) {
          maxParent = (maxParent == null) ? lp : math.max(maxParent, lp);
        }
      }
      if (maxParent != null) {
        final cand = maxParent + 1;
        final prev = level[u];
        if (prev == null || cand > prev) {
          level[u] = cand;
          changed = true;
        }
      }
    }
    if (!changed) break;
  }
  // Узлы, оставшиеся без уровня (жёсткие циклы): положим на нижний из уже назначенных + 1
  final currentMax = level.isEmpty ? 0 : level.values.reduce(math.max);
  for (final s in steps) {
    level.putIfAbsent(s.id, () => currentMax + 1);
  }

  // Обратная релаксация (сжатие длинных рёбер): гарантируем, что parent расположен максимально близко к детям
  // level[parent] = max(level[parent], level[child] - 1)
  for (int iter = 0; iter < steps.length; iter++) {
    bool changed = false;
    for (final s in steps) {
      final p = s.id;
      final lp = level[p]!;
      // next
      if (s.next != null && s.next! > 0 && level.containsKey(s.next)) {
        final lc = level[s.next!]!;
        final cand = lc - 1;
        if (cand > lp) {
          level[p] = cand;
          changed = true;
        }
      }
      // branches
      for (final mapping in s.branchLogic.values) {
        for (final toId in mapping.values) {
          if (toId > 0 && level.containsKey(toId)) {
            final lc = level[toId]!;
            final cand = lc - 1;
            if (cand > level[p]!) {
              level[p] = cand;
              changed = true;
            }
          }
        }
      }
    }
    if (!changed) break;
  }

  // Группировка по уровням
  final Map<int, List<int>> byLevel = {};
  for (final e in level.entries) {
    (byLevel[e.value] ??= <int>[]).add(e.key);
  }
  final sortedLevels = byLevel.keys.toList()..sort();
  // Базовая сортировка по id
  for (final l in sortedLevels) {
    byLevel[l]!.sort();
  }

  // Барицентрическая сортировка сверху-вниз: для каждого уровня l>0
  // сортируем по среднему индексу родителей на уровне l-1
  final orderIndex = <int, Map<int, int>>{}; // level -> (nodeId -> index)
  for (final l in sortedLevels) {
    final nodes = byLevel[l]!;
    // Индексы текущего уровня (до пересортировки)
    final idxMap = <int, int>{};
    for (int i = 0; i < nodes.length; i++) {
      idxMap[nodes[i]] = i;
    }
    orderIndex[l] = idxMap;
  }
  for (int i = 1; i < sortedLevels.length; i++) {
    final l = sortedLevels[i];
    final prev = sortedLevels[i - 1];
    final prevOrder = orderIndex[prev]!; // nodeId -> index
    final nodes = byLevel[l]!;
    nodes.sort((a, b) {
      double baryA;
      final pa = parents[a];
      if (pa == null || pa.isEmpty) {
        baryA = orderIndex[l]![a]!.toDouble();
      } else {
        final indices = pa
            .where((p) => prevOrder.containsKey(p))
            .map((p) => prevOrder[p]!.toDouble())
            .toList();
        baryA = indices.isEmpty
            ? orderIndex[l]![a]!.toDouble()
            : (indices.reduce((x, y) => x + y) / indices.length);
      }

      double baryB;
      final pb = parents[b];
      if (pb == null || pb.isEmpty) {
        baryB = orderIndex[l]![b]!.toDouble();
      } else {
        final indices = pb
            .where((p) => prevOrder.containsKey(p))
            .map((p) => prevOrder[p]!.toDouble())
            .toList();
        baryB = indices.isEmpty
            ? orderIndex[l]![b]!.toDouble()
            : (indices.reduce((x, y) => x + y) / indices.length);
      }
      final cmp = baryA.compareTo(baryB);
      if (cmp != 0) return cmp;
      return a.compareTo(b); // стабильность: по id
    });
    // Обновим индексы уровня после сортировки
    final idxMap = <int, int>{};
    for (int k = 0; k < nodes.length; k++) {
      idxMap[nodes[k]] = k;
    }
    orderIndex[l] = idxMap;
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
  final right = positions.values
      .map((o) => o.dx + nodeSize.width)
      .fold<double>(0, math.max);
  final bottom = positions.values
      .map((o) => o.dy + nodeSize.height)
      .fold<double>(0, math.max);
  final canvasSize = Size(right + padding, bottom + padding);

  return CenteredLayoutResult(
    positions: positions,
    nextEdges: nextEdges,
    branchEdges: branchEdges,
    canvasSize: canvasSize,
  );
}

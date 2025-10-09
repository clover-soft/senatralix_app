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

/// Индексация шагов по id
Map<int, DialogStep> _indexById(List<DialogStep> steps) => {
  for (final s in steps) s.id: s,
};

// ignore: unintended_html_in_doc_comment
/// Построение словаря родителей: { childId -> Set<parentId> }
Map<int, Set<int>> _buildParents(
  List<DialogStep> steps,
  Map<int, DialogStep> byId,
) {
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
  return parents;
}

// ignore: unintended_html_in_doc_comment
/// Построение исходящих рёбер: { fromId -> Set<toId> }
Map<int, Set<int>> _buildOutgoing(
  List<DialogStep> steps,
  Map<int, DialogStep> byId,
) {
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
  return outgoing;
}

/// Инициализация уровней: корень (id=1) на уровне 0; прочие корневые — на уровне >=1
Map<int, int> _computeInitialLevels(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
  Map<int, Set<int>> outgoing,
) {
  final level = <int, int>{};
  final ids = steps.map((e) => e.id).toList()..sort();
  final hasId1 = ids.contains(1);
  final root = hasId1 ? 1 : ids.first;
  level[root] = 0;
  for (final id in ids) {
    if (id == root) continue;
    if ((parents[id] ?? const <int>{}).isEmpty) {
      // Прочие источники опускаем минимум на 1 уровень ниже верхнего
      level[id] = 1;
    }
  }
  // Итеративная релаксация: child >= parent + 1
  for (int iter = 0; iter < steps.length; iter++) {
    bool changed = false;
    for (final p in ids) {
      final lp = level[p] ?? 0;
      for (final u in (outgoing[p] ?? const <int>{})) {
        final need = lp + 1;
        final lu = level[u] ?? 0;
        if (lu < need) {
          level[u] = need;
          changed = true;
        }
      }
    }
    if (!changed) break;
  }
  // Никто, кроме корня, не должен остаться на уровне 0
  for (final id in ids) {
    if (id != root && (level[id] ?? 0) == 0) level[id] = 1;
  }
  return level;
}

/// Ограничение разрыва по рёбрам: для каждого child уровень не выше min(parent)+maxGap,
/// при этом соблюдаем минимум child >= parent+1. Итеративно до стабилизации.
void _applyEdgeGapUpperBounds(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
  Map<int, int> level, {
  int maxGap = 1,
}) {
  if (maxGap < 1) maxGap = 1;
  final ids = steps.map((e) => e.id).toList();
  for (int iter = 0; iter < steps.length * 2; iter++) {
    bool changed = false;
    // Верхние границы по всем родителям (min over parents)
    for (final id in ids) {
      final ps = parents[id] ?? const <int>{};
      if (ps.isEmpty) continue; // корни не ограничиваем сверху
      int ub = 1 << 30;
      for (final p in ps) {
        final cand = (level[p] ?? 0) + maxGap;
        if (cand < ub) ub = cand;
      }
      if ((level[id] ?? 0) > ub) {
        level[id] = ub;
        changed = true;
      }
    }
    // Минимум: child >= parent + 1
    for (final id in ids) {
      final ps = parents[id] ?? const <int>{};
      int need = 0;
      for (final p in ps) {
        final req = (level[p] ?? 0) + 1;
        if (req > need) need = req;
      }
      if ((level[id] ?? 0) < need) {
        level[id] = need;
        changed = true;
      }
    }
    // Гарантируем, что все некорневые не остаются на уровне 0
    for (final id in ids) {
      if (id != 1 && (level[id] ?? 0) == 0) {
        level[id] = 1;
        changed = true;
      }
    }
    if (!changed) break;
  }
}

/// Эксклюзивность branch-узлов: на одном уровне максимум 1 branch-нода, и не выше родителей
void _enforceBranchExclusivity(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
  Map<int, int> level,
) {
  final branchIds =
      steps.where((s) => s.branchLogic.isNotEmpty).map((s) => s.id).toList()
        ..sort();
  if (branchIds.isEmpty) return;
  // Гарантия: только корень остаётся на уровне 0
  for (final id in level.keys.toList()) {
    if (id != 1 && (level[id] ?? 0) == 0) level[id] = 1;
  }
  // Уникальные уровни для branch
  final occupied = <int>{};
  for (final bid in branchIds) {
    int l = level[bid] ?? 1;
    if (l == 0) l = 1;
    // Не выше максимального родителя + 1
    final ps = parents[bid] ?? const <int>{};
    int maxP = -1;
    for (final p in ps) {
      final lp = level[p] ?? 0;
      if (lp > maxP) maxP = lp;
    }
    final need = maxP + 1;
    if (l < need) l = need;
    while (occupied.contains(l)) {
      l++;
    }
    level[bid] = l;
    occupied.add(l);
  }
}

/// Сжатие уровней в плотный диапазон 0..K (с сохранением относительного порядка)
void _compressLevels(Map<int, int> level) {
  final uniq = level.values.toSet().toList()..sort();
  final rank = <int, int>{};
  for (int i = 0; i < uniq.length; i++) {
    rank[uniq[i]] = i;
  }
  level.updateAll((_, v) => rank[v]!);
}

/// Расчёт позиций для каждого узла по уровням с центрированием рядов
Map<int, Offset> _computePositions(
  Map<int, List<int>> byLevel,
  Size nodeSize,
  double nodeSeparation,
  double levelSeparation,
  double padding,
) {
  final levels = byLevel.keys.toList()..sort();
  double levelMaxWidth = 0;
  final levelWidths = <int, double>{};
  for (final l in levels) {
    final n = byLevel[l]!.length;
    final width = n * nodeSize.width + (n - 1) * nodeSeparation;
    levelWidths[l] = width;
    if (width > levelMaxWidth) levelMaxWidth = width;
  }
  final positions = <int, Offset>{};
  for (final l in levels) {
    final nodes = byLevel[l]!;
    final currentWidth = levelWidths[l] ?? 0;
    final startX = (levelMaxWidth - currentWidth) / 2;
    final y = padding + l * (nodeSize.height + levelSeparation);
    for (int i = 0; i < nodes.length; i++) {
      final x = padding + startX + i * (nodeSize.width + nodeSeparation);
      positions[nodes[i]] = Offset(x, y);
    }
  }
  return positions;
}

/// Формирование списков рёбер
(List<MapEntry<int, int>> nextEdges, List<MapEntry<int, int>> branchEdges)
_collectEdges(List<DialogStep> steps, Map<int, DialogStep> byId) {
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
  return (nextEdges, branchEdges);
}

/// Барицентрическая сортировка внутри уровней (сверху-вниз):
/// сортирует узлы текущего уровня по среднему индексу их родителей на предыдущем уровне
void _barycentricSort(Map<int, List<int>> byLevel, Map<int, Set<int>> parents) {
  final levels = byLevel.keys.toList()..sort();
  if (levels.length < 2) return;
  // Построим индекс текущих порядков
  final orderIndex = <int, Map<int, int>>{}; // level -> (nodeId -> index)
  for (final l in levels) {
    final nodes = byLevel[l]!;
    final idx = <int, int>{};
    for (int i = 0; i < nodes.length; i++) {
      idx[nodes[i]] = i;
    }
    orderIndex[l] = idx;
  }
  for (int i = 1; i < levels.length; i++) {
    final l = levels[i];
    final prev = levels[i - 1];
    final prevOrder = orderIndex[prev]!;
    final nodes = byLevel[l]!;
    nodes.sort((a, b) {
      double baryA;
      final pa = parents[a] ?? const <int>{};
      final idxA = pa
          .where((p) => prevOrder.containsKey(p))
          .map((p) => prevOrder[p]!.toDouble())
          .toList();
      baryA = idxA.isEmpty
          ? (orderIndex[l]?[a]?.toDouble() ?? 0)
          : (idxA.reduce((x, y) => x + y) / idxA.length);

      double baryB;
      final pb = parents[b] ?? const <int>{};
      final idxB = pb
          .where((p) => prevOrder.containsKey(p))
          .map((p) => prevOrder[p]!.toDouble())
          .toList();
      baryB = idxB.isEmpty
          ? (orderIndex[l]?[b]?.toDouble() ?? 0)
          : (idxB.reduce((x, y) => x + y) / idxB.length);

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
}

/// Вычисляет уровни и координаты для центрированной построчной раскладки.
CenteredLayoutResult computeCenteredLayout(
  List<DialogStep> steps, {
  Size nodeSize = const Size(240, 120),
  double nodeSeparation = 32,
  double levelSeparation = 120,
  double padding = 80,
}) {
  // Пустой вход — пустой результат
  if (steps.isEmpty) {
    return const CenteredLayoutResult(
      positions: {},
      nextEdges: [],
      branchEdges: [],
      canvasSize: Size.zero,
    );
  }

  // Индексация и графовые структуры
  final byId = _indexById(steps);
  final parents = _buildParents(steps, byId);
  final outgoing = _buildOutgoing(steps, byId);

  // Начальные уровни: корень id=1 наверху, остальные ниже, parent < child
  final level = _computeInitialLevels(steps, parents, outgoing);

  // Cap: ограничим разрыв по рёбрам (child <= min(parent)+1) с сохранением parent<child
  _applyEdgeGapUpperBounds(steps, parents, level, maxGap: 1);

  // Эксклюзивность для branch-узлов и корректировка относительно родителей
  _enforceBranchExclusivity(steps, parents, level);

  // Повторный cap после эксклюзивности branch для восстановления монотонности и ограничения разрыва
  _applyEdgeGapUpperBounds(steps, parents, level, maxGap: 1);

  // Плотное сжатие 0..K
  _compressLevels(level);

  // Группировка по уровням (пересобираем после cap/сжатия)
  final byLevel = <int, List<int>>{};
  for (final e in level.entries) {
    (byLevel[e.value] ??= <int>[]).add(e.key);
  }
  // Барицентрическая сортировка для уменьшения пересечений рёбер
  _barycentricSort(byLevel, parents);

  // Размещение branch слева в ряду (если есть другие ноды)
  final branchSet = steps
      .where((s) => s.branchLogic.isNotEmpty)
      .map((s) => s.id)
      .toSet();
  for (final l in byLevel.keys) {
    final nodes = byLevel[l]!;
    final atLevel = nodes.where((id) => branchSet.contains(id)).toList();
    if (atLevel.isNotEmpty &&
        nodes.length > 1 &&
        nodes.first != atLevel.first) {
      nodes.remove(atLevel.first);
      nodes.insert(0, atLevel.first);
    }
  }

  // Лог: список рядов с идентификаторами нод и branch-нод
  final sortedLevels = byLevel.keys.toList()..sort();
  for (final l in sortedLevels) {
    final nodes = byLevel[l]!;
    final branchIdsAtLevel = nodes
        .where((id) => branchSet.contains(id))
        .toList();
    final nodesFmt = nodes.map((id) {
      final ps = parents[id] ?? const <int>{};
      final plist = ps.toList()..sort();
      return '$id(${plist.join(',')})';
    }).toList();
    // ignore: avoid_print
    print('[layout] row l=$l nodes=$nodesFmt branchIds=$branchIdsAtLevel');
  }

  // Позиции и рёбра
  final positions = _computePositions(
    byLevel,
    nodeSize,
    nodeSeparation,
    levelSeparation,
    padding,
  );
  final edges = _collectEdges(steps, byId);

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
    nextEdges: edges.$1,
    branchEdges: edges.$2,
    canvasSize: canvasSize,
  );
}

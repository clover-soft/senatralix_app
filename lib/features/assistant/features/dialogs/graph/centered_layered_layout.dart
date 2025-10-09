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

// Флаг отладочного вывода этапов раскладки
const bool _kLayoutDebug = false;

/// Индексация шагов по id
Map<int, DialogStep> _indexById(List<DialogStep> steps) => {
  for (final s in steps) s.id: s,
};

/// Построение словаря родителей: { childId -> Set<parentId> }
Map<int, Set<int>> _buildParents(List<DialogStep> steps, Map<int, DialogStep> byId) {
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

/// Построение исходящих рёбер: { fromId -> Set<toId> }
Map<int, Set<int>> _buildOutgoing(List<DialogStep> steps, Map<int, DialogStep> byId) {
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

/// Эксклюзивность branch-узлов: на одном уровне максимум 1 branch-нода, и не выше родителей
void _enforceBranchExclusivity(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
  Map<int, int> level,
) {
  final branchIds = steps.where((s) => s.branchLogic.isNotEmpty).map((s) => s.id).toList()
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

/// Базовая сортировка узлов внутри уровня (по id)
void _sortWithinLevels(Map<int, List<int>> byLevel) {
  for (final l in byLevel.keys) {
    byLevel[l]!.sort();
  }
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
(List<MapEntry<int, int>> nextEdges, List<MapEntry<int, int>> branchEdges) _collectEdges(
  List<DialogStep> steps,
  Map<int, DialogStep> byId,
) {
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

  // Эксклюзивность для branch-узлов и корректировка относительно родителей
  _enforceBranchExclusivity(steps, parents, level);

  // Плотное сжатие 0..K
  _compressLevels(level);

  // Группировка по уровням
  final byLevel = <int, List<int>>{};
  for (final e in level.entries) {
    (byLevel[e.value] ??= <int>[]).add(e.key);
  }
  _sortWithinLevels(byLevel);

  // Размещение branch слева в ряду (если есть другие ноды)
  final branchSet = steps.where((s) => s.branchLogic.isNotEmpty).map((s) => s.id).toSet();
  for (final l in byLevel.keys) {
    final nodes = byLevel[l]!;
    final atLevel = nodes.where((id) => branchSet.contains(id)).toList();
    if (atLevel.isNotEmpty && nodes.length > 1 && nodes.first != atLevel.first) {
      nodes.remove(atLevel.first);
      nodes.insert(0, atLevel.first);
    }
  }

  // Позиции и рёбра
  final positions = _computePositions(byLevel, nodeSize, nodeSeparation, levelSeparation, padding);
  final edges = _collectEdges(steps, byId);

  // Размер холста
  final right = positions.values.map((o) => o.dx + nodeSize.width).fold<double>(0, math.max);
  final bottom = positions.values.map((o) => o.dy + nodeSize.height).fold<double>(0, math.max);
  final canvasSize = Size(right + padding, bottom + padding);

  return CenteredLayoutResult(
    positions: positions,
    nextEdges: edges.$1,
    branchEdges: edges.$2,
    canvasSize: canvasSize,
  );
}

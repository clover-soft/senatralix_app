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

/// Чистая функция нормализации уровней.
/// Возвращает новую мапу уровней, где уровни сжаты в 0..K и соблюдена полоса child ∈ [parent+1, parent+kMaxGap].
Map<int, int> normalizeLevels(
  List<DialogStep> steps,
  Map<int, Set<int>> outgoing,
  Map<int, int> levelIn,
) {
  // Копия входных уровней
  final level = <int, int>{}..addAll(levelIn);

  if (kCenteredLayoutDebug) {
    // Лог входных параметров
    final uniqIn = levelIn.values.toSet().toList()..sort();
    // ignore: avoid_print
    print('[normalize] IN: nodes=${levelIn.length} uniqLevels=${uniqIn}');
    // Считаем пример рёбер
    int edgeCount = 0;
    for (final outs in outgoing.values) edgeCount += outs.length;
    // ignore: avoid_print
    print('[normalize] IN: edges=$edgeCount kMaxGap=$kMaxGap');
  }

  // Двунаправленная релаксация до сходимости
  for (int iter = 0; iter < steps.length * 3; iter++) {
    bool changed = false;
    // Прямой проход: ограничение на ребёнка относительно родителя
    for (final s in steps) {
      final lp = level[s.id] ?? 0;
      final outs = outgoing[s.id] ?? const <int>{};
      for (final u in outs) {
        final minC = lp + 1;
        final maxC = lp + kMaxGap;
        final lu = level[u] ?? 0;
        int newLu = lu;
        if (newLu < minC) newLu = minC;
        if (newLu > maxC) newLu = maxC;
        if (newLu != lu) {
          level[u] = newLu;
          changed = true;
        }
      }
    }
    // Обратный проход: ограничение на родителя относительно ребёнка
    for (final s in steps) {
      final lp = level[s.id] ?? 0;
      final outs = outgoing[s.id] ?? const <int>{};
      for (final u in outs) {
        final lu = level[u] ?? 0;
        final maxP = lu - 1; // parent не выше child-1
        if (lp > maxP) {
          level[s.id] = maxP < 0 ? 0 : maxP;
          changed = true;
        }
      }
    }
    if (!changed) break;
  }

  // Плотное сжатие 0..K (dense ranks)
  final uniq = level.values.toSet().toList()..sort();
  final rank = <int, int>{};
  for (int i = 0; i < uniq.length; i++) {
    rank[uniq[i]] = i;
  }
  level.updateAll((_, v) => rank[v]!);

  if (kCenteredLayoutDebug) {
    final uniqOut = level.values.toSet().toList()..sort();
    // Проверим макс. разрыв по рёбрам
    int maxGapObserved = 0;
    for (final s in steps) {
      final lp = level[s.id] ?? 0;
      for (final u in (outgoing[s.id] ?? const <int>{})) {
        final lu = level[u] ?? 0;
        final gap = lu - lp;
        if (gap > maxGapObserved) maxGapObserved = gap;
      }
    }
    // ignore: avoid_print
    print('[normalize] OUT: uniqLevels=${uniqOut} maxGapObserved=$maxGapObserved');
  }
  return level;
}

/// Рассчитывает нижние и верхние границы уровней и сжимает level в [L, U]
void _computeLowerUpperClamp(
  List<DialogStep> steps,
  Map<int, Set<int>> outgoing,
  List<int> roots,
  Map<int, int> level, {
  int maxGap = 2,
}) {
  if (maxGap < 1) maxGap = 1;
  final nodeIds = steps.map((e) => e.id).toList();
  // Нижние границы L
  final L = <int, int>{for (final s in steps) s.id: 0};
  for (final r in roots) {
    L[r] = 0;
  }

  // Прогон по рёбрам для L(u) >= L(p)+1
  for (int iter = 0; iter < nodeIds.length; iter++) {
    bool changed = false;
    for (final p in nodeIds) {
      final lp = L[p] ?? 0;
      for (final u in (outgoing[p] ?? const <int>{})) {
        final cand = lp + 1;
        if ((L[u] ?? 0) < cand) {
          L[u] = cand;
          changed = true;
        }
      }
    }
    if (!changed) break;
  }

  // Верхние границы U
  const big = 1 << 30;
  final U = <int, int>{for (final s in steps) s.id: big};
  for (final r in roots) {
    U[r] = L[r] ?? 0;
  }
  for (int iter = 0; iter < nodeIds.length; iter++) {
    bool changed = false;
    for (final p in nodeIds) {
      final up = U[p];
      if (up == null || up == big) continue;
      for (final u in (outgoing[p] ?? const <int>{})) {
        final cand = up + maxGap;
        if (cand < U[u]!) {
          U[u] = cand;
          changed = true;
        }
      }
    }
    if (!changed) break;
  }
  // Гарантировать U >= L и финальный clamp
  for (final id in nodeIds) {
    final li = L[id] ?? 0;
    final ui = (U[id] == null || U[id] == big) ? li : U[id]!;
    final uic = ui < li ? li : ui;
    final cur = level[id] ?? li;
    if (cur < li) {
      level[id] = li;
    } else if (cur > uic) {
      level[id] = uic;
    } else {
      level[id] = cur;
    }
  }
}

// (удалено) _levelsSignature и _enforceEdgeBand — не используются в текущем пайплайне
const int kMaxGap = 1; // глобальный лимит вертикального разрыва по ребру

/// Включение подробного лога расчёта раскладки (для отладки длинных рёбер)
const bool kCenteredLayoutDebug = true;

/// Рассчитывает верхние границы уровней из ограничения на разрыв по рёбрам (maxGap)
/// и стягивает уровни в интервал [L(u), U(u)], где L(u) уже задан как текущий level[u].
void _applyEdgeGapUpperBounds(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
  Map<int, Set<int>> outgoing,
  List<int> roots,
  Map<int, int> level, {
  int maxGap = 2,
  Map<int, int>? minLevelOverride,
}) {
  if (maxGap < 1) return;
  // Инициализация верхних границ
  final big = 1 << 30;
  final ub = <int, int>{for (final s in steps) s.id: big};
  for (final r in roots) {
    ub[r] = level[r] ?? 0;
  }
  // Прямой проход: U(child) <= U(parent) + maxGap
  for (int iter = 0; iter < steps.length; iter++) {
    bool changed = false;
    for (final s in steps) {
      final up = ub[s.id];
      if (up == null || up == big) continue;
      for (final u in (outgoing[s.id] ?? const <int>{})) {
        final cand = up + maxGap;
        if (cand < ub[u]!) {
          ub[u] = cand;
          changed = true;
        }
      }
    }
    if (!changed) break;
  }
  // Ограничим верхние границы текущим уровнем (не увеличиваем cap сверх текущего)
  for (final s in steps) {
    final id = s.id;
    ub[id] = math.min(ub[id]!, level[id]!);
    // Если есть минимальные уровни (для сдвинутых branch), не опускаем ниже них
    if (minLevelOverride != null) {
      final minL = minLevelOverride[id];
      if (minL != null && ub[id]! < minL) {
        ub[id] = minL;
      }
    }
  }
  // Стягивание уровней к U(u) с сохранением монотонности
  for (int iter = 0; iter < steps.length; iter++) {
    bool changed = false;
    // Срез сверху
    for (final s in steps) {
      final id = s.id;
      final cap = ub[id]!;
      if (level[id]! > cap) {
        level[id] = cap;
        changed = true;
      }
    }
    // Восстановление child >= parent+1
    _enforceParentBeforeChild(steps, outgoing, level);
    // При необходимости ещё раз срежем уровни по U(u)
    for (final s in steps) {
      final id = s.id;
      final cap = ub[id]!;
      if (level[id]! > cap) {
        level[id] = cap;
        changed = true;
      }
    }
    if (!changed) break;
  }
}

/// Делает уровни нод с ветвлениями эксклюзивными (в ряду только одна такая нода)
/// и упорядочивает такие ноды по возрастанию id сверху вниз.
Map<int, int> _enforceBranchRows(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
  Map<int, Set<int>> outgoing,
  Map<int, int> level,
) {
  final minLevelOverride = <int, int>{};
  // Список id нод с ветвлениями по возрастанию id
  final branchIds =
      steps.where((s) => s.branchLogic.isNotEmpty).map((s) => s.id).toList()
        ..sort();
  if (branchIds.isEmpty) return minLevelOverride;

  // Гарантируем порядок branch по id: non-decreasing уровни
  for (int i = 1; i < branchIds.length; i++) {
    final prev = branchIds[i - 1];
    final cur = branchIds[i];
    final need = (level[prev] ?? 0) + 1;
    if ((level[cur] ?? 0) < need) {
      level[cur] = need;
    }
  }

  // Эксклюзивность branch в ряду: итеративно, пока стабильно.
  for (int iter = 0; iter < steps.length; iter++) {
    bool changed = false;
    final byLevel = <int, List<int>>{};
    for (final s in steps) {
      final l = level[s.id] ?? 0;
      (byLevel[l] ??= <int>[]).add(s.id);
    }
    for (final entry in byLevel.entries) {
      final l = entry.key;
      final ids = entry.value;
      final branchAtLevel = ids.where((id) => branchIds.contains(id)).toList()
        ..sort();
      if (branchAtLevel.isEmpty) continue;

      // Раз на уровне есть branch, должна остаться ровно ОДНА branch-нода — с минимальным id
      // Прочие branch-ноды уезжают вниз, НЕ-branch остаются.
      for (final bid in branchAtLevel.skip(1)) {
        if ((level[bid] ?? 0) == l) {
          // Базовое смещение вниз
          int newLevel = l + 1;
          // Ограничим новый уровень диапазоном по всем родителям bid: [max(parent)+1, max(parent)+kMaxGap]
          final ps = parents[bid] ?? const <int>{};
          if (ps.isNotEmpty) {
            int parentMax = -1;
            for (final p in ps) {
              final lp = level[p] ?? 0;
              if (lp > parentMax) parentMax = lp;
            }
            final lower = parentMax + 1;
            final upper = parentMax + kMaxGap;
            if (newLevel < lower) newLevel = lower;
            if (newLevel > upper) newLevel = upper;
          }
          level[bid] = newLevel;
          // Минимальный уровень для этой branch-ноды фиксируем, чтобы cap её не подтянул обратно
          minLevelOverride[bid] = newLevel;
          changed = true;
        }
      }
    }
    if (!changed) break;
    // После сдвигов восстановим монотонность
    _enforceParentBeforeChild(steps, outgoing, level);
  }

  // Дополнительно: если у branch-ноды есть родители, убедимся, что она размещена не выше их
  for (final bid in branchIds) {
    final ps = parents[bid] ?? const <int>{};
    int maxParent = -1;
    for (final p in ps) {
      final lp = level[p] ?? 0;
      if (lp > maxParent) maxParent = lp;
    }
    final need = maxParent + 1;
    if ((level[bid] ?? 0) < need) {
      level[bid] = need;
    }
  }

  // Финальная монотонность
  _enforceParentBeforeChild(steps, outgoing, level);
  return minLevelOverride;
}

// ------------------------
// Вспомогательные функции раскладки
// ------------------------

/// Индексация списка шагов по id: { stepId -> DialogStep }
Map<int, DialogStep> _indexById(List<DialogStep> steps) => {
  for (final s in steps) s.id: s,
};

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

/// Поиск начальных корней (узлы без родителей). Если ни одного нет — берём минимальный id.
List<int> _findInitialRoots(
  List<DialogStep> steps,
  Map<int, Set<int>> parents,
) {
  final roots = steps
      .where((s) => parents[s.id]!.isEmpty)
      .map((e) => e.id)
      .toList();
  if (roots.isEmpty) {
    roots.add(steps.map((e) => e.id).reduce(math.min));
  }
  return roots;
}

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

/// Расширяет набор корней: для каждой недостижимой компоненты добавляет новый корень (минимальный id в компоненте).
void _expandRootsByComponents(
  List<int> roots,
  Map<int, Set<int>> outgoing,
  Iterable<int> allIds,
) {
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
  var remaining = allIds.toSet().difference(reachable);
  while (remaining.isNotEmpty) {
    final extraRoot = remaining.reduce((a, b) => a < b ? a : b);
    roots.add(extraRoot);
    dfs(extraRoot);
    remaining = allIds.toSet().difference(reachable);
  }
}

/// Гарантирует монотонность уровней: для каждого ребра parent->child выполняется level(child) >= level(parent) + 1.

/// Гарантирует монотонность уровней: для каждого ребра parent->child выполняется level(child) >= level(parent) + 1.
void _enforceParentBeforeChild(
  List<DialogStep> steps,
  Map<int, Set<int>> outgoing,
  Map<int, int> level,
) {
  for (int iter = 0; iter < steps.length; iter++) {
    bool changed = false;
    for (final s in steps) {
      final lp = level[s.id] ?? 0;
      final outs = outgoing[s.id] ?? const <int>{};
      for (final u in outs) {
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
  final byId = _indexById(steps);

  // Родители: кто ссылается на кого
  final parents = _buildParents(steps, byId);

  // Корни: шаги без родителей (начальный набор)
  final roots = _findInitialRoots(steps, parents);
  if (kCenteredLayoutDebug) {
    // Лог корней
    // ignore: avoid_print
    print(
      '[layout] roots: ${roots.take(20).toList()}${roots.length > 20 ? '...' : ''}',
    );
  }

  // Рёбра (для вычисления уровней/порядка)
  final outgoing = _buildOutgoing(steps, byId);

  // Расширим набор корней по компонентам: добавим корень для каждой недостижимой компоненты
  _expandRootsByComponents(roots, outgoing, steps.map((e) => e.id));

  // Единый финализатор уровней: нижние/верхние границы и clamp (maxGap=2)
  final level = <int, int>{};
  _computeLowerUpperClamp(steps, outgoing, roots, level, maxGap: 2);

  // Гарантия: каждый ребёнок ниже любого своего родителя минимум на 1 уровень
  _enforceParentBeforeChild(steps, outgoing, level);

  // Анти-длинные рёбра: первичная стабилизация верхними границами (разрыв до 1)
  _applyEdgeGapUpperBounds(steps, parents, outgoing, roots, level, maxGap: 1);

  // Правила для branch-нод: эксклюзивные ряды и порядок по id
  final branchMinOverride = _enforceBranchRows(steps, parents, outgoing, level);

  // Анти-длинные рёбра: финальная стабилизация единственным cap (разрыв до 1)
  _applyEdgeGapUpperBounds(
    steps,
    parents,
    outgoing,
    roots,
    level,
    maxGap: 1,
    minLevelOverride: branchMinOverride,
  );
  // Повторно закрепим уникальность branch в рядах (на случай, если cap свёл их в один ряд)
  _enforceBranchRows(steps, parents, outgoing, level);
  // И восстановим монотонность после этого шага (только подтягивание вверх)
  _enforceParentBeforeChild(steps, outgoing, level);
  // Финальная плотная нормализация уровней ПЕРЕД логом
  final normalizedForLog = normalizeLevels(steps, outgoing, level);
  level
    ..clear()
    ..addAll(normalizedForLog);
  if (kCenteredLayoutDebug) {
    // Уровни после плотной нормализации
    final uniqLevels = level.values.toSet().toList()..sort();
    // ignore: avoid_print
    print('[layout] levels(after normalize) = ' + uniqLevels.toString());
    // Проверка больших разрывов по уровням (после финальной стабилизации)
    for (final s in steps) {
      final lp = level[s.id] ?? 0;
      for (final u in (outgoing[s.id] ?? const <int>{})) {
        final lu = level[u] ?? 0;
        final gap = lu - lp;
        if (gap > 1) {
          // ignore: avoid_print
          print('[layout] big gap POST: $lp -> $lu edge ${s.id} -> $u');
        }
      }
    }
    final maxLevel = level.values.isEmpty ? 0 : level.values.reduce(math.max);
    // ignore: avoid_print
    print('[layout] maxLevel=$maxLevel nodes=${steps.length}');
  }

  // На всякий случай сохраняем плотность уровней 0..K перед группировкой
  final normalizedForLayout = normalizeLevels(steps, outgoing, level);
  level
    ..clear()
    ..addAll(normalizedForLayout);
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

  // Принудительное размещение branch слева, если на уровне есть другие ноды
  final branchSet = steps
      .where((s) => s.branchLogic.isNotEmpty)
      .map((s) => s.id)
      .toSet();
  for (final l in sortedLevels) {
    final nodes = byLevel[l]!;
    final branchAtLevel = nodes.where((id) => branchSet.contains(id)).toList();
    if (branchAtLevel.isEmpty) continue;
    // По нашему правилу на уровне может быть только одна branch-нода
    final bid = branchAtLevel.first;
    if (nodes.length > 1 && nodes.first != bid) {
      nodes.remove(bid);
      nodes.insert(0, bid); // ставим слева
    }
  }

  if (kCenteredLayoutDebug) {
    for (final l in sortedLevels) {
      final nodes = byLevel[l]!;
      final branchIdsAtLevel = nodes
          .where((id) => branchSet.contains(id))
          .toList();
      // ignore: avoid_print
      print('[layout] row l=$l nodes=${nodes} branchIds=$branchIdsAtLevel');
    }
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
  if (kCenteredLayoutDebug) {
    // ignore: avoid_print
    print('[layout] canvasSize=$canvasSize');
  }

  return CenteredLayoutResult(
    positions: positions,
    nextEdges: nextEdges,
    branchEdges: branchEdges,
    canvasSize: canvasSize,
  );
}

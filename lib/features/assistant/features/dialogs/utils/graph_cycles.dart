import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Построить ориентированный граф (adjacency list) из шагов по полям next и branchLogic
Map<int, List<int>> _buildAdjacency(List<DialogStep> steps) {
  final idSet = steps.map((e) => e.id).toSet();
  final g = <int, List<int>>{};
  for (final s in steps) {
    final list = g.putIfAbsent(s.id, () => <int>[]);
    final n = s.next;
    if (n != null && idSet.contains(n)) list.add(n);
    for (final mapping in s.branchLogic.values) {
      for (final to in mapping.values) {
        if (idSet.contains(to)) list.add(to);
      }
    }
  }
  return g;
}

/// Проверка наличия циклов в графе шагов диалога
bool hasDialogCycles(List<DialogStep> steps) {
  if (steps.isEmpty) return false;
  final g = _buildAdjacency(steps);
  final nodes = g.keys.toSet();
  final color = <int, int>{
    for (final id in nodes) id: 0,
  }; // 0 white, 1 gray, 2 black

  bool dfs(int u) {
    color[u] = 1; // gray
    for (final v in g[u] ?? const <int>[]) {
      final c = color[v] ?? 0;
      if (c == 1) return true; // back-edge
      if (c == 0 && dfs(v)) return true;
    }
    color[u] = 2; // black
    return false;
  }

  for (final id in nodes) {
    if (color[id] == 0 && dfs(id)) return true;
  }
  return false;
}

/// Найти обратные рёбра (back-edges) по DFS-окраске.
/// Возвращает пары (fromId, toId) — рёбра, ведущие в серую вершину.
List<MapEntry<int, int>> findBackEdges(List<DialogStep> steps) {
  final g = _buildAdjacency(steps);
  final nodes = g.keys.toSet();
  final color = <int, int>{for (final id in nodes) id: 0};
  final result = <MapEntry<int, int>>[];

  void dfs(int u) {
    color[u] = 1; // gray
    for (final v in g[u] ?? const <int>[]) {
      final c = color[v] ?? 0;
      if (c == 1) {
        result.add(MapEntry(u, v));
      } else if (c == 0) {
        dfs(v);
      }
    }
    color[u] = 2; // black
  }

  for (final id in nodes) {
    if (color[id] == 0) dfs(id);
  }
  return result;
}

/// Выбрать рёбра для исключения из Sugiyama так, чтобы удалялись именно «вверх» направленные связи.
/// На вход: исходные шаги. На выход: пары (from,to), которые следует исключить и дорисовать отдельно.
List<MapEntry<int, int>> selectEdgesToOmit(List<DialogStep> steps) {
  final g = _buildAdjacency(steps);
  // 1) Находим back-edges
  final backs = findBackEdges(steps);
  final backSet = backs.map((e) => '${e.key}->${e.value}').toSet();

  // 2) Считаем уровни на графе без back-edges
  final nodes = g.keys.toSet();
  final indeg = <int, int>{for (final n in nodes) n: 0};
  g.forEach((u, outs) {
    for (final v in outs) {
      if (backSet.contains('$u->$v')) continue;
      indeg[v] = (indeg[v] ?? 0) + 1;
    }
  });
  var roots = nodes.where((n) => (indeg[n] ?? 0) == 0).toList();
  if (roots.isEmpty && nodes.isNotEmpty) {
    final minIn = indeg.values.fold<int>(1 << 30, (m, v) => v < m ? v : m);
    roots = nodes.where((n) => (indeg[n] ?? 0) == minIn).toList()..sort();
  }
  final level = <int, int>{for (final n in nodes) n: 1 << 30};
  final queue = <int>[];
  for (final r in roots) {
    level[r] = 0;
    queue.add(r);
  }
  while (queue.isNotEmpty) {
    final u = queue.removeAt(0);
    for (final v in g[u] ?? const <int>[]) {
      if (backSet.contains('$u->$v')) continue;
      final nd = level[u]! + 1;
      if (nd < (level[v] ?? (1 << 30))) {
        level[v] = nd;
        queue.add(v);
      }
    }
  }

  // 3) Для каждой вершины v оставляем входящее от предка с минимальным уровнем
  final preds = <int, List<int>>{}; // v -> [u]
  final edges = <MapEntry<int, int>>[];
  g.forEach((u, outs) {
    for (final v in outs) {
      edges.add(MapEntry(u, v));
      if (backSet.contains('$u->$v')) continue;
      (preds[v] ??= <int>[]).add(u);
      preds.putIfAbsent(u, () => <int>[]);
    }
  });

  final omit = <MapEntry<int, int>>[];
  preds.forEach((v, us) {
    if (us.isEmpty) return;
    int minPredLevel = 1 << 30;
    for (final u in us) {
      final lu = level[u] ?? (1 << 30);
      if (lu < minPredLevel) minPredLevel = lu;
    }
    for (final u in us) {
      final lu = level[u] ?? (1 << 30);
      if (lu > minPredLevel) omit.add(MapEntry(u, v));
    }
  });

  // 4) Добавляем сами back-edges в omit (дорисовываются поверх)
  omit.addAll(backs);

  // Уникализируем
  final seen = <String>{};
  final unique = <MapEntry<int, int>>[];
  for (final e in omit) {
    final k = '${e.key}->${e.value}';
    if (seen.add(k)) unique.add(e);
  }
  // Лог
  try {
    final levelsStr = level.entries
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final predsStr = preds.entries
        .map(
          (e) =>
              '${e.key}<=[${e.value.join(',')}] (min=${(e.value.isEmpty) ? 'inf' : (e.value.map((u) => level[u] ?? (1 << 30)).reduce((a, b) => a < b ? a : b))})',
        )
        .join('; ');
    final edgesStr = edges.map((e) => '${e.key}->${e.value}').join(', ');
    final backsStr = backs.map((e) => '${e.key}->${e.value}').join(', ');
    final omitStr = unique.map((e) => '${e.key}->${e.value}').join(', ');
    print(
      '[GraphCycles] levels={$levelsStr} preds={$predsStr} edges=[$edgesStr] backs=[$backsStr] omit=[$omitStr]',
    );
  } catch (_) {}
  return unique;
}

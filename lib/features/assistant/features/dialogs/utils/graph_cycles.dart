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
  final color = <int, int>{for (final id in nodes) id: 0}; // 0 white, 1 gray, 2 black

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

/// Посчитать дистанции (уровни) от корней (вершины без входящих рёбер).
Map<int, int> _computeLevels(List<DialogStep> steps) {
  final g = _buildAdjacency(steps);
  final nodes = g.keys.toSet();
  // Входящие
  final indeg = <int, int>{for (final n in nodes) n: 0};
  g.forEach((u, outs) {
    for (final v in outs) {
      indeg[v] = (indeg[v] ?? 0) + 1;
    }
  });
  var roots = nodes.where((n) => (indeg[n] ?? 0) == 0).toList();
  if (roots.isEmpty && nodes.isNotEmpty) {
    // Фолбэк: используем вершины с минимальной входящей степенью как корни
    final minIn = indeg.values.fold<int>(1 << 30, (m, v) => v < m ? v : m);
    roots = nodes.where((n) => (indeg[n] ?? 0) == minIn).toList();
    // Если и это не помогло (теоретически), возьмём минимальный id
    roots.sort();
    if (roots.isEmpty) roots = [nodes.reduce((a, b) => a < b ? a : b)];
  }
  final dist = <int, int>{for (final n in nodes) n: 1 << 30};
  final queue = <int>[];
  for (final r in roots) {
    dist[r] = 0;
    queue.add(r);
  }
  while (queue.isNotEmpty) {
    final u = queue.removeAt(0);
    for (final v in g[u] ?? const <int>[]) {
      final nd = dist[u]! + 1;
      if (nd < (dist[v] ?? (1 << 30))) {
        dist[v] = nd;
        queue.add(v);
      }
    }
  }
  return dist;
}

/// Выбрать рёбра для исключения из Sugiyama так, чтобы удалялись именно «вверх» направленные связи.
/// На вход: исходные шаги. На выход: пары (from,to), которые следует исключить и дорисовать отдельно.
List<MapEntry<int, int>> selectEdgesToOmit(List<DialogStep> steps) {
  final g = _buildAdjacency(steps);
  final backs = findBackEdges(steps);
  if (backs.isEmpty) return backs;
  final level = _computeLevels(steps);
  final omit = <MapEntry<int, int>>[];
  bool hasEdge(int a, int b) => (g[a] ?? const <int>[]).contains(b);

  for (final e in backs) {
    final u = e.key;
    final v = e.value;
    final du = level[u] ?? (1 << 30);
    final dv = level[v] ?? (1 << 30);
    // Выбираем ребро, направленное из более глубокого уровня к более высокому («вверх»)
    if (du > dv) {
      // u глубже v — e(u->v) идёт вверх
      omit.add(e);
    } else if (dv > du) {
      // v глубже u — если есть обратное ребро, выберем его как «вверх»
      if (hasEdge(v, u)) {
        omit.add(MapEntry(v, u));
      } else {
        // нет обратного — выбора нет, оставляем исходное
        omit.add(e);
      }
    } else {
      // du == dv (один уровень). Предпочтем обратное, если оно есть, чтобы получить «вверх» при раскладке
      if (hasEdge(v, u)) {
        omit.add(MapEntry(v, u));
      } else {
        omit.add(e);
      }
    }
  }
  // Уникализируем
  final seen = <String>{};
  final unique = <MapEntry<int, int>>[];
  for (final e in omit) {
    final k = '${e.key}->${e.value}';
    if (seen.add(k)) unique.add(e);
  }
  // Отладочный лог: уровни и выбранные рёбра для исключения
  try {
    final levelsStr = level.entries.map((e) => '${e.key}:${e.value}').join(', ');
    final backsStr = backs.map((e) => '${e.key}->${e.value}').join(', ');
    final omitStr = unique.map((e) => '${e.key}->${e.value}').join(', ');
    // Используем print, чтобы не тянуть зависимости логгера в утилиту
    print('[GraphCycles] levels={$levelsStr} backs=[$backsStr] omit=[$omitStr]');
  } catch (_) {}
  return unique;
}

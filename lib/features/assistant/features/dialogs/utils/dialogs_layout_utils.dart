import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Результаты вычисления сетки графа (для вертикального графа сверху-вниз)
class DialogGridStats {
  const DialogGridStats({
    required this.rows,
    required this.cols,
    required this.levels,
  });

  /// Кол-во рядов (уровней сверху-вниз)
  final int rows;

  /// Максимальное кол-во нод на одном уровне (ширина слева-направо)
  final int cols;

  /// Карта: уровень -> список id шагов на этом уровне
  final Map<int, List<int>> levels;
}

/// Построить уровни графа и посчитать ряды/колонки.
///
/// Алгоритм:
/// 1) Строим ориентированный граф из шагов по связям `next` и по ветвлениям `branchLogic`.
/// 2) Ищем корни (шаги без входящих рёбер). Если корней нет — берём минимальный id как корень.
/// 3) BFS от всех корней: шаги, на которые можно попасть, получают уровень `min(level[parent] + 1)`.
/// 4) Группируем id по уровню и считаем `rows` и `cols`.
DialogGridStats computeDialogGridStats(List<DialogStep> steps) {
  if (steps.isEmpty) {
    return const DialogGridStats(rows: 0, cols: 0, levels: {});
  }

  // Индексы для быстрого доступа
  final ids = steps.map((e) => e.id).toSet();
  final outgoing = <int, Set<int>>{}; // from -> {to}
  final incomingCount = <int, int>{}; // to -> count

  void _addEdge(int from, int to) {
    if (!ids.contains(to)) return; // игнор ссылок на несуществующие id
    outgoing.putIfAbsent(from, () => <int>{}).add(to);
    incomingCount[to] = (incomingCount[to] ?? 0) + 1;
  }

  // Собираем рёбра
  for (final s in steps) {
    if (s.next != null) {
      _addEdge(s.id, s.next!);
    }
    if (s.branchLogic.isNotEmpty) {
      for (final entry in s.branchLogic.entries) {
        for (final kv in entry.value.entries) {
          _addEdge(s.id, kv.value);
        }
      }
    }
    outgoing.putIfAbsent(s.id, () => <int>{});
    incomingCount.putIfAbsent(s.id, () => 0);
  }

  // Находим корни (без входящих)
  final roots = incomingCount.entries
      .where((e) => (e.value == 0))
      .map((e) => e.key)
      .toList();
  if (roots.isEmpty) {
    // fallback: берём минимальный id
    final minId = ids.reduce((a, b) => a < b ? a : b);
    roots.add(minId);
  }

  // BFS для уровней
  final levelOf = <int, int>{};
  final queue = <int>[];
  for (final r in roots) {
    levelOf[r] = 0;
    queue.add(r);
  }
  while (queue.isNotEmpty) {
    final u = queue.removeAt(0);
    final lu = levelOf[u] ?? 0;
    for (final v in outgoing[u] ?? const <int>{}) {
      final lv = levelOf[v];
      final cand = lu + 1;
      if (lv == null || cand < lv) {
        levelOf[v] = cand;
        queue.add(v);
      }
    }
  }

  // Если остались ноды без уровня (изолированные компоненты), 
  // назначим им уровень 0 (или максимальный найденный + 1 — по желанию).
  final maxAssigned = levelOf.values.isEmpty ? 0 : levelOf.values.reduce((a, b) => a > b ? a : b);
  for (final id in ids) {
    levelOf.putIfAbsent(id, () => maxAssigned); // помещаем в самый нижний найденный уровень
  }

  // Группируем по уровням
  final levels = <int, List<int>>{};
  for (final entry in levelOf.entries) {
    levels.putIfAbsent(entry.value, () => <int>[]).add(entry.key);
  }
  // Отсортируем id внутри уровня по возрастанию для стабильности
  for (final l in levels.keys) {
    levels[l]!.sort();
  }

  final rows = levels.keys.isEmpty ? 0 : (levels.keys.reduce((a, b) => a > b ? a : b) + 1);
  var cols = 0;
  for (final list in levels.values) {
    if (list.length > cols) cols = list.length;
  }

  return DialogGridStats(rows: rows, cols: cols, levels: levels);
}

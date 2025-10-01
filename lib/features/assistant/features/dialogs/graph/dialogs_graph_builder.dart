import 'package:graphview/GraphView.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Построитель графа диалогов из списка шагов и заданного стиля
class DialogsGraphBuilder {
  DialogsGraphBuilder({required this.style});

  final GraphStyle style;

  /// Строит Graph: добавляет ноды и рёбра next/branch_logic. Возвращает готовый граф.
  Graph build(List<DialogStep> steps) {
    final graph = Graph()..isTree = (style.layoutType == GraphLayoutType.buchheimTopBottom);

    // Индексация нод
    final nodeById = <int, Node>{};
    for (final s in steps) {
      final n = Node.Id(s.id);
      nodeById[s.id] = n;
      graph.addNode(n);
    }

    // next (по умолчанию чёрные)
    for (final s in steps) {
      if (s.next != null && s.next! > 0) {
        final from = nodeById[s.id];
        final to = nodeById[s.next!];
        if (from != null && to != null) {
          graph.addEdge(from, to, paint: style.edgeNextPaint);
        }
      }
    }

    // branch_logic (оранжевые)
    // Для Buchheim (дерева) пропускаем ветвления, чтобы сохранить древовидность (один родитель у узла)
    final allowBranches = style.layoutType != GraphLayoutType.buchheimTopBottom;
    if (allowBranches) {
      for (final s in steps) {
        if (s.branchLogic.isEmpty) continue;
        for (final mapping in s.branchLogic.values) {
          for (final entry in mapping.entries) {
            final toId = entry.value;
            if (toId <= 0) continue;
            final from = nodeById[s.id];
            final to = nodeById[toId];
            if (from != null && to != null) {
              graph.addEdge(from, to, paint: style.edgeBranchPaint);
            }
          }
        }
      }
    }

    return graph;
  }
}

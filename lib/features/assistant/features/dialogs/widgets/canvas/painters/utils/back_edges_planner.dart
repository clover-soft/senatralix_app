import 'dart:math' as math;
import 'package:flutter/material.dart';

/// DTO: информация о ряду
class RowInfo {
  final int index;
  final double y;
  final List<int> nodeIds;
  final double minX;
  final double maxX;
  double get width => maxX - minX;

  RowInfo({
    required this.index,
    required this.y,
    required this.nodeIds,
    required this.minX,
    required this.maxX,
  });
}

/// DTO: горизонтальный сегмент (полка) для группы рёбер
class ShelfSegment {
  final int rowIndex; // ряд у края которого идёт полка
  final bool toLeft; // полка уходит к левому краю (true) или к правому (false)
  final int lane; // эшелон
  final double y; // вертикаль полки
  final double x1; // начало по X
  final double x2; // конец по X (край ряда ± overshoot)
  final List<MapEntry<int, int>> edges; // рёбра, которые по ней идут

  ShelfSegment({
    required this.rowIndex,
    required this.toLeft,
    required this.lane,
    required this.y,
    required this.x1,
    required this.x2,
    required this.edges,
  });
}

/// Вспомогательная структура для предварительной геометрии ребра (до подбора lane)
class _PreEdge {
  final MapEntry<int, int> edge;
  final Offset from;
  final Offset to;
  final Offset srcTop;
  final Offset dstTop;
  final int srcRowIdx;
  final bool toLeft;
  final int shelfRowIdx;
  final double shelfX;
  final double baseShelfY; // p1.y = srcTop.y - lift
  final double approachY; // dstTop.y - lift

  _PreEdge(
    this.edge,
    this.from,
    this.to,
    this.srcTop,
    this.dstTop,
    this.srcRowIdx,
    this.toLeft,
    this.shelfRowIdx,
    this.shelfX,
    this.baseShelfY,
    this.approachY,
  );
}

/// DTO: план для одного ребра (контрольные точки пути без скругления)
class EdgePlan {
  final MapEntry<int, int> edge;
  final Offset srcTop;
  final Offset dstTop;
  final bool toLeft;
  final int shelfRowIndex;
  final int lane;
  final double shelfY;
  final double shelfX;
  final List<Offset> points; // p1..p5

  EdgePlan({
    required this.edge,
    required this.srcTop,
    required this.dstTop,
    required this.toLeft,
    required this.shelfRowIndex,
    required this.lane,
    required this.shelfY,
    required this.shelfX,
    required this.points,
  });
}

/// Итоговый план обратных рёбер
class BackEdgesPlan {
  final List<RowInfo> rows;
  final List<ShelfSegment> shelves;
  final Map<MapEntry<int, int>, EdgePlan> edgePlans;

  BackEdgesPlan({
    required this.rows,
    required this.shelves,
    required this.edgePlans,
  });
}

/// Планировщик: считает ряды и план горизонтальных полок; стратегия hash
class BackEdgesPlanner {
  const BackEdgesPlanner();

  BackEdgesPlan computePlan({
    required Map<int, Offset> positions,
    required Size nodeSize,
    required List<MapEntry<int, int>> allEdges,
    required double exitFactor,
    required double approachFactor,
    required double exitOffset,
    required double approachOffset,
    required double lift,
    required double overshoot,
    required double shelfSpacing,
    required int shelfMaxLanes,
    required double approachSpacingX,
    required int approachMaxPush,
    required double approachEchelonSpacingY,
    required int approachMaxLanesY,
  }) {
    // 1) Ряды
    final rows = _computeRows(positions);
    final rowInfos = _rowInfos(rows, positions, nodeSize);

    // 2) Предварительная геометрия для всех рёбер
    final shelves = <ShelfSegment>[];
    final plans = <MapEntry<int, int>, EdgePlan>{};

    final pre = <_PreEdge>[];
    for (final e in allEdges) {
      final from = positions[e.key]!;
      final to = positions[e.value]!;
      if (!(from.dy > to.dy)) continue; // только back-edges вверх

      final srcTop = Offset(
        from.dx + nodeSize.width * exitFactor + exitOffset,
        from.dy,
      );
      final dstTop = Offset(
        to.dx + nodeSize.width * approachFactor + approachOffset,
        to.dy,
      );
      final p1 = srcTop.translate(0, -lift);

      final srcRowIdx = _findRowIndexForY(rows, positions, from.dy);
      final rowCenters =
          rows[srcRowIdx]
              .map((id) => positions[id]!.dx + nodeSize.width / 2)
              .toList()
            ..sort();
      final medianX = rowCenters[rowCenters.length ~/ 2];
      final srcCenterX = from.dx + nodeSize.width / 2;
      final toLeft = srcCenterX < medianX;

      final widestUpper = _findWidestUpperRowIndex(
        rows,
        positions,
        nodeSize,
        from.dy,
      );
      final shelfRowIdx = widestUpper ?? srcRowIdx;
      final extent = _rowExtent(rows[shelfRowIdx], positions, nodeSize);
      final shelfX = toLeft ? (extent.$1 - overshoot) : (extent.$2 + overshoot);
      final baseShelfY = p1.dy;
      final approachY = dstTop.dy - lift;

      pre.add(
        _PreEdge(
          e,
          from,
          to,
          srcTop,
          dstTop,
          srcRowIdx,
          toLeft,
          shelfRowIdx,
          shelfX,
          baseShelfY,
          approachY,
        ),
      );
    }

    // 3) Построим интервалы подходов (независимы от lane)
    final approachIntervals =
        <MapEntry<int, int>, (double y, double x1, double x2)>{};
    for (final pe in pre) {
      final ax1 = math.min(pe.shelfX, pe.dstTop.dx);
      final ax2 = math.max(pe.shelfX, pe.dstTop.dx);
      approachIntervals[pe.edge] = (pe.approachY, ax1, ax2);
    }

    // 4) Подбираем lane для каждой полки, избегая совпадений с подходами и уже занятыми полками на том же y
    final usedShelves =
        <
          (double y, double x1, double x2)
        >[]; // для проверки перекрытий полка-полка
    for (final pe in pre) {
      int lane = _laneHash(pe.edge, pe.shelfRowIdx, pe.toLeft, shelfMaxLanes);
      double shelfY = pe.baseShelfY - lane * shelfSpacing;
      final sx1 = math.min(pe.srcTop.dx, pe.shelfX);
      final sx2 = math.max(pe.srcTop.dx, pe.shelfX);

      bool conflict;
      int guard = shelfMaxLanes * 2 + 4; // защита от бесконечного цикла
      do {
        conflict = false;
        // Против подходов
        approachIntervals.forEach((edgeA, a) {
          if (edgeA == pe.edge) return; // свой подход не сравниваем
          if ((shelfY - a.$1).abs() <= 0.5) {
            final overlap = math.max(
              0.0,
              math.min(sx2, a.$3) - math.max(sx1, a.$2),
            );
            if (overlap > 1.0) {
              conflict = true;
            }
          }
        });
        // Против уже занятых полок
        for (final u in usedShelves) {
          if ((shelfY - u.$1).abs() <= 0.5) {
            final overlap = math.max(
              0.0,
              math.min(sx2, u.$3) - math.max(sx1, u.$2),
            );
            if (overlap > 1.0) {
              conflict = true;
              break;
            }
          }
        }

        if (conflict) {
          lane = (lane + 1) % math.max(1, shelfMaxLanes);
          shelfY = pe.baseShelfY - lane * shelfSpacing;
        }
      } while (conflict && guard-- > 0);

      final p2 = Offset(pe.shelfX, shelfY);
      final p3 = Offset(p2.dx, pe.approachY);
      final p4 = Offset(pe.dstTop.dx, p3.dy);
      final p5 = pe.dstTop;

      final plan = EdgePlan(
        edge: pe.edge,
        srcTop: pe.srcTop,
        dstTop: pe.dstTop,
        toLeft: pe.toLeft,
        shelfRowIndex: pe.shelfRowIdx,
        lane: lane,
        shelfY: shelfY,
        shelfX: pe.shelfX,
        points: [Offset(pe.srcTop.dx, pe.baseShelfY), p2, p3, p4, p5],
      );
      plans[pe.edge] = plan;

      usedShelves.add((shelfY, sx1, sx2));

      shelves.add(
        ShelfSegment(
          rowIndex: pe.shelfRowIdx,
          toLeft: pe.toLeft,
          lane: lane,
          y: shelfY,
          x1: sx1,
          x2: sx2,
          edges: [pe.edge],
        ),
      );
    }

    // 5) Разведение подходов по X на одном уровне approachY (без изменения Y)
    // Группируем планы по уровню подхода
    final byApproachY = <double, List<EdgePlan>>{};
    for (var ep in plans.values) {
      final y = ep.points[2].dy; // p3.y
      byApproachY.putIfAbsent(y, () => []).add(ep);
    }

    byApproachY.forEach((y, list) {
      // сортируем по dstTop.x, чтобы формировать интервалы слева направо
      list.sort((a, b) => a.dstTop.dx.compareTo(b.dstTop.dx));
      final occupied = <(double x1, double x2)>[];
      for (final ep in list) {
        final baseP2 = ep.points[1];
        final dstX = ep.dstTop.dx;
        final dir = (dstX - baseP2.dx) >= 0
            ? -1.0
            : 1.0; // толкаем от приёмника
        Offset chosenP2 = baseP2;
        bool placed = false;
        for (int k = 0; k <= approachMaxPush; k++) {
          final candX = baseP2.dx + dir * k * approachSpacingX;
          final x1 = math.min(candX, dstX);
          final x2 = math.max(candX, dstX);
          bool overlaps = false;
          for (final occ in occupied) {
            final overlap = math.max(
              0.0,
              math.min(x2, occ.$2) - math.max(x1, occ.$1),
            );
            if (overlap > 1.0) {
              overlaps = true;
              break;
            }
          }
          if (!overlaps) {
            chosenP2 = Offset(candX, baseP2.dy);
            occupied.add((x1, x2));
            placed = true;
            break;
          }
        }
        if (!placed) {
          // если не нашли место — оставляем базовый
          final x1 = math.min(baseP2.dx, dstX);
          final x2 = math.max(baseP2.dx, dstX);
          occupied.add((x1, x2));
        }
        // Обновляем точки ep с новым p2.x
        final p3 = ep.points[2];
        final newP4 = Offset(ep.dstTop.dx, p3.dy);
        ep.points[1] = chosenP2;
        ep.points[3] = newP4;
      }
    });

    // 6) Микро-эшелоны по Y для подходов: назначаем laneY внутри группы одного approachY
    byApproachY.forEach((baseY, list) {
      // стабильное назначение laneY
      int nextLane = 0;
      for (final ep in list) {
        final laneY = nextLane % math.max(1, approachMaxLanesY);
        nextLane++;
        // смещаем p3.y (и p4.y) на -laneY*spacingY, затем короткий вертикальный стык до dstTop.y сохранится в p5
        final p3 = ep.points[2];
        final newP3 = Offset(p3.dx, baseY - laneY * approachEchelonSpacingY);
        final newP4 = Offset(ep.dstTop.dx, newP3.dy);
        ep.points[2] = newP3;
        ep.points[3] = newP4;
      }
    });

    return BackEdgesPlan(rows: rowInfos, shelves: shelves, edgePlans: plans);
  }

  // ----------------- helpers -----------------
  List<List<int>> _computeRows(Map<int, Offset> positions) {
    final entries = positions.entries.toList()
      ..sort((a, b) => a.value.dy.compareTo(b.value.dy));
    const eps = 0.5;
    final rows = <List<int>>[];
    double? currentY;
    for (final e in entries) {
      if (currentY == null || (e.value.dy - currentY).abs() > eps) {
        rows.add([e.key]);
        currentY = e.value.dy;
      } else {
        rows.last.add(e.key);
      }
    }
    return rows;
  }

  List<RowInfo> _rowInfos(
    List<List<int>> rows,
    Map<int, Offset> positions,
    Size nodeSize,
  ) {
    final result = <RowInfo>[];
    for (var i = 0; i < rows.length; i++) {
      final y = positions[rows[i].first]!.dy;
      final extent = _rowExtent(rows[i], positions, nodeSize);
      result.add(
        RowInfo(
          index: i,
          y: y,
          nodeIds: rows[i],
          minX: extent.$1,
          maxX: extent.$2,
        ),
      );
    }
    return result;
  }

  (double, double) _rowExtent(
    List<int> row,
    Map<int, Offset> positions,
    Size nodeSize,
  ) {
    final minX = row
        .map((id) => positions[id]!.dx)
        .reduce((a, b) => a < b ? a : b);
    final maxRight = row
        .map((id) => positions[id]!.dx + nodeSize.width)
        .reduce((a, b) => a > b ? a : b);
    return (minX, maxRight);
  }

  int _findRowIndexForY(
    List<List<int>> rows,
    Map<int, Offset> positions,
    double y,
  ) {
    const eps = 0.5;
    for (var i = 0; i < rows.length; i++) {
      final any = rows[i].first;
      if ((positions[any]!.dy - y).abs() <= eps) return i;
    }
    double best = double.infinity;
    int idx = 0;
    for (var i = 0; i < rows.length; i++) {
      final any = rows[i].first;
      final d = (positions[any]!.dy - y).abs();
      if (d < best) {
        best = d;
        idx = i;
      }
    }
    return idx;
  }

  int? _findWidestUpperRowIndex(
    List<List<int>> rows,
    Map<int, Offset> positions,
    Size nodeSize,
    double srcY,
  ) {
    int? bestIdx;
    double bestWidth = -1;
    for (var i = 0; i < rows.length; i++) {
      final y = positions[rows[i].first]!.dy;
      if (y >= srcY) continue;
      final extent = _rowExtent(rows[i], positions, nodeSize);
      final width = extent.$2 - extent.$1;
      if (width > bestWidth) {
        bestWidth = width;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  int _laneHash(
    MapEntry<int, int> e,
    int shelfRowIdx,
    bool toLeft,
    int maxLanes,
  ) {
    // JS-safe: 32-битный FNV-1a с маской, чтобы оставаться < 2^31
    int h = 0x811C9DC5; // 2166136261
    void mix(int v) {
      h ^= v;
      h = (h * 0x01000193) & 0x7fffffff; // *16777619 и маска на 31 бит
    }

    mix(e.key);
    mix(e.value);
    mix(shelfRowIdx);
    mix(toLeft ? 1 : 0);
    final int lane = h % math.max(1, maxLanes);
    return lane;
  }
}

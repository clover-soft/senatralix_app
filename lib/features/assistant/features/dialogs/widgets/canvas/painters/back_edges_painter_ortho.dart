import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/utils/back_edges_planner.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/utils/ortho_turns.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/utils/arrow_drawer.dart';

/// Ортогональный пейнтер обратных рёбер (углы 90° со скруглениями)
/// Выход из верхней грани источника, вход в верхнюю грань приёмника.
class BackEdgesPainterOrtho extends CustomPainter {
  final Map<int, Offset> positions;
  final Size nodeSize;
  final List<MapEntry<int, int>> allEdges;
  final Color color;
  final double strokeWidth;
  final double cornerRadius;
  final double verticalClearance;
  final double horizontalClearance;
  final double exitOffset;
  final double approachOffset;
  final double exitFactor;
  final double approachFactor;
  final bool approachFromTopOnly;
  final double minSegment;
  final bool arrowAttachAtEdgeMid;
  final bool arrowTriangleFilled;
  final double arrowTriangleBase;
  final double arrowTriangleHeight;
  final int filletVariant; // 0..3 ориентация дуги

  final Paint _stroke;
  final Paint _fill;
  final BackEdgesPlan? plan;

  BackEdgesPainterOrtho({
    required this.positions,
    required this.nodeSize,
    required this.allEdges,
    required this.color,
    required this.strokeWidth,
    required this.cornerRadius,
    required this.verticalClearance,
    required this.horizontalClearance,
    required this.exitOffset,
    required this.approachOffset,
    required this.exitFactor,
    required this.approachFactor,
    required this.approachFromTopOnly,
    required this.minSegment,
    required this.arrowAttachAtEdgeMid,
    required this.arrowTriangleFilled,
    required this.arrowTriangleBase,
    required this.arrowTriangleHeight,
    this.filletVariant = 2,
    this.plan,
  }) : _stroke = Paint()
         ..color = color
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth
         ..strokeCap = StrokeCap.round
         ..strokeJoin = StrokeJoin.round,
       _fill = Paint()
         ..color = color
         ..style = PaintingStyle.fill;

  // Группировка нод по Y-уровням (рядам)
  List<List<int>> _computeRows() {
    final entries = positions.entries.toList()
      ..sort((a, b) => a.value.dy.compareTo(b.value.dy));
    const double eps = 0.5; // допуск по Y
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

  // Экстенты (minX, maxX) для каждого ряда, в координатах левых/правых границ нод
  Map<int, (double, double)> _computeRowExtents(List<List<int>> rows) {
    final map = <int, (double, double)>{};
    for (var i = 0; i < rows.length; i++) {
      final minX = rows[i]
          .map((id) => positions[id]!.dx)
          .reduce((a, b) => a < b ? a : b);
      final maxRight = rows[i]
          .map((id) => positions[id]!.dx + nodeSize.width)
          .reduce((a, b) => a > b ? a : b);
      map[i] = (minX, maxRight);
    }
    return map;
  }

  int _findRowIndexForY(List<List<int>> rows, double y) {
    const double eps = 0.5;
    for (var i = 0; i < rows.length; i++) {
      final any = rows[i].first;
      if ((positions[any]!.dy - y).abs() <= eps) return i;
    }
    // fallback: ближайший
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
    Map<int, (double, double)> extents,
    double srcY,
  ) {
    int? bestIdx;
    double bestWidth = -1;
    for (var i = 0; i < rows.length; i++) {
      final y = positions[rows[i].first]!.dy;
      if (y >= srcY) continue; // только верхние ряды
      final (minX, maxRight) = extents[i]!;
      final width = maxRight - minX;
      if (width > bestWidth) {
        bestWidth = width;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Если есть централизованный план — рисуем строго по нему
    if (plan != null) {
      for (final ep in plan!.edgePlans.values) {
        final srcTop = ep.srcTop;
        final p1 = ep.points[0];
        final p2 = ep.points[1];
        final p3 = ep.points[2];
        final p4 = ep.points[3];
        final p5 = ep.points[4];

        // Нормализация точек из планера: приводим к ортогональному шаблону
        // Берём более «высокую» (меньшую по Y) из p1/p2 для уровня первой полки, чтобы избежать наложения
        final double shelfY = (p1.dy < p2.dy) ? p1.dy : p2.dy;
        final pp1 = Offset(
          p1.dx,
          shelfY,
        ); // вертикальный подъём от srcTop до shelfY
        final pp2 = Offset(
          p2.dx,
          shelfY,
        ); // горизонтальная полка на уровне shelfY
        final pp3 = Offset(
          pp2.dx,
          p3.dy,
        ); // вертикальный подъём/спуск до уровня подхода
        final pp4 = Offset(p4.dx, pp3.dy); // горизонталь до оси входа
        final pp5 = p5; // вертикаль вниз к стрелке

        final path = Path();
        _moveTo(path, srcTop);
        // Скругления в 4 углах по тройкам точек с нормализованными точками
        _filletAtCorner(path, srcTop, pp1, pp2);
        _filletAtCorner(path, pp1, pp2, pp3);
        _filletAtCorner(path, pp2, pp3, pp4);
        _filletAtCorner(path, pp3, pp4, pp5);
        // Финальный довод до середины основания стрелки
        final baseMidPlanned = computeArrowBaseMidDown(
          tipPoint: ep.dstTop,
          height: arrowTriangleHeight,
        );
        path.lineTo(baseMidPlanned.dx, baseMidPlanned.dy);

        canvas.drawPath(path, _stroke);
        drawTriangleArrowDown(
          canvas: canvas,
          tipPoint: ep.dstTop,
          base: arrowTriangleBase,
          height: arrowTriangleHeight,
          filled: arrowTriangleFilled,
          stroke: _stroke,
          fill: _fill,
        );
      }
      return;
    }
    // Подготовим ряды (группировка по Y) и экстенты рядов
    final rows = _computeRows();
    final rowExtents = _computeRowExtents(rows);

    for (final e in allEdges) {
      final from = positions[e.key];
      final to = positions[e.value];
      if (from == null || to == null) continue;

      // Выход и вход по верхней грани с учётом факторов 0..1 (по умолчанию 0.75)
      final srcTop = Offset(
        from.dx + nodeSize.width * exitFactor + exitOffset,
        from.dy,
      );
      final dstTop = Offset(
        to.dx + nodeSize.width * approachFactor + approachOffset,
        to.dy,
      );

      // Шаг 1: подняться вверх от источника на lift из настроек (ортогональный подъём)
      final double lift = verticalClearance > 0 ? verticalClearance : 20.0;
      final p1 = srcTop.translate(0, -lift);

      // Определим индекс ряда источника и его «сторону» (лево/право/центр→право)
      final srcRowIdx = _findRowIndexForY(rows, from.dy);
      // Центр ряда по X — медиана центров нод
      final rowCenters =
          rows[srcRowIdx]
              .map((id) => positions[id]!.dx + nodeSize.width / 2)
              .toList()
            ..sort();
      final medianX = rowCenters[rowCenters.length ~/ 2];
      final srcCenterX = from.dx + nodeSize.width / 2;
      final goLeft = srcCenterX < medianX;

      // Выберем самый широкий ряд С ВЕРХУ (только ряды с y < from.dy)
      final widestUpperRowIdx = _findWidestUpperRowIndex(
        rows,
        rowExtents,
        from.dy,
      );
      // Если нет рядов сверху — используем экстент текущего ряда
      final extent = widestUpperRowIdx != null
          ? rowExtents[widestUpperRowIdx]!
          : rowExtents[srcRowIdx]!;
      // Граница ряда с выносом 20px
      const double overshoot = 20.0;
      final shelfY = p1.dy; // полка идёт на высоте p1
      final shelfX = goLeft ? (extent.$1 - overshoot) : (extent.$2 + overshoot);
      final p2 = Offset(shelfX, shelfY);

      // Шаг 3: от края ряда повернуть вверх и подняться до уровня (topY приёмника - 20)
      final upToY = dstTop.dy - lift;
      final p3 = Offset(p2.dx, upToY);

      // Шаг 4: повернуть к приёмнику и идти горизонтально до оси входа (dstTop.dx)
      final p4 = Offset(dstTop.dx, p3.dy);

      // Шаг 5: повернуть вниз к стрелке (dstTop)
      final p5 = dstTop;

      // Строим ортогональный путь со скруглениями
      final path = Path();
      _moveTo(path, srcTop);
      _filletAtCorner(path, srcTop, p1, p2);
      _filletAtCorner(path, p1, p2, p3);
      _filletAtCorner(path, p2, p3, p4);
      _filletAtCorner(path, p3, p4, p5);
      final baseMid = computeArrowBaseMidDown(
        tipPoint: dstTop,
        height: arrowTriangleHeight,
      );
      path.lineTo(baseMid.dx, baseMid.dy);

      canvas.drawPath(path, _stroke);
      drawTriangleArrowDown(
        canvas: canvas,
        tipPoint: dstTop,
        base: arrowTriangleBase,
        height: arrowTriangleHeight,
        filled: arrowTriangleFilled,
        stroke: _stroke,
        fill: _fill,
      );
    }
  }

  // Перемещение пера
  void _moveTo(Path path, Offset p) {
    path.moveTo(p.dx, p.dy);
  }

  // Скругление в угловой точке corner между отрезками prev->corner и corner->next
  // Делегируем построение новой функции addOrthoFilletFromSegments
  void _filletAtCorner(Path path, Offset prev, Offset corner, Offset next) {
    addOrthoFilletFromSegments(
      path,
      inStart: prev,
      inEnd: corner,
      outStart: corner,
      outEnd: next,
      radius: cornerRadius,
      minSegment: minSegment,
    );
  }

  // (удалено) _lineOrFillet — больше не используется

  // Удалена старая локальная реализация поворота (_addOrthoTurn, _filletTo) — используем utils/ortho_turns.dart

  // (удалено) локальный рисовальщик стрелки — используем utils/arrow_drawer.dart

  @override
  bool shouldRepaint(covariant BackEdgesPainterOrtho old) {
    return positions != old.positions ||
        nodeSize != old.nodeSize ||
        allEdges != old.allEdges ||
        color != old.color ||
        strokeWidth != old.strokeWidth ||
        cornerRadius != old.cornerRadius ||
        verticalClearance != old.verticalClearance ||
        horizontalClearance != old.horizontalClearance ||
        exitOffset != old.exitOffset ||
        approachOffset != old.approachOffset ||
        approachFromTopOnly != old.approachFromTopOnly ||
        minSegment != old.minSegment ||
        arrowAttachAtEdgeMid != old.arrowAttachAtEdgeMid ||
        arrowTriangleFilled != old.arrowTriangleFilled ||
        arrowTriangleBase != old.arrowTriangleBase ||
        arrowTriangleHeight != old.arrowTriangleHeight ||
        filletVariant != old.filletVariant;
  }
}

import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/utils/arrow_drawer.dart';

class EdgesPainter extends CustomPainter {
  EdgesPainter({
    required this.positions,
    required this.edges,
    required this.nodeSize,
    required this.color,
    required this.strokeWidth,
  });

  final Map<int, Offset> positions;
  final List<MapEntry<int, int>> edges;
  final Size nodeSize;
  final Color color;
  final double strokeWidth;

  // Параметры отрисовки рёбер
  static const double curvature = 60.0; // вертикальная кривизна Безье
  static const double parallelSep = 12.0; // разведение параллельных рёбер по X
  static const double arrowLen = 10.0; // длина стрелки
  static const double arrowDeg = 22.0; // угол лучей стрелки в градусах
  static const double portPadding = 6.0; // отступ от границы ноды для порта

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Предподсчёт групп параллельных рёбер (from->to)
    final Map<String, int> totalPerPair = {};
    for (final e in edges) {
      final key = '${e.key}->${e.value}';
      totalPerPair.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
    final Map<String, int> seenPerPair = {};

    for (final e in edges) {
      final fromPos = positions[e.key];
      final toPos = positions[e.value];
      if (fromPos == null || toPos == null) continue;

      // Разведение параллельных рёбер
      final key = '${e.key}->${e.value}';
      final total = totalPerPair[key] ?? 1;
      final seen = seenPerPair.update(key, (v) => v + 1, ifAbsent: () => 0);
      final offsetIndex = seen - (total - 1) / 2.0; // симметричное распределение
      final dxSep = offsetIndex * parallelSep;

      // Порты: выход снизу исходной ноды и вход сверху целевой ноды
      final p0 = Offset(
        fromPos.dx + nodeSize.width / 2 + dxSep,
        fromPos.dy + nodeSize.height, // без отступа: выходим прямо из грани
      );
      final p1 = Offset(
        toPos.dx + nodeSize.width / 2 + dxSep,
        toPos.dy - portPadding,
      );
      // Кончик стрелки должен лежать на верхней грани целевой ноды (без отступа)
      final entryTip = Offset(p1.dx, toPos.dy);

      // Контрольные точки кубической Безье
      final c1 = Offset(p0.dx, p0.dy + curvature);
      final c2 = Offset(p1.dx, p1.dy - curvature);

      // Середина основания стрелки (для стыковки линии)
      final arrowTangent = Offset(p1.dx - c2.dx, p1.dy - c2.dy);
      final arrowHeight = 12.0;
      final arrowBase = 8.0;
      final baseMid = computeArrowBaseMidAlong(
        tipPoint: entryTip,
        tangent: arrowTangent,
        height: arrowHeight,
      );

      // Кривая доводится до середины основания стрелки
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, baseMid.dx, baseMid.dy);
      canvas.drawPath(path, paint);

      // Треугольная стрелка по касательной
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      drawTriangleArrowAlong(
        canvas: canvas,
        tipPoint: entryTip,
        tangent: arrowTangent,
        base: arrowBase,
        height: arrowHeight,
        filled: true,
        stroke: paint,
        fill: fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EdgesPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.edges != edges ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.nodeSize != nodeSize;
  }
}

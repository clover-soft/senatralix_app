import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/canvas/painters/utils/arrow_drawer.dart';

/// Рисует обратные рёбра (идущие вверх) с обходом сверху.
class BackEdgesPainter extends CustomPainter {
  BackEdgesPainter({
    required this.positions,
    required this.nodeSize,
    required this.allEdges,
    required this.color,
    required this.strokeWidth,
  });

  final Map<int, Offset> positions;
  final Size nodeSize;
  final List<MapEntry<int, int>> allEdges;
  final Color color;
  final double strokeWidth;

  static const double topBypass = 60.0; // подъём для обхода сверху
  static const double portPadding = 6.0; // отступ от ноды

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final e in allEdges) {
      final from = positions[e.key];
      final to = positions[e.value];
      if (from == null || to == null) continue;
      // Ищем только обратные рёбра: вверх (from выше по Y)
      if (from.dy <= to.dy) continue;

      // Порты: выход сверху из исходной ноды, вход сверху в целевую
      final p0 = Offset(
        from.dx + nodeSize.width / 2,
        from.dy - portPadding,
      );
      final p1 = Offset(
        to.dx + nodeSize.width / 2,
        to.dy - portPadding,
      );

      // Обход сверху одной горизонтальной полкой
      final topY = math.min(p0.dy, p1.dy) - topBypass;
      final c1 = Offset(p0.dx, topY);
      final c2 = Offset(p1.dx, topY);

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
      canvas.drawPath(path, paint);

      // Треугольная стрелка по касательной
      drawTriangleArrowAlong(
        canvas: canvas,
        tipPoint: p1,
        tangent: Offset(p1.dx - c2.dx, p1.dy - c2.dy),
        base: 8.0,
        height: 12.0,
        filled: true,
        stroke: paint,
        fill: Paint()..color = color..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackEdgesPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.allEdges != allEdges ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.nodeSize != nodeSize;
  }
}

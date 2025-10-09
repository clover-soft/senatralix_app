import 'dart:math' as math;
import 'package:flutter/material.dart';

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

      // Стрелка (две линии) у конца p1 по касательной
      final tangent = Offset(p1.dx - c2.dx, p1.dy - c2.dy);
      final len = math.max(1e-6, tangent.distance);
      final ux = tangent.dx / len;
      final uy = tangent.dy / len;
      final baseAngle = math.atan2(uy, ux) + math.pi; // назад от кончика
      const arrowLen = 10.0;
      const a = 22.0 * math.pi / 180.0;
      final leftAngle = baseAngle + a;
      final rightAngle = baseAngle - a;
      final left = Offset(
        p1.dx + arrowLen * math.cos(leftAngle),
        p1.dy + arrowLen * math.sin(leftAngle),
      );
      final right = Offset(
        p1.dx + arrowLen * math.cos(rightAngle),
        p1.dy + arrowLen * math.sin(rightAngle),
      );
      canvas.drawLine(p1, left, paint);
      canvas.drawLine(p1, right, paint);
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

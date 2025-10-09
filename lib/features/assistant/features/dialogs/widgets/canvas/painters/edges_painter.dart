import 'dart:math' as math;
import 'package:flutter/material.dart';

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
        fromPos.dy + nodeSize.height + portPadding,
      );
      final p1 = Offset(
        toPos.dx + nodeSize.width / 2 + dxSep,
        toPos.dy - portPadding,
      );

      // Контрольные точки кубической Безье
      final c1 = Offset(p0.dx, p0.dy + curvature);
      final c2 = Offset(p1.dx, p1.dy - curvature);

      // Кривая
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
      canvas.drawPath(path, paint);

      // Стрелка по касательной в конце кривой
      final tangent = Offset(p1.dx - c2.dx, p1.dy - c2.dy);
      final len = math.max(1e-6, tangent.distance);
      final ux = tangent.dx / len;
      final uy = tangent.dy / len;
      final baseAngle = math.atan2(uy, ux) + math.pi; // направление назад от кончика
      final a = arrowDeg * math.pi / 180.0;
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
  bool shouldRepaint(covariant EdgesPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.edges != edges ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.nodeSize != nodeSize;
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:sentralix_app/features/assistant/features/dialogs/graph/centered_layered_layout.dart';

class DialogsCenteredCanvas extends StatelessWidget {
  const DialogsCenteredCanvas({
    super.key,
    required this.layout,
    required this.nodeSize,
    required this.buildNode,
    this.transformationController,
    this.contentKey,
  });

  final CenteredLayoutResult layout;
  final Size nodeSize;
  final Widget Function(int stepId, Key? key) buildNode;
  final TransformationController? transformationController;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    final content = RepaintBoundary(
      key: contentKey,
      child: Stack(
        children: [
          // Полотно нужного размера
          SizedBox(width: layout.canvasSize.width, height: layout.canvasSize.height),
          // Рёбра next (чёрные)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EdgesPainter(
                  positions: layout.positions,
                  edges: layout.nextEdges,
                  nodeSize: nodeSize,
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          // Рёбра branch (оранжевые)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EdgesPainter(
                  positions: layout.positions,
                  edges: layout.branchEdges,
                  nodeSize: nodeSize,
                  color: const Color(0xFFFF9800),
                  strokeWidth: 1.6,
                ),
              ),
            ),
          ),
          // Узлы
          ...layout.positions.entries.map(
            (e) => Positioned(
              left: e.value.dx,
              top: e.value.dy,
              width: nodeSize.width,
              height: nodeSize.height,
              child: buildNode(e.key, Key(e.key.toString())),
            ),
          ),
        ],
      ),
    );

    return SizedBox.expand(
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(4000),
        clipBehavior: Clip.none,
        transformationController: transformationController,
        child: content,
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
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
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.edges != edges ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.nodeSize != nodeSize;
  }
}

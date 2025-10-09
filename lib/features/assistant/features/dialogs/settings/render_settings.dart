import 'package:flutter/material.dart';

/// Настройки рендера (цвета, толщины, параметры стрелок/кривых)
class RenderSettings {
  // Цвета рёбер
  final Color nextEdgeColor;
  final Color branchEdgeColor;
  final Color backEdgeColor;

  // Толщины
  final double nextEdgeStrokeWidth;
  final double branchEdgeStrokeWidth;
  final double backEdgeStrokeWidth;

  // Геометрия стрелок/кривых
  final double arrowLength;
  final double arrowDegrees;
  final double curvature;
  final double parallelSeparation;
  final double portPadding;

  const RenderSettings({
    this.nextEdgeColor = Colors.black,
    this.branchEdgeColor = const Color(0xFFFF9800),
    this.backEdgeColor = const Color(0xFFEA4335),
    this.nextEdgeStrokeWidth = 2.0,
    this.branchEdgeStrokeWidth = 1.6,
    this.backEdgeStrokeWidth = 1.8,
    this.arrowLength = 10.0,
    this.arrowDegrees = 22.0,
    this.curvature = 60.0,
    this.parallelSeparation = 12.0,
    this.portPadding = 6.0,
  });
}

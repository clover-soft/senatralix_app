import 'package:flutter/widgets.dart';

/// Параметры раскладки графа (геометрия уровней и узлов)
class LayoutSettings {
  final Size nodeSize;
  final double nodeSeparation;
  final double levelSeparation;
  final double padding;

  const LayoutSettings({
    this.nodeSize = const Size(240, 120),
    this.nodeSeparation = 32,
    this.levelSeparation = 120,
    this.padding = 80,
  });
}

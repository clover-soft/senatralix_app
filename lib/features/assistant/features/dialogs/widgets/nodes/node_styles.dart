import 'package:flutter/material.dart';

/// Стилевые константы и удобные пресеты для нод графа
class NodeStyles {
  // Базовые цвета карточек нод
  final Color background;
  final Color border;
  final Color titleColor;
  final Color subtitleColor;
  final Color selectedBorder;

  // Отступы и радиусы
  final EdgeInsets padding;
  final double borderRadius;
  final double borderWidth;

  const NodeStyles({
    this.background = const Color(0xFFF9FAFB),
    this.border = const Color(0xFFE5E7EB),
    this.titleColor = const Color(0xFF111827),
    this.subtitleColor = const Color(0xFF6B7280),
    this.selectedBorder = const Color(0xFF3B82F6),
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
    this.borderWidth = 1,
  });
}

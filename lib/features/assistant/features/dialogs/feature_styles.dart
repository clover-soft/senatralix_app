import 'package:flutter/material.dart';

/// Глобальные стилевые настройки подфичи Dialogs
/// Содержит параметры карточек нод и настройки рёбер графа
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

  // Геометрия карточки
  final double cardWidth; // целевая ширина карточки
  final double cardHeight; // целевая высота карточки

  // Типографика заголовка и инструкции
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final String? titleFontFamily;
  final double instructionFontSize;
  final FontWeight instructionFontWeight;
  final String? instructionFontFamily;

  // Пресеты цветов бейджей (текст/фон)
  final Color badgePrimaryFg;
  final Color badgePrimaryBg;
  final Color badgeSuccessFg;
  final Color badgeSuccessBg;
  final Color badgeWarningFg;
  final Color badgeWarningBg;
  final Color badgeInfoFg;
  final Color badgeInfoBg;
  final Color badgeNeutralFg;
  final Color badgeNeutralBg;

  // Цвета и толщины рёбер графа
  final Color nextEdgeColor;
  final Color branchEdgeColor;
  final Color backEdgeColor;
  final double nextEdgeStrokeWidth;
  final double branchEdgeStrokeWidth;
  final double backEdgeStrokeWidth;

  const NodeStyles({
    // Карточка
    this.background = const Color.fromARGB(255, 205, 235, 197),
    this.border = const Color.fromARGB(255, 132, 156, 135),
    this.titleColor = const Color.fromARGB(255, 40, 40, 40),
    this.subtitleColor = const Color.fromARGB(149, 107, 114, 128),
    this.selectedBorder = const Color(0xFF3B82F6),
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 20,
    this.borderWidth = 6,
    this.cardWidth = 260,
    this.cardHeight = 160,

    // Типографика
    this.titleFontSize = 18.5,
    this.titleFontWeight = FontWeight.w700,
    this.titleFontFamily = 'Roboto',
    this.instructionFontSize = 15.5,
    this.instructionFontWeight = FontWeight.w500,
    this.instructionFontFamily = 'Roboto',

    // badge presets
    this.badgePrimaryFg = const Color(0xFF1D4ED8),
    this.badgePrimaryBg = const Color(0xFFEFF6FF),
    this.badgeSuccessFg = const Color(0xFF065F46),
    this.badgeSuccessBg = const Color(0xFFD1FAE5),
    this.badgeWarningFg = const Color(0xFFEF6C00),
    this.badgeWarningBg = const Color(0xFFFFF3E0),
    this.badgeInfoFg = const Color(0xFF0369A1),
    this.badgeInfoBg = const Color(0xFFE0F2FE),
    this.badgeNeutralFg = const Color(0xFF111827),
    this.badgeNeutralBg = const Color(0xFFE5E7EB),

    // Рёбра графа (значения по умолчанию прежние)
    this.nextEdgeColor = const Color.fromARGB(205, 47, 98, 0),
    this.branchEdgeColor = const Color(0xFFFF9800),
    this.backEdgeColor = const Color.fromARGB(255, 193, 86, 77),
    this.nextEdgeStrokeWidth = 4,
    this.branchEdgeStrokeWidth = 4,
    this.backEdgeStrokeWidth = 4,
  });
}

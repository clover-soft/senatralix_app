import 'package:flutter/material.dart';

/// Небольшой бейдж для отображения статуса/роли ноды
class NodeBadge extends StatelessWidget {
  const NodeBadge({
    super.key,
    required this.text,
    this.color = const Color(0xFF111827),
    this.background = const Color(0xFFE5E7EB),
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = 999,
  });

  /// Текст бейджа
  final String text;

  /// Цвет текста/иконки
  final Color color;

  /// Цвет фона бейджа
  final Color background;

  /// Иконка слева (необязательно)
  final IconData? icon;

  /// Внутренние отступы
  final EdgeInsets padding;

  /// Радиус скругления
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final row = <Widget>[];
    if (icon != null) {
      row.add(Icon(icon, size: 14, color: color));
      row.add(const SizedBox(width: 4));
    }
    row.add(Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        height: 1.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ));

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: row,
      ),
    );
  }
}

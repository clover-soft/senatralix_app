import 'package:flutter/material.dart';
import 'node_badges.dart';
import 'node_styles.dart';

/// Базовый виджет ноды диалогового графа.
/// Отображает заголовок, подзаголовок, набор бейджей и кастомное наполнение (children).
class DialogNodeWidget extends StatelessWidget {
  const DialogNodeWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.badges = const <NodeBadge>[],
    this.selected = false,
    this.onTap,
    this.styles = const NodeStyles(),
    this.trailing,
    this.child,
  });

  /// Заголовок ноды (обычно label шага)
  final String title;

  /// Доп. подзаголовок (например, краткое описание)
  final String? subtitle;

  /// Бейджи со статусами
  final List<NodeBadge> badges;

  /// Состояние выделения (меняет цвет рамки)
  final bool selected;

  /// Обработчик клика по карточке
  final VoidCallback? onTap;

  /// Стилевые параметры
  final NodeStyles styles;

  /// Правый верхний элемент (иконка/меню)
  final Widget? trailing;

  /// Доп. контент внизу карточки
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? styles.selectedBorder : styles.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(styles.borderRadius),
        child: Container(
          padding: styles.padding,
          decoration: BoxDecoration(
            color: styles.background,
            border: Border.all(color: borderColor, width: styles.borderWidth),
            borderRadius: BorderRadius.circular(styles.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: styles.titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                color: styles.subtitleColor,
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: badges,
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: 8),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

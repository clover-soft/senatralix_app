import 'package:flutter/material.dart';
import 'node_badges.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/subfeature_styles.dart';

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
    this.styles = const SubfeatureStyles(),
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
  final SubfeatureStyles styles;

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
        child: SizedBox(
          width: styles.cardWidth,
          child: Container(
            padding: styles.padding,
            decoration: BoxDecoration(
              color: styles.background,
              border: Border.all(color: borderColor, width: styles.borderWidth),
              borderRadius: BorderRadius.circular(styles.borderRadius),
            ),
            child: SizedBox(
              height: styles.cardHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Заголовок (35%)
                  Expanded(
                    flex: 35,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: styles.titleColor,
                          fontSize: styles.titleFontSize,
                          fontWeight: styles.titleFontWeight,
                          height: 1.2,
                          fontFamily: styles.titleFontFamily,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // 2) Инструкция (50%) — без прокрутки, вычисляем maxLines по доступной высоте
                  Expanded(
                    flex: 50,
                    child: (subtitle != null && subtitle!.isNotEmpty)
                        ? LayoutBuilder(
                            builder: (ctx, constraints) {
                              final style = TextStyle(
                                color: styles.subtitleColor,
                                fontSize: styles.instructionFontSize,
                                fontWeight: styles.instructionFontWeight,
                                height: 1.3,
                                fontFamily: styles.instructionFontFamily,
                              );
                              final lineHeightPx =
                                  (style.fontSize ?? 14) *
                                  (style.height ?? 1.2);
                              final available = constraints.maxHeight.isFinite
                                  ? constraints.maxHeight
                                  : styles.cardHeight * 0.5;
                              final computedMaxLines =
                                  available > 0 && lineHeightPx > 0
                                  ? (available / lineHeightPx).floor().clamp(
                                      1,
                                      100,
                                    )
                                  : 3;
                              return Text(
                                subtitle!,
                                style: style,
                                maxLines: computedMaxLines,
                                overflow: TextOverflow.ellipsis,
                                textWidthBasis: TextWidthBasis.parent,
                                softWrap: true,
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  // 3) Панель с бейджами и кнопками (15%)
                  Expanded(
                    flex: 15,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Бейджи слева
                        if (badges.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: badges,
                            ),
                          )
                        else
                          const Spacer(),
                        // Кнопки справа
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                  // Дополнительный произвольный контент под полосой бейджей (если нужен)
                  if (child != null) ...[const SizedBox(height: 8), child!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

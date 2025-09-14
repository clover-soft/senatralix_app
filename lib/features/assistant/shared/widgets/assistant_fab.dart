import 'package:flutter/material.dart';

/// Унифицированная плавающая кнопка действия для подфич ассистента
/// Используется как значение для Scaffold.floatingActionButton.
class AssistantActionFab extends StatelessWidget {
  const AssistantActionFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.mini = false,
    this.heroTag,
    this.customChild,
  });

  /// Иконка на кнопке
  final IconData icon;

  /// Подсказка (tooltip)
  final String tooltip;

  /// Обработчик нажатия. Если null — кнопка будет disabled.
  final VoidCallback? onPressed;

  /// Меньший размер FAB
  final bool mini;

  /// Необязательный heroTag, если экран использует несколько FAB
  final Object? heroTag;

  /// Кастомный child. Если задан — используется вместо иконки
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: mini,
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      child: customChild ?? Icon(icon),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/nodes/node_actions_panel.dart';
import 'node_badges.dart';
import 'dialog_node_widget.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/subfeature_styles.dart';

/// Фабрика виджета ноды по модели DialogStep
class DialogNodeFactory {
  const DialogNodeFactory();

  /// Создаёт виджет ноды по шагу
  /// [onOpenMenu] — колбэк для кнопок действий (если требуется)
  Widget buildNodeFromStep(
    DialogStep step, {
    VoidCallback? onTap,
    VoidCallback? onOpenMenu,
    VoidCallback? onAddNext,
    VoidCallback? onDelete,
    SubfeatureStyles styles = const SubfeatureStyles(),
  }) {
    final isBranch = step.branchLogic.isNotEmpty;
    final isRoot = step.id == 1;

    final badges = <NodeBadge>[];
    if (isRoot) {
      badges.add(
        const NodeBadge(
          text: 'корень',
          background: Color(0xFFE0F2FE),
          color: Color(0xFF0369A1),
        ),
      );
    }
    if (isBranch) {
      badges.add(
        const NodeBadge(
          text: 'ветвление',
          background: Color(0xFFFFF3E0),
          color: Color(0xFFEF6C00),
        ),
      );
    }
    if (step.next != null && step.next! > 0 && step.branchLogic.isEmpty) {
      badges.add(
        const NodeBadge(
          text: 'следующий шаг',
          background: Color(0xFFEFF6FF),
          color: Color(0xFF1D4ED8),
        ),
      );
    }

    // Кнопку добавления шага показываем только если нет next и нет ветвлений
    final bool hasNext = step.next != null && step.next! > 0;
    final trailing = DialogsNodeActionsPanel(
      onAddNext: (hasNext || isBranch) ? null : onAddNext,
      onSettings: onOpenMenu,
      onDelete: onDelete,
    );

    return DialogNodeWidget(
      title: step.label.isNotEmpty ? step.label : step.name,
      subtitle: step.instructions.isNotEmpty ? step.instructions : null,
      badges: badges,
      selected: false,
      onTap: onTap,
      styles: styles,
      trailing: trailing,
    );
  }
}

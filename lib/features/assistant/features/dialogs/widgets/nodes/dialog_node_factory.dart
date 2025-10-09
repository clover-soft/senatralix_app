import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/nodes/node_actions_panel.dart';
import 'node_badges.dart';
import 'dialog_node_widget.dart';
import 'node_styles.dart';

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
    NodeStyles styles = const NodeStyles(),
  }) {
    final isBranch = step.branchLogic.isNotEmpty;
    final isRoot = step.id == 1;

    final badges = <NodeBadge>[];
    if (isRoot) {
      badges.add(const NodeBadge(text: 'root', background: Color(0xFFE0F2FE), color: Color(0xFF0369A1)));
    }
    if (isBranch) {
      badges.add(const NodeBadge(text: 'branch', background: Color(0xFFFFF3E0), color: Color(0xFFEF6C00)));
    }
    if (step.next != null && step.next! > 0 && step.branchLogic.isEmpty) {
      badges.add(const NodeBadge(text: 'next', background: Color(0xFFEFF6FF), color: Color(0xFF1D4ED8)));
    }

    final trailing = DialogsNodeActionsPanel(
      onAddNext: onAddNext,
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

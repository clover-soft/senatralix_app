import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:sentralix_app/features/assistant/models/assistant.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_feature_list_item.dart';

/// Элемент списка ассистентов на базе универсального AppListItem.
/// Позволяет переопределять leading/trailing (например, добавить переключатели/кнопки),
/// а центральную часть формирует из полей ассистента (имя/описание/мета-инфо).
class AssistantListItem extends StatelessWidget {
  final Assistant assistant;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AssistantListItem({
    super.key,
    required this.assistant,
    this.leading,
    this.trailing,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final defaultLeading = Icon(
      RemixIcons.robot_2_line,
      color: scheme.secondary,
    );

    final defaultTrailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: onDelete == null ? 'Удаление недоступно' : 'Удалить',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        const Icon(Icons.chevron_right),
      ],
    );

    final subtitle = (assistant.description?.isNotEmpty ?? false)
        ? assistant.description!
        : assistant.id;

    final meta = assistant.settings != null
        ? 'Модель: ${assistant.settings!.model}  •  Темп: ${assistant.settings!.temperature.toStringAsFixed(1)}'
        : null;

    return AssistantFeatureListItem(
      leadingIcon: leading ?? defaultLeading,
      trailing: trailing ?? defaultTrailing,
      title: assistant.name,
      subtitle: subtitle,
      meta: meta,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';

/// Универсальный элемент списка с настраиваемыми leading/trailing и центральным блоком
/// - leading: собирается из иконки и (опционально) мини-свитча
/// - trailing: любой виджет (иконки действий, индикаторы)
/// - title/subtitle: основная информация
/// - meta: служебные поля, например, параметры/состояние
class AssistantFeatureListItem extends StatelessWidget {
  // Новый API для leading
  final Widget? leadingIcon;
  final ValueChanged<bool>? onSwitchChanged;
  final bool? switchValue;
  final String? switchTooltip;

  final Widget? trailing;
  // Новый API для trailing
  final bool showDelete;
  final bool deleteEnabled;
  final bool showChevron;
  final Future<void> Function()? onDeletePressed;
  final String title;
  final String? subtitle;
  final String? meta;
  final VoidCallback? onTap;

  const AssistantFeatureListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leadingIcon,
    this.onSwitchChanged,
    this.switchValue,
    this.trailing,
    this.onTap,
    this.switchTooltip,
    this.showDelete = false,
    this.deleteEnabled = true,
    this.showChevron = true,
    this.onDeletePressed,
  });

  Widget? _buildLeading(BuildContext context) {
    final hasIcon = leadingIcon != null;
    // Свитч отображаем, если передано хотя бы значение (он может быть disabled при null-обработчике)
    final hasSwitch = switchValue != null;
    if (!hasIcon && !hasSwitch) return null;

    final children = <Widget>[];
    if (hasIcon) {
      children.add(leadingIcon!);
    }
    if (hasIcon && hasSwitch) {
      children.add(const SizedBox(width: 6));
    }
    if (hasSwitch) {
      final sw = Transform.scale(
        scale: 0.85,
        child: Switch(
          value: switchValue ?? false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: onSwitchChanged,
        ),
      );
      children.add(
        switchTooltip != null && switchTooltip!.isNotEmpty
            ? Tooltip(message: switchTooltip!, child: sw)
            : sw,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  /// Собирает trailing-часть: удаление (при наличии) и стрелка вправо (при наличии)
  Widget? _buildTrailing(BuildContext context) {
    final widgets = <Widget>[];
    if (showDelete) {
      widgets.add(
        IconButton(
          tooltip: deleteEnabled ? 'Удалить' : 'Удаление запрещено',
          icon: const Icon(Icons.delete_outline),
          onPressed: deleteEnabled
              ? () {
                  // Вызов без ожидания; обработчик может быть async
                  onDeletePressed?.call();
                }
              : null,
        ),
      );
    }
    if (showChevron) {
      widgets.add(const Icon(Icons.chevron_right));
    }
    if (widgets.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: _buildLeading(context),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
          if (meta != null && meta!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(meta!, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
      trailing: trailing ?? _buildTrailing(context),
      onTap: onTap,
    );
  }
}

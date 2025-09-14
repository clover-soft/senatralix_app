import 'package:flutter/material.dart';

/// Универсальный элемент списка с настраиваемыми leading/trailing и центральным блоком
/// - leading: собирается из иконки и (опционально) мини-свитча
/// - trailing: любой виджет (иконки действий, индикаторы)
/// - title/subtitle: основная информация
/// - meta: служебные поля, например, параметры/состояние
class AppListItem extends StatelessWidget {
  // Новый API для leading
  final Widget? leadingIcon;
  final ValueChanged<bool>? onSwitchChanged;
  final bool? switchValue;
  final String? switchTooltip;

  final Widget? trailing;
  final String title;
  final String? subtitle;
  final String? meta;
  final VoidCallback? onTap;

  const AppListItem({
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
  });

  Widget? _buildLeading(BuildContext context) {
    final hasIcon = leadingIcon != null;
    final hasSwitch = onSwitchChanged != null;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
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
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          if (meta != null && meta!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                meta!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

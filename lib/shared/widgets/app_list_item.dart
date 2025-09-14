import 'package:flutter/material.dart';

/// Универсальный элемент списка с настраиваемыми leading/trailing и центральным блоком
/// - leading: любой виджет (иконки, переключатели, аватары)
/// - trailing: любой виджет (иконки действий, индикаторы)
/// - title/subtitle: основная информация
/// - meta: служебные поля, например, параметры/состояние
class AppListItem extends StatelessWidget {
  final Widget? leading;
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
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: leading,
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
      trailing: trailing,
      onTap: onTap,
    );
  }
}

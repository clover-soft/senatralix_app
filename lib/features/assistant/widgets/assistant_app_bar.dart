import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';

/// Общий AppBar для экранов ассистента и его подфич
/// - Для домашнего экрана ассистента (локальное меню) используйте [subfeatureTitle == null]
///   • leading: назад к списку ассистентов
///   • title: "Assistant (Имя)"
/// - Для подфич (settings/tools/…): укажите [subfeatureTitle]
///   • leading: назад к локальному меню ассистента
///   • title: "Assistant • <Subfeature> (<Имя>)"
///   • actions: кнопка "домой ассистента"
class AssistantAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AssistantAppBar({
    super.key,
    required this.assistantId,
    this.subfeatureTitle,
    this.backPath,
    this.backTooltip,
    this.backPopFirst = false,
  });

  final String assistantId;
  final String? subfeatureTitle;
  // Если указан, кнопка "назад" ведёт по этому пути
  final String? backPath;
  // Текст подсказки для кнопки назад, если задан backPath
  final String? backTooltip;
  // Если true, при нажатии «назад» сначала будет попытка закрыть текущий экран (Navigator.pop)
  final bool backPopFirst;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(assistantListProvider).byId(assistantId)?.name ?? 'Unknown';
    final title = subfeatureTitle == null
        ? 'Assistant ($name)'
        : 'Assistant • ${subfeatureTitle!} ($name)';

    return AppBar(
      leading: IconButton(
        tooltip: backPath != null
            ? (backTooltip ?? 'Назад')
            : (subfeatureTitle == null ? 'К списку ассистентов' : 'К ассистенту'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (backPopFirst && Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
            return;
          }
          if (backPath != null) {
            context.go(backPath!);
          } else if (subfeatureTitle == null) {
            context.go('/assistant');
          } else {
            context.go('/assistant/$assistantId');
          }
        },
      ),
      actions: subfeatureTitle == null
          ? null
          : [
              IconButton(
                tooltip: 'Домой ассистента',
                icon: const Icon(Icons.home_outlined),
                onPressed: () => context.go('/assistant/$assistantId'),
              ),
            ],
      title: Text(title),
    );
  }
}

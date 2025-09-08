// comment: Trailing container for AppShell NavigationRail
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/shared/providers/shell_provider.dart';
import 'app_shell_rail_item.dart';

class AppShellLeading extends ConsumerWidget {
  final double width;
  final double expandedWidth;
  final bool expanded;
  const AppShellLeading({
    super.key,
    required this.width,
    required this.expandedWidth,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Локально задаём цвета иконки/лейбла как onPrimary, чтобы были контрастны к фону AppBar/primary
    final localNavTheme = theme.navigationRailTheme.copyWith(
      indicatorColor: Colors.transparent,
      selectedIconTheme: IconThemeData(color: scheme.onPrimary),
      unselectedIconTheme: IconThemeData(color: scheme.onPrimary),
      // Размер и стиль текста как у заголовка AppBar
      selectedLabelTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: scheme.onPrimary,
      ),
      unselectedLabelTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: scheme.onPrimary,
      ),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(0),
      curve: Curves.easeInOut,
      height: 56,
      // Используем тот же цвет, что и у AppBar — scheme.primary
      color: scheme.primary,
      width: expanded ? expandedWidth : width,

      child: SizedBox(
        width: expanded ? expandedWidth : width,
        child: Theme(
          data: theme.copyWith(navigationRailTheme: localNavTheme),
          child: Transform.translate(
            offset: const Offset(0, -6),
            child: AppShellRailItem(
              icon: Icons.menu,
              label: 'Sentralix',
              selected: false,
              onPressed: () {
                // Переключение состояния NavigationRail (expand/collapse)
                final expanded = ref.read(shellRailExpandedProvider);
                ref.read(shellRailExpandedProvider.notifier).state = !expanded;
              },
            ),
          ),
        ),
      ),
    );
  }
}

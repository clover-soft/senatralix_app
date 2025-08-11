// comment: Trailing container for AppShell NavigationRail
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_shell_rail_item.dart';

class AppShellTrailing extends StatelessWidget {
  final double width;
  final double expandedWidth;
  final bool expanded;
  const AppShellTrailing({
    super.key,
    required this.width,
    required this.expandedWidth,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool isProfile = currentPath.startsWith('/profile');
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        curve: Curves.easeInOut,
        // height: 80,
        width: expanded ? expandedWidth : width,
        // overflow hidden via decoration + clipBehavior
        decoration: const BoxDecoration(),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            AppShellRailItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: isProfile,
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

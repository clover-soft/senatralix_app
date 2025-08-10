// comment: AppShell - shared layout with left menu (Drawer/NavigationRail) and top bar with user avatar/menu on the left
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:sentralix_app/shared/providers/shell_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(shellRailExpandedProvider);
    int selectedIndex = 0; // 0 -> Dashboard

    final avatar = const CircleAvatar(child: Icon(Icons.person, size: 18));

    final userMenu = PopupMenuButton<String>(
      tooltip: 'User menu',
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
        PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
      onSelected: (v) {
        switch (v) {
          case 'profile':
            // TODO: implement profile route
            break;
          case 'settings':
            // TODO: implement settings route
            break;
          case 'logout':
            // comment: delegate to DashboardController -> Auth logout
            ref.read(dashboardControllerProvider).logout();
            break;
        }
      },
      child: avatar,
    );

    final rail = NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (idx) {
        switch (idx) {
          case 0:
            context.go('/');
            break;
        }
      },
      labelType: expanded ? null : NavigationRailLabelType.none,
      extended: expanded,
      // Leading: brand + toggle inside the rail, no top padding to reach very top
      leading: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: expanded
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Collapse menu',
                    onPressed: () => ref.read(shellRailExpandedProvider.notifier).state = false,
                    icon: const Icon(Icons.menu),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sentralix',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : IconButton(
                tooltip: 'Expand menu',
                onPressed: () => ref.read(shellRailExpandedProvider.notifier).state = true,
                icon: const Icon(Icons.menu),
              ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: userMenu,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
      ],
    );

    return Scaffold(
      body: Row(
        children: [
          rail,
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

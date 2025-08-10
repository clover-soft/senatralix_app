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
    // featureIndex: index of current feature destination (0 => Dashboard)
    int featureIndex = 0;
    // selectedIndex in rail: +1 because 0 is reserved for toggle/brand item
    int selectedIndex = featureIndex + 1;

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
        // idx 0 reserved for toggle item
        if (idx == 0) {
          ref.read(shellRailExpandedProvider.notifier).state = !expanded;
          return;
        }
        switch (idx) {
          case 1: // Dashboard
            context.go('/');
            break;
        }
      },
      labelType: expanded ? null : NavigationRailLabelType.none,
      extended: expanded,
      // No custom leading; toggle is the first destination for consistent styling
      leading: const SizedBox(height: 0),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: userMenu,
      ),
      destinations: [
        // 0: Toggle/Brand item — looks like a normal destination
        const NavigationRailDestination(
          icon: Icon(Icons.menu),
          selectedIcon: Icon(Icons.menu),
          label: Text('Sentralix'),
        ),
        // 1: Dashboard
        const NavigationRailDestination(
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

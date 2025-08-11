// comment: AppShell - shared layout with left menu (Drawer/NavigationRail) and top bar with user avatar/menu on the left
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/shared/providers/shell_provider.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell_trailing.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(shellRailExpandedProvider);
    final currentPath = GoRouterState.of(context).uri.path;
    final minExpandedWidth = 200.0;
    final minCollapsedWidth = 80.0;
    // featureIndex: index of current feature destination (0 => Dashboard)
    int? featureIndex;
    // Map known destinations to feature indices
    if (currentPath == '/') {
      featureIndex = 0; // Dashboard
    } else {
      featureIndex = null; // not a rail destination (e.g., /profile)
    }
    // selectedIndex in rail: +1 because 0 is reserved for toggle/brand item
    int selectedIndex = (featureIndex ?? 0) + 1; // keep in-bounds; will neutralize visuals when null
    final baseNavTheme = Theme.of(context).navigationRailTheme;
    final bool neutralizeSelection = featureIndex == null; // when on non-rail routes
    final NavigationRailThemeData overrideTheme = neutralizeSelection
        ? baseNavTheme.copyWith(
            indicatorColor: Colors.transparent,
            selectedIconTheme: baseNavTheme.unselectedIconTheme,
            selectedLabelTextStyle: baseNavTheme.unselectedLabelTextStyle,
          )
        : baseNavTheme;

    final rail = NavigationRail(
      minWidth: minCollapsedWidth,
      minExtendedWidth: minExpandedWidth,
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
      // externalized top/bottom areas
      trailing: AppShellTrailing(
        width: minCollapsedWidth,
        expandedWidth: minExpandedWidth,
        expanded: expanded,
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
          NavigationRailTheme(
            data: overrideTheme,
            child: rail,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// comment: AppShell - shared layout with left menu (Drawer/NavigationRail) and top bar with user avatar/menu on the left
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/shared/providers/shell_provider.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell_trailing.dart';
import 'package:sentralix_app/data/providers/context_data_provider.dart';
import 'package:sentralix_app/shared/navigation/menu_registry.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(shellRailExpandedProvider);
    final currentPath = GoRouterState.of(context).uri.path;
    final ctxState = ref.watch(contextDataProvider).state;
    final minExpandedWidth = 200.0;
    final minCollapsedWidth = 80.0;
    // Build dynamic items from context menu using registry
    final dynamicItems = <MenuDef>[
      for (final item in ctxState.menu)
        if (kMenuRegistry.containsKey(item['key'])) kMenuRegistry[item['key']]!
    ];

    // featureIndex: index in dynamicItems for current path
    int? featureIndex;
    final idx = dynamicItems.indexWhere((e) => e.route == currentPath);
    if (idx >= 0) {
      featureIndex = idx;
    } else {
      featureIndex = null; // not a rail destination (e.g., other routes)
    }
    // selectedIndex in rail: +1 because 0 is reserved for toggle/brand item
    int? selectedIndex = dynamicItems.isEmpty ? null : ((featureIndex ?? 0) + 1);
    final baseNavTheme = Theme.of(context).navigationRailTheme;
    final bool neutralizeSelection = featureIndex == null || dynamicItems.isEmpty; // when on non-rail routes or empty
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
        final menuIdx = idx - 1; // shift for toggle item
        if (menuIdx >= 0 && menuIdx < dynamicItems.length) {
          final def = dynamicItems[menuIdx];
          context.go(def.route);
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
        // Dynamic items from context
        for (final def in dynamicItems)
          NavigationRailDestination(
            icon: Icon(def.icon),
            selectedIcon: Icon(def.selectedIcon),
            label: Text(def.defaultLabel),
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

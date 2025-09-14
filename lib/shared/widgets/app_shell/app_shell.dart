// comment: AppShell - shared layout with left menu (Drawer/NavigationRail) and top bar with user avatar/menu on the left
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/shared/providers/shell_provider.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell_leading.dart';
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
        if (kMenuRegistry.containsKey(item['key'])) kMenuRegistry[item['key']]!,
    ];

    // featureIndex: индекс текущего пункта меню по маршруту
    int? featureIndex;
    // 1) Точное совпадение
    final exactIdx = dynamicItems.indexWhere((e) => e.route == currentPath);
    if (exactIdx >= 0) {
      featureIndex = exactIdx;
    } else {
      // 2) Вложенные маршруты: для пунктов, отличных от корневого '/'
      final nestedIdx = dynamicItems.indexWhere(
        (e) => e.route != '/' && currentPath.startsWith('${e.route}/'),
      );
      featureIndex = nestedIdx >= 0 ? nestedIdx : null;
    }
    // selectedIndex напрямую соответствует индексу в dynamicItems
    int? selectedIndex =
        (featureIndex != null &&
            featureIndex >= 0 &&
            featureIndex < dynamicItems.length)
        ? featureIndex
        : null;
    final baseNavTheme = Theme.of(context).navigationRailTheme;
    final bool neutralizeSelection =
        featureIndex == null ||
        dynamicItems.isEmpty; // when on non-rail routes or empty
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
        if (idx >= 0 && idx < dynamicItems.length) {
          final def = dynamicItems[idx];
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
      leading: Transform.translate(
        offset: const Offset(0, -8),
        child: AppShellLeading(
          width: minCollapsedWidth,
          expandedWidth: minExpandedWidth,
          expanded: expanded,
        ),
      ),
      destinations: [
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
          NavigationRailTheme(data: overrideTheme, child: rail),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

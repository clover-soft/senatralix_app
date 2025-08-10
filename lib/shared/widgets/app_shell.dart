// comment: AppShell - shared layout with left menu (Drawer/NavigationRail) and top bar with user avatar/menu on the left
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/shared/providers/shell_provider.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

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

    final auth = ref.watch(authDataProvider).state;
    final profileLabel =
        (auth.user != null &&
            (auth.user!['name'] ?? '').toString().trim().isNotEmpty)
        ? auth.user!['name'].toString()
        : 'Профиль';

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
      // bottom area: divider + profile button anchored to bottom
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // no-op: profile click behavior will be defined later
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: expanded
                      ? Row(
                          children: [
                            const Icon(Icons.person_outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                profileLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Center(child: Icon(Icons.person_outline)),
                ),
              ),
            ),
          ],
        ),
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

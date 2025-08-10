// comment: AppShell - shared layout with left menu (Drawer/NavigationRail) and top bar with user avatar/menu on the left
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/dashboard/providers/dashboard_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1000; // simple breakpoint
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

    final drawer = Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Menu', style: TextStyle(fontSize: 20)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: selectedIndex == 0,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/');
              },
            ),
            // Add more items here when new features appear
          ],
        ),
      ),
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
      labelType: NavigationRailLabelType.all,
      // leading left empty; avatar/menu is in AppBar leading per requirement
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isWide, // show burger only on narrow screens
        leading: !isWide
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : userMenu, // on wide screens, put avatar/menu on the left in the AppBar
        titleSpacing: 0,
        title: Row(
          children: [
            if (!isWide) ...[
              const SizedBox(width: 8),
              // avatar+menu on the left in title for narrow screens
              userMenu,
              const SizedBox(width: 12),
            ],
            const Text(''),
          ],
        ),
      ),
      drawer: isWide ? null : drawer,
      body: Row(
        children: [
          if (isWide) rail,
          Expanded(child: child),
        ],
      ),
    );
  }
}

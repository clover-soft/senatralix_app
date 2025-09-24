// comment: Trailing container for AppShell NavigationRail
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/data/providers/profile_data_provider.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell_rail_item.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell_version_info.dart';

class AppShellTrailing extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool isProfile = currentPath.startsWith('/profile');
    final profileController = ref.watch(profileDataProvider);
    final profileState = profileController.state;
    final me = profileState.profile ?? const <String, dynamic>{};
    final String username = (me['username'] ?? '').toString().trim();
    final String email = (me['email'] ?? '').toString().trim();
    final String label = username.isNotEmpty
        ? username
        : (email.isNotEmpty ? email : 'Profile');
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
            SizedBox(
              width: expanded ? expandedWidth : width,
              child: const Center(child: AppShellVersionInfo()),
            ),
            const Divider(),
            AppShellRailItem(
              icon: Icons.person_outline,
              label: label,
              selected: isProfile,
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

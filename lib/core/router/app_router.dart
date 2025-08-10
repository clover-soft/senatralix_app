import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/registration/screens/registration_screen.dart';
import 'package:sentralix_app/features/auth/screens/auth_screen.dart';
import 'package:sentralix_app/features/auth/screens/splash_screen.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';
import 'package:sentralix_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(ProviderContainer container) => GoRouter(
  navigatorKey: navigatorKey,
  // comment: re-evaluate redirects when authDataProvider notifies
  refreshListenable: container.read(authDataProvider),
  redirect: (context, state) {
    final auth = container.read(authDataProvider).state;

    final loc = state.uri.toString();
    final path = state.uri.path; // robust on web hash strategy
    final isAuthRoute = path.startsWith('/auth');
    final isSplash = path == '/splash';
    final isRegistration = path == '/registration';

    print(
      'redirect: ${state.uri} path: $path isAuthRoute: $isAuthRoute isSplash: $isSplash isRegistration: $isRegistration',
    );

    // While /me is loading, show splash to avoid flicker/loops
    if (!auth.ready && !isSplash) {
      return '/splash';
    }

    // If not logged in -> go to login (even from splash)
    if (auth.ready && !auth.loggedIn && !isAuthRoute && !isRegistration) {
      final from = Uri.encodeComponent(loc);
      return '/auth/login?from=$from';
    }

    // If logged in and on auth route -> go back to original location or home
    if (auth.ready && auth.loggedIn && isAuthRoute) {
      final from = state.uri.queryParameters['from'];
      return from ?? '/';
    }

    // If logged in and on splash -> go home
    if (auth.ready && auth.loggedIn && isSplash) {
      return '/';
    }

    // If not logged in and on splash -> go to login
    if (auth.ready && !auth.loggedIn && isSplash) {
      return '/auth/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) {
        return const MaterialPage(child: SplashScreen());
      },
    ),
    // Shell with persistent layout (left menu + top bar)
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            return const MaterialPage(child: DashboardScreen());
          },
        ),
        // Add more feature routes here, they will render inside AppShell
      ],
    ),
    GoRoute(
      path: '/registration',
      pageBuilder: (context, state) {
        return MaterialPage(child: RegistrationScreen());
      },
    ),
    GoRoute(
      path: '/auth/login',
      pageBuilder: (context, state) {
        return const MaterialPage(child: AuthScreen());
      },
    ),
  ],
);

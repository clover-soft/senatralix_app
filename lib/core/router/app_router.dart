import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/registration/screens/registration_screen.dart';
import 'package:sentralix_app/features/auth/screens/auth_screen.dart';
import 'package:sentralix_app/features/auth/screens/splash_screen.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';
import 'package:sentralix_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:sentralix_app/shared/widgets/app_shell/app_shell.dart';
import 'package:sentralix_app/features/profile/screens/profile_screen.dart';
import 'package:sentralix_app/features/assistant/assistant_routes.dart';

final navigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(ProviderContainer container) => GoRouter(
  navigatorKey: navigatorKey,
  // comment: re-evaluate redirects when authDataProvider notifies
  refreshListenable: container.read(authDataProvider),
  redirect: (context, state) {
    final auth = container.read(authDataProvider).state;

    // Поддержка hash-стратегии: если во фрагменте есть путь — используем его как эффективный
    final rawUri = state.uri;
    final hasFragmentPath = (rawUri.fragment).isNotEmpty && rawUri.fragment.startsWith('/');
    final fragmentUri = hasFragmentPath ? Uri.parse(rawUri.fragment) : null;
    final effectivePath = hasFragmentPath ? fragmentUri!.path : rawUri.path;
    final effectiveLoc = hasFragmentPath ? fragmentUri!.toString() : rawUri.toString();

    final loc = effectiveLoc;
    final path = effectivePath; // путь для логики роутера
    final isAuthRoute = path.startsWith('/auth');
    final isSplash = path == '/splash';
    final isRegistration = path == '/registration';

    print('redirect: raw=${state.uri} eff=$loc path=$path authRoute=$isAuthRoute splash=$isSplash reg=$isRegistration');

    // Пока /me грузится — показываем splash и сохраняем исходный адрес в from
    if (!auth.ready && !isSplash) {
      final from = Uri.encodeComponent(loc);
      return '/splash?from=$from';
    }

    // Если не залогинен -> на логин (сохраняем from)
    if (auth.ready && !auth.loggedIn && !isAuthRoute && !isRegistration) {
      final from = Uri.encodeComponent(loc);
      return '/auth/login?from=$from';
    }

    // If logged in and on auth route -> go back to original location or home
    if (auth.ready && auth.loggedIn && isAuthRoute) {
      final from = state.uri.queryParameters['from'];
      return from ?? '/';
    }

    // Если залогинен и на splash -> возвращаемся на исходный адрес (или домой)
    if (auth.ready && auth.loggedIn && isSplash) {
      final from = state.uri.queryParameters['from'];
      return from ?? '/';
    }

    // Если не залогинен и на splash -> на логин c from
    if (auth.ready && !auth.loggedIn && isSplash) {
      final from = state.uri.queryParameters['from'];
      final suffix = from != null ? '?from=$from' : '';
      return '/auth/login$suffix';
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
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) {
            return const MaterialPage(child: ProfileScreen());
          },
        ),
        // Assistant feature routes
        ...assistantRoutes(),
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

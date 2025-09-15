import 'package:flutter/material.dart';
import 'package:sentralix_app/core/logger.dart';
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
import 'package:sentralix_app/shared/navigation/menu_registry.dart';

final navigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(ProviderContainer container) => GoRouter(
  navigatorKey: navigatorKey,
  // comment: re-evaluate redirects when authDataProvider notifies
  refreshListenable: container.read(authDataProvider),
  redirect: (context, state) {
    final auth = container.read(authDataProvider).state;

    // Поддержка hash-стратегии: если во фрагменте есть путь — используем его как эффективный
    final rawUri = state.uri;
    final hasFragmentPath =
        (rawUri.fragment).isNotEmpty && rawUri.fragment.startsWith('/');
    final fragmentUri = hasFragmentPath ? Uri.parse(rawUri.fragment) : null;
    final effectivePath = hasFragmentPath ? fragmentUri!.path : rawUri.path;
    final effectiveLoc = hasFragmentPath
        ? fragmentUri!.toString()
        : rawUri.toString();

    final loc = effectiveLoc;
    final path = effectivePath; // путь для логики роутера
    final isAuthRoute = path.startsWith('/auth');
    final isSplash = path == '/splash';
    final isRegistration = path == '/registration';

    AppLogger.d('redirect: raw=${state.uri} eff=$loc path=$path authRoute=$isAuthRoute splash=$isSplash reg=$isRegistration', tag: 'Router');

    // Важно: не дёргать URL на стадии инициализации auth (auth.ready == false)
    // Разрешаем рендер страницы; protected-редирект выполняем только когда auth.ready == true.

    // Если не залогинен -> на логин (сохраняем from)
    if (auth.ready && !auth.loggedIn && !isAuthRoute && !isRegistration) {
      final from = Uri.encodeComponent(loc);
      return '/auth/login?from=$from';
    }

    // Маршрут по умолчанию: первая фича из меню, у которой route != '/'
    String defaultRoute = '/';
    if (kMenuRegistry.values.isNotEmpty) {
      final firstNonRoot = kMenuRegistry.values.cast<MenuDef?>().firstWhere(
            (m) => m != null && m.route != '/',
            orElse: () => null,
          );
      defaultRoute = (firstNonRoot?.route ?? kMenuRegistry.values.first.route)
          .toString();
    }

    // Если залогинен и мы на auth-роуте -> возвращаемся на from или на defaultRoute
    if (auth.ready && auth.loggedIn && isAuthRoute) {
      final from = state.uri.queryParameters['from'];
      return from ?? defaultRoute;
    }

    // Если залогинен и мы на корне '/', но первая фича не '/' — редиректим на неё
    if (auth.ready && auth.loggedIn && path == '/' && defaultRoute != '/') {
      return defaultRoute;
    }

    // Splash не используем в redirect, чтобы избежать прыжков URL на deep-link

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/registration/screens/registration_screen.dart';
import 'package:sentralix_app/features/auth/screens/auth_screen.dart';
import 'package:sentralix_app/features/auth/screens/splash_screen.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(ProviderContainer container) => GoRouter(
      navigatorKey: navigatorKey,
      // comment: re-evaluate redirects when authDataProvider notifies
      refreshListenable: container.read(authDataProvider),
      redirect: (context, state) {
        final auth = container.read(authDataProvider).state;

        final loc = state.uri.toString();
        final isAuthRoute = loc.startsWith('/auth');
        final isSplash = loc == '/splash';

        // While /me is loading, show splash to avoid flicker/loops
        if (!auth.ready && !isSplash) {
          return '/splash';
        }

        // If not logged in and trying to access a non-auth route -> go to login
        if (auth.ready && !auth.loggedIn && !isAuthRoute && !isSplash) {
          final from = Uri.encodeComponent(loc);
          return '/auth/login?from=$from';
        }

        // If logged in and on auth route -> go back to original location or home
        if (auth.ready && auth.loggedIn && isAuthRoute) {
          final from = state.uri.queryParameters['from'];
          return from ?? '/';
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
        GoRoute(
          path: '/',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/registration/screens/registration_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  redirect: (context, state) {
    // final ref = ProviderScope.containerOf(context);
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        final _ = ProviderScope.containerOf(context);
        return MaterialPage(child: RegistrationScreen());
      },
    ),
  ],
);

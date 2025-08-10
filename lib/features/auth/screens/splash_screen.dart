import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authDataProvider).state;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (auth.ready && auth.loggedIn) {
        context.go('/');
      } else if (auth.ready && !auth.loggedIn) {
        context.go('/auth/login');
      }
    });

    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

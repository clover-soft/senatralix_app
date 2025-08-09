import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/core/theme/app_theme.dart';
import 'package:sentralix_app/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SentralixApp(),
    ),
  );
}

class SentralixApp extends ConsumerWidget {
  const SentralixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery,
          child: MaterialApp.router(
            title: "Sentralix",
            theme: AppTheme().themeData(AppThemeMode.light),
            routerConfig: appRouter,
          ),
        );
      },
    );
  }
}

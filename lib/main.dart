import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/core/theme/app_theme.dart';
import 'package:sentralix_app/core/router/app_router.dart';
import 'package:sentralix_app/data/providers/context_data_provider.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final router = createAppRouter(container);

  // Ensure contextDataProvider is instantiated so it can listen to auth changes
  // and load context on login
  // ignore: unused_result
  container.read(contextDataProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: SentralixApp(router: router),
    ),
  );
}

class SentralixApp extends ConsumerWidget {
  const SentralixApp({super.key, required this.router});

  final GoRouter router;

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
            routerConfig: router,
          ),
        );
      },
    );
  }
}

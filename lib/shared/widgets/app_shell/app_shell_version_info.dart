import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/core/providers/build_info_provider.dart';

/// Небольшой виджет, показывающий текущую версию приложения
class AppShellVersionInfo extends ConsumerWidget {
  const AppShellVersionInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(buildInfoProvider);
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);

    final String label = infoAsync.when(
      data: (info) {
        final version = info.version.isNotEmpty ? info.version : 'unknown';
        final build = info.buildNumber.isNotEmpty ? info.buildNumber : '0';
        return 'v $version+$build';
      },
      loading: () => 'v…',
      error: (_, __) => '--',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}

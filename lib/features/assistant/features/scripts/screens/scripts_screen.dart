import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';

class AssistantScriptsScreen extends ConsumerWidget {
  const AssistantScriptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final name = ref.watch(assistantListProvider).byId(id)?.name ?? 'Unknown';

    final width = MediaQuery.sizeOf(context).width;
    final showBreadcrumbs = width >= 900;
    Widget title = Text('Assistant • Scripts ($name)');
    if (showBreadcrumbs) {
      title = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => context.go('/assistant'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Assistant'),
          ),
          const Text('›'),
          TextButton(
            onPressed: () => context.go('/assistant/$id'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(name),
          ),
          const Text('›'),
          const Text('Scripts'),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'К ассистенту',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/assistant/$id'),
        ),
        actions: [
          IconButton(
            tooltip: 'Домой ассистента',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/assistant/$id'),
          ),
        ],
        title: title,
      ),
      body: Center(
        child: Text('Scripts for assistant "$name" (on events: enter/leave dialog, triggers, etc.)'),
      ),
    );
  }
}

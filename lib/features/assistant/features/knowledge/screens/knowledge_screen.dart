import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';

class AssistantKnowledgeScreen extends ConsumerWidget {
  const AssistantKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    final name = ref.watch(assistantListProvider).byId(id)?.name ?? 'Unknown';

    final width = MediaQuery.sizeOf(context).width;
    final showBreadcrumbs = width >= 900;
    Widget title = Text('Assistant • Knowledge ($name)');
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
          const Text('Knowledge'),
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
        child: Text('Knowledge base for assistant "$name" (admin uploads)'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_tools_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/tools/widgets/tools_list_card.dart';
import 'package:sentralix_app/features/assistant/features/tools/widgets/tools_presets_card.dart';

class AssistantToolsScreen extends ConsumerWidget {
  const AssistantToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantId =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';

    final boot = ref.watch(assistantBootstrapProvider);
    final loader = ref.watch(assistantToolsLoaderProvider(assistantId));

    final tools = ref.watch(
      assistantToolsProvider.select(
        (s) => s.byAssistantId[assistantId] ?? const <AssistantTool>[],
      ),
    );

    Widget buildScaffold(Widget body) => Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Инструменты',
      ),
      body: body,
    );

    if (boot.isLoading || loader.isLoading) {
      return buildScaffold(const Center(child: CircularProgressIndicator()));
    }

    final Object? error = boot.hasError
        ? boot.error
        : (loader.hasError ? loader.error : null);
    if (error != null) {
      return buildScaffold(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Не удалось загрузить инструменты: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.refresh(assistantToolsLoaderProvider(assistantId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return buildScaffold(
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final presets = const ToolsPresetsCard();

          if (isWide) {
            final availableHeight = constraints.maxHeight;
            return Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: availableHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ToolsListCard(
                        assistantId: assistantId,
                        initialTools: tools,
                        // Чуть уменьшим на внутренние отступы карточки
                        maxHeight: (availableHeight - 24).clamp(320.0, 1200.0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: presets),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToolsListCard(
                  assistantId: assistantId,
                  initialTools: tools,
                ),
                const SizedBox(height: 16),
                presets,
              ],
            ),
          );
        },
      ),
    );
  }
}

// Переключатель активности теперь встроен в плитку списка в ToolsListCard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/slots/widgets/slots_list.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/slots/widgets/slot_details_panel.dart';

/// Экран подфичи "Память ассистента" (слоты)
class AssistantSlotsScreen extends ConsumerWidget {
  const AssistantSlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: id,
        subfeatureTitle: 'Память ассистента',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: SlotsList()),
                  const SizedBox(width: 16),
                  const SizedBox(width: 420, child: SlotDetailsPanel()),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: SlotsList()),
                SizedBox(height: 12),
                // В узкой раскладке панель деталей ниже списка
                SizedBox(height: 320, child: SlotDetailsPanel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

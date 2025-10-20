import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/timeline_provider.dart';
import 'package:sentralix_app/features/assistant/features/sessions/styles/subfeature_styles.dart';

/// Панель саммари по диалогу (справа на десктопе / снизу на мобиле)
class TimelineSummaryPanel extends ConsumerWidget {
  final String internalId;
  const TimelineSummaryPanel({super.key, required this.internalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(timelineSummaryContextProvider(internalId));
    final theme = Theme.of(context);
    final styles = SubfeatureStyles.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: styles.summaryPanelBackground),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ячейки памяти',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (ctx.isEmpty)
                      Text(
                        'Контекст не найден',
                        style: theme.textTheme.bodySmall,
                      ),
                    for (final e in ctx.entries)
                      Container(
                        constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: styles.systemBubble.background,
                          borderRadius: styles.systemBubble.borderRadius,
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: styles.contentTextStyle.copyWith(color: styles.systemBubble.textColor),
                          softWrap: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

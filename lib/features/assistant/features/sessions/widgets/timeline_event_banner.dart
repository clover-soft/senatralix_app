import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/timeline_entry.dart';
import 'package:sentralix_app/features/assistant/features/sessions/styles/subfeature_styles.dart';

/// Поперечные баннеры событий (Run/ToolCall/ThreadSlots)
class TimelineEventBanner extends StatelessWidget {
  final Widget child;
  const TimelineEventBanner._(this.child);

  factory TimelineEventBanner.run({required AssistantRunEntry run}) {
    return TimelineEventBanner._(_RunBanner(run: run));
  }

  factory TimelineEventBanner.tool({required ToolCallLogEntry log}) {
    return TimelineEventBanner._(_ToolBanner(log: log));
  }

  factory TimelineEventBanner.slots({required ThreadSlotsEntry slots}) {
    return TimelineEventBanner._(_SlotsBanner(slots: slots));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: child,
    );
  }
}

class _ToolBanner extends StatelessWidget {
  final ToolCallLogEntry log;
  const _ToolBanner({required this.log});
  @override
  Widget build(BuildContext context) {
    final styles = SubfeatureStyles.of(context);
    final sys = styles.systemBubble;
    final text = sys.textColor;
    return Container(
      decoration: BoxDecoration(
        color: sys.background,
        borderRadius: sys.borderRadius,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.extension, color: text),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tool: ${log.toolName}',
                  style: styles.headerTextStyle.copyWith(color: text),
                ),
                const SizedBox(height: 2),
                Text(
                  'Статус: ${log.status}  ·  Длительность: ${log.durationMs ?? 0} мс',
                  style: styles.contentTextStyle.copyWith(
                    color: text.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunBanner extends StatelessWidget {
  final AssistantRunEntry run;
  const _RunBanner({required this.run});
  @override
  Widget build(BuildContext context) {
    final styles = SubfeatureStyles.of(context);
    final sys = styles.systemBubble;
    final text = sys.textColor;
    return Container(
      decoration: BoxDecoration(
        color: sys.background,
        borderRadius: sys.borderRadius,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: text),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant Run • ${run.status}',
                  style: styles.headerTextStyle.copyWith(color: text),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tokens: in=${run.inputTokens ?? 0} • out=${run.outputTokens ?? 0}',
                  style: styles.contentTextStyle.copyWith(
                    color: text.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotsBanner extends StatelessWidget {
  final ThreadSlotsEntry slots;
  const _SlotsBanner({required this.slots});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Контекст/слоты', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in slots.values.take(12))
                Chip(
                  label: Text('${v.contextName}: ${v.value}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

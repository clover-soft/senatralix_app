import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/timeline_provider.dart';
import 'package:sentralix_app/features/assistant/features/sessions/styles/subfeature_styles.dart';

/// Панель саммари по диалогу (справа на десктопе / снизу на мобиле)
class TimelineSummaryPanel extends ConsumerWidget {
  final String internalId;
  /// Если true — панель размещена снизу под лентой; если false — справа от ленты
  final bool isBottom;
  const TimelineSummaryPanel({super.key, required this.internalId, this.isBottom = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(timelineSummaryContextProvider(internalId));
    final theme = Theme.of(context);
    final styles = SubfeatureStyles.of(context);
    final dividerColor = styles.summaryPanelDividerColor
        .withOpacity(styles.summaryPanelDividerOpacity);
    final topWidth = isBottom ? 10.0 : 0.0;
    final leftWidth = isBottom ? 0.0 : 10.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: styles.summaryPanelBackground,
        border: Border(
          top: BorderSide(color: dividerColor, width: topWidth),
          left: BorderSide(color: dividerColor, width: leftWidth),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                      _CopyableSlotChip(
                        text: '${e.key}: ${e.value}',
                        background: styles.systemBubble.background,
                        radius: styles.systemBubble.borderRadius,
                        textStyle: styles.contentTextStyle.copyWith(
                          color: styles.systemBubble.textColor,
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

class _CopyableSlotChip extends StatefulWidget {
  final String text;
  final Color background;
  final BorderRadius radius;
  final TextStyle textStyle;
  const _CopyableSlotChip({
    required this.text,
    required this.background,
    required this.radius,
    required this.textStyle,
  });
  @override
  State<_CopyableSlotChip> createState() => _CopyableSlotChipState();
}

class _CopyableSlotChipState extends State<_CopyableSlotChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: widget.radius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.text,
                style: widget.textStyle,
                softWrap: true,
              ),
            ),
            if (_hover) ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Скопировать',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                iconSize: 16,
                icon: const Icon(Icons.copy_all_outlined),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: widget.text));
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Скопировано в буфер обмена')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

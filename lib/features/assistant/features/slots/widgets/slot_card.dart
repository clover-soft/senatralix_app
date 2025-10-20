import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/slot_types.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Карточка слота (адаптивная)
class SlotCard extends ConsumerWidget {
  const SlotCard({super.key, required this.slot});

  final DialogSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selectedId = ref.watch(selectedSlotIdProvider);
    final isSelected = selectedId == slot.id;
    final isSystem = slot.name.startsWith('THREAD_');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ref.read(selectedSlotIdProvider.notifier).state = slot.id,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 420,
          minHeight: 100,
          maxHeight: 100,
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? scheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.12)
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isSelected ? Icons.memory : Icons.memory_outlined,
                    size: 20,
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slot.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot.label,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Tooltip(
                            message: 'Тип',
                            child: Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              kSlotTypeLabels[slot.slotType] ?? slot.slotType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: 'Опции',
                            child: Icon(
                              Icons.tune,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${slot.options.length}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: 'Подсказки',
                            child: Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${slot.hints.length}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: isSystem
                      ? 'Системная ячейка памяти (удаление запрещено)'
                      : 'Удалить',
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: isSystem ? Theme.of(context).disabledColor : null,
                    ),
                    onPressed: isSystem
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Удалить ячейку памяти?'),
                                    content: Text(
                                      'Вы действительно хотите удалить "${slot.label}"? Это действие нельзя отменить.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Отмена'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(ctx).colorScheme.error,
                                        ),
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Удалить'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            if (!context.mounted || !confirm) return;

                            final api = ref.read(assistantApiProvider);
                            final selectedId = ref.read(selectedSlotIdProvider);
                            try {
                              await api.deleteDialogSlot(slot.id);
                              ref.invalidate(dialogSlotsProvider);
                              if (selectedId == slot.id) {
                                ref.read(selectedSlotIdProvider.notifier).state = null;
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ячейка удалена')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Не удалось удалить: $e')),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';

/// Карточка-добавление нового слота (стилистически совпадает по размерам)
class SlotAddCard extends ConsumerWidget {
  const SlotAddCard({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed ?? () async {
        final api = ref.read(assistantApiProvider);
        try {
          final body = <String, dynamic>{
            'name': 'NEW_SLOT',
            'label': 'Новая ячейка памяти',
            'prompt': '',
            'options': <String>[],
            'hints': <String>[],
            'metadata': <String, dynamic>{},
            'slot_type': 'string',
          };
          final created = await api.createDialogSlot(body: body);

          // Обновить список и выбрать созданный слот
          ref.invalidate(dialogSlotsProvider);
          ref.read(selectedSlotIdProvider.notifier).state = created.id;

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ячейка создана')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось создать: $e')),
            );
          }
        }
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 420,
          minHeight: 100,
          maxHeight: 100,
        ),
        child: Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.add, size: 22, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавить ячейку памяти',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/sessions_filter_provider.dart';

/// Панель фильтров: выбор диапазона дат и лимита строк. Располагается в одну строку.
class SessionsFilterBar extends ConsumerWidget {
  const SessionsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(sessionsFilterProvider);

    Future<void> pickDateRange() async {
      final now = DateTime.now();
      final initialStart = filter.createdFrom ?? now.subtract(const Duration(days: 7));
      final initialEnd = filter.createdTo ?? now;
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(now.year + 2),
        initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
        helpText: 'Выберите период',
        saveText: 'Применить',
        builder: (ctx, child) {
          final size = MediaQuery.of(ctx).size;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: size.height * 0.8,
              ),
              child: Material(
                type: MaterialType.card,
                elevation: 6,
                clipBehavior: Clip.antiAlias,
                borderOnForeground: false,
                child: child!,
              ),
            ),
          );
        },
      );
      if (picked != null) {
        ref.read(sessionsFilterProvider.notifier).setDateRange(
              from: picked.start,
              to: picked.end,
            );
      }
    }

    final limits = const [10, 25, 50, 100];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Даты
          OutlinedButton.icon(
            onPressed: pickDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(filter.dateRangeLabel),
          ),
          const SizedBox(width: 12),
          // Лимит
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: filter.limit,
              items: [
                for (final v in limits)
                  DropdownMenuItem<int>(value: v, child: Text('Показывать: $v')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(sessionsFilterProvider.notifier).setLimit(v);
                }
              },
            ),
          ),
          const Spacer(),
          // Сброс
          TextButton(
            onPressed: () => ref.read(sessionsFilterProvider.notifier).reset(),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

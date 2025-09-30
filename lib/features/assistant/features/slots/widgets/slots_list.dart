import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/slot_types.dart';
import 'package:sentralix_app/features/assistant/features/slots/widgets/slot_card.dart';
import 'package:sentralix_app/features/assistant/features/slots/widgets/slot_add_card.dart';

/// Список слотов (адаптивные карточки)
class SlotsList extends ConsumerStatefulWidget {
  const SlotsList({super.key});

  @override
  ConsumerState<SlotsList> createState() => _SlotsListState();
}

class _SlotsListState extends ConsumerState<SlotsList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dialogSlotsProvider);
    final filtered = ref.watch(filteredDialogSlotsProvider);
    final types = ref.watch(slotsAvailableTypesProvider);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Filters(types: types),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text('Не удалось загрузить слоты: $e'),
                    ],
                  ),
                ),
                data: (slots) {
                  if (slots.isEmpty) {
                    return _EmptyState(onReload: () => ref.refresh(dialogSlotsProvider));
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final crossAxisCount = w <= 520 ? 1 : (w <= 980 ? 2 : 3);
                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: GridView.builder(
                          controller: _scrollController,
                          primary: false,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            // фиксированная высота карточки (см. SlotCard BoxConstraints)
                            mainAxisExtent: 100,
                          ),
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              return const SlotAddCard();
                            }
                            final s = filtered[index];
                            return SlotCard(slot: s);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.types});
  final List<String> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(slotsTypeFilterProvider);
    return Row(
      children: [
        // Поиск
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Поиск по Имя/Описание',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => ref.read(slotsSearchQueryProvider.notifier).state = v,
          ),
        ),
        const SizedBox(width: 12),
        // Тип (фиксированная ширина, чтобы избежать unbounded width)
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            isDense: true,
            value: type,
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Все типы'),
              ),
              ...types.map(
                (t) => DropdownMenuItem<String>(
                  value: t,
                  child: Text(kSlotTypeLabels[t] ?? t),
                ),
              ),
            ],
            onChanged: (v) => ref.read(slotsTypeFilterProvider.notifier).state = v ?? '',
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReload});
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.list_alt_outlined, size: 48),
          const SizedBox(height: 8),
          const Text('Слоты не найдены'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onReload, child: const Text('Обновить')),
        ],
      ),
    );
  }
}

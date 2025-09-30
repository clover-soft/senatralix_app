import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Провайдер загрузки слотов диалога
final dialogSlotsProvider = FutureProvider<List<DialogSlot>>((ref) async {
  final api = ref.read(assistantApiProvider);
  final list = await api.fetchDialogSlots();
  return list.map((e) => DialogSlot.fromJson(e)).toList();
});

/// Текущий выбранный слот (id)
final selectedSlotIdProvider = StateProvider<int?>((ref) => null);

/// Фильтры
final slotsSearchQueryProvider = StateProvider<String>((ref) => '');
final slotsTypeFilterProvider = StateProvider<String>((ref) => ''); // '' = все типы
final slotsHasOptionsOnlyProvider = StateProvider<bool>((ref) => false);
final slotsHasHintsOnlyProvider = StateProvider<bool>((ref) => false);

/// Список доступных типов (для фильтра)
final slotsAvailableTypesProvider = Provider<List<String>>((ref) {
  final async = ref.watch(dialogSlotsProvider);
  return async.maybeWhen(
    data: (slots) => slots.map((e) => e.slotType).toSet().toList()..sort(),
    orElse: () => const <String>[],
  );
});

/// Отфильтрованный список
final filteredDialogSlotsProvider = Provider<List<DialogSlot>>((ref) {
  final async = ref.watch(dialogSlotsProvider);
  final q = ref.watch(slotsSearchQueryProvider).trim().toLowerCase();
  final type = ref.watch(slotsTypeFilterProvider);
  final onlyWithOptions = ref.watch(slotsHasOptionsOnlyProvider);
  final onlyWithHints = ref.watch(slotsHasHintsOnlyProvider);

  return async.maybeWhen(
    data: (slots) {
      Iterable<DialogSlot> it = slots;
      if (q.isNotEmpty) {
        it = it.where((s) {
          return s.name.toLowerCase().contains(q) ||
              s.label.toLowerCase().contains(q) ||
              s.prompt.toLowerCase().contains(q);
        });
      }
      if (type.isNotEmpty) {
        it = it.where((s) => s.slotType == type);
      }
      if (onlyWithOptions) {
        it = it.where((s) => s.options.isNotEmpty);
      }
      if (onlyWithHints) {
        it = it.where((s) => s.hints.isNotEmpty);
      }
      return it.toList();
    },
    orElse: () => const <DialogSlot>[],
  );
});

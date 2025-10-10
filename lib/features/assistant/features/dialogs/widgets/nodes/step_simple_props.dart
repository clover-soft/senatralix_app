import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';

/// Простой шаг: выбор ячеек памяти (опциональные/обязательные) и следующий шаг
class StepSimpleProps extends StatelessWidget {
  const StepSimpleProps({
    super.key,
    required this.current,
    required this.steps,
    required this.availableSlots,
    required this.selectedOptional,
    required this.selectedRequired,
    required this.slotToAdd,
    required this.onSetSlotToAdd,
    required this.nextId,
    required this.onNextChanged,
  });

  final DialogStep current;
  final List<DialogStep> steps;
  final List<DialogSlot> availableSlots;
  final Set<int> selectedOptional;
  final Set<int> selectedRequired;
  final int? slotToAdd;
  final ValueChanged<int?> onSetSlotToAdd;
  final int? nextId;
  final ValueChanged<int?> onNextChanged;

  @override
  Widget build(BuildContext context) {
    final selectedAll = <int>{...selectedOptional, ...selectedRequired};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ячейки памяти для заполнения',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in selectedAll)
              FilterChip(
                selected: selectedRequired.contains(id),
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(() {
                      final s = availableSlots.firstWhere(
                        (e) => e.id == id,
                        orElse: () => DialogSlot(
                          id: id,
                          name: 'ID_$id',
                          label: '',
                          prompt: '',
                          options: const [],
                          hints: const [],
                          metadata: const {},
                          slotType: '',
                        ),
                      );
                      return '${s.id}: ${s.label.isNotEmpty ? s.label : s.name}';
                    }()),
                    const SizedBox(width: 6),
                    if (selectedRequired.contains(id))
                      const Icon(Icons.check_circle, size: 16),
                  ],
                ),
                tooltip: selectedRequired.contains(id)
                    ? 'Обязательная — кликните, чтобы сделать опциональной'
                    : 'Опциональная — кликните, чтобы сделать обязательной',
                onSelected: (v) {
                  if (selectedRequired.contains(id)) {
                    selectedRequired.remove(id);
                    selectedOptional.add(id);
                  } else {
                    selectedRequired.add(id);
                    selectedOptional.remove(id);
                  }
                  // setState снаружи (родитель отвечает)
                  (context as Element).markNeedsBuild();
                },
                onDeleted: () {
                  selectedRequired.remove(id);
                  selectedOptional.remove(id);
                  (context as Element).markNeedsBuild();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: DropdownButtonFormField<int?>(
                // ignore: deprecated_member_use
                value: slotToAdd,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Выберите ячейки для заполнения',
                ),
                items: [
                  for (final s in availableSlots.where(
                    (e) =>
                        !selectedOptional.contains(e.id) &&
                        !selectedRequired.contains(e.id),
                  ))
                    DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text(
                        '${s.id}: ${s.label.isNotEmpty ? s.label : s.name}',
                      ),
                    ),
                ],
                onChanged: onSetSlotToAdd,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Добавить ячейку',
              onPressed: (slotToAdd != null)
                  ? () {
                      selectedOptional.add(slotToAdd!);
                      onSetSlotToAdd(null);
                      (context as Element).markNeedsBuild();
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          // ignore: deprecated_member_use
          value: nextId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Следующий шаг (next)'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('— нет —')),
            ...steps
                .where((e) => e.id != current.id)
                .map(
                  (e) => DropdownMenuItem<int?>(
                    value: e.id,
                    child: Text(
                      '${e.id}: ${e.label.isNotEmpty ? e.label : e.name}',
                    ),
                  ),
                ),
          ],
          onChanged: onNextChanged,
        ),
      ],
    );
  }
}

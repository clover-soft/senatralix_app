import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';

/// Маршрутизатор: выбор слота с перечнем значений и назначение следующего шага для каждого значения
class StepRouterProps extends StatefulWidget {
  const StepRouterProps({
    super.key,
    required this.current,
    required this.steps,
    required this.availableSlots,
    required this.branchMap,
    required this.onSelectSlot,
    required this.onSetOptionNext,
  });

  final DialogStep current;
  final List<DialogStep> steps;
  final List<DialogSlot> availableSlots;
  final Map<String, Map<String, int>> branchMap;
  final void Function(int slotId) onSelectSlot;
  final void Function(int slotId, String value, int? nextId) onSetOptionNext;

  @override
  State<StepRouterProps> createState() => _StepRouterPropsState();
}

class _StepRouterPropsState extends State<StepRouterProps> {
  int? _selectedSlotId;

  List<DialogSlot> get _enumSlots => widget.availableSlots.where((s) => s.options.isNotEmpty).toList();

  DialogSlot? _findSlotById(int id) => widget.availableSlots.where((s) => s.id == id).firstOrNull;

  @override
  void initState() {
    super.initState();
    // Инициализация выбранного слота из branchMap (если есть)
    if (widget.branchMap.isNotEmpty) {
      final firstKey = widget.branchMap.keys.first;
      _selectedSlotId = int.tryParse(firstKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedKey = _selectedSlotId?.toString();
    final selectedSlot = _selectedSlotId != null ? _findSlotById(_selectedSlotId!) : null;
    final mappings = selectedKey != null ? (widget.branchMap[selectedKey] ?? <String, int>{}) : <String, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Маршрутизатор', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        // Выбор единственного слота-перечня
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _selectedSlotId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Слот (перечень) для маршрутизации'),
                items: [
                  for (final s in _enumSlots)
                    DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text('${s.id}: ${s.label.isNotEmpty ? s.label : s.name}'),
                    ),
                ],
                onChanged: (v) {
                  setState(() => _selectedSlotId = v);
                  if (v != null) widget.onSelectSlot(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedSlotId == null)
          Text('Выберите слот-перечень для настроек маршрутизации', style: Theme.of(context).textTheme.bodySmall)
        else
          const SizedBox.shrink(),
        const SizedBox(height: 16),
        // Таблица значений -> следующий шаг
        if (selectedSlot != null) ...[
          Text('Назначение шагов для значений слота: ${selectedSlot.label.isNotEmpty ? selectedSlot.label : selectedSlot.name}',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Column(
            children: [
              for (final v in selectedSlot.options)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: mappings[v],
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Следующий шаг'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('— нет —')),
                            for (final st in widget.steps.where((e) => e.id != widget.current.id))
                              DropdownMenuItem<int?>(
                                value: st.id,
                                child: Text('${st.id}: ${st.label.isNotEmpty ? st.label : st.name}'),
                              ),
                          ],
                          onChanged: (n) => setState(() => widget.onSetOptionNext(selectedSlot.id, v, n)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

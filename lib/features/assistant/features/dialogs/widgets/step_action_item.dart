import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';

/// Элемент списка действий шага: выбор слота, выбор действия, поле значения и кнопка удаления
/// Обёрнут в рамку с закруглениями для визуального отделения.
class StepActionItem extends StatelessWidget {
  const StepActionItem({
    super.key,
    required this.index,
    required this.action,
    required this.slots,
    required this.onUpdate,
    required this.onRemove,
    required this.buildValueEditor,
    required this.slotById,
  });

  final int index;
  final SlotSetAction action;
  final List<DialogSlot> slots;
  final ValueChanged<SlotSetAction> onUpdate;
  final VoidCallback onRemove;
  final Widget Function(int index, DialogSlot slot, SlotSetAction act) buildValueEditor;
  final DialogSlot? Function(int id) slotById;

  @override
  Widget build(BuildContext context) {
    final slot = slotById(action.slotId) ??
        (slots.isNotEmpty
            ? slots.first
            : const DialogSlot(
                id: 0,
                name: '',
                label: '',
                prompt: '',
                options: [],
                hints: [],
                metadata: {},
                slotType: 'string',
              ));

    String kind;
    if (action.clear) {
      kind = 'clear';
    } else if (action.setNull) {
      kind = 'set_null';
    } else {
      kind = 'set_value';
    }

    return Container
      (
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<int>(
              initialValue: slot.id == 0 ? null : slot.id,
              items: slots
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.id}: ${s.label}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final updated = SlotSetAction(
                  slotId: v,
                  setValue: action.setValue,
                  setNull: action.setNull,
                  clear: action.clear,
                  onlyIfAbsent: action.onlyIfAbsent,
                );
                onUpdate(updated);
              },
              decoration: const InputDecoration(labelText: 'Слот'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: kind,
              items: const [
                DropdownMenuItem(value: 'set_value', child: Text('Set value')),
                DropdownMenuItem(value: 'set_null', child: Text('Set null')),
                DropdownMenuItem(value: 'clear', child: Text('Clear')),
              ],
              onChanged: (v) {
                if (v == null) return;
                SlotSetAction updated;
                if (v == 'set_value') {
                  final s = slot;
                  Object? def;
                  switch (s.slotType) {
                    case 'boolean':
                      def = false;
                      break;
                    case 'integer':
                    case 'digit':
                      def = 0;
                      break;
                    case 'number':
                      def = 0.0;
                      break;
                    case 'enum':
                      def = s.options.isNotEmpty ? s.options.first : '';
                      break;
                    case 'json':
                      def = <String, dynamic>{};
                      break;
                    case 'repeatable':
                      def = <dynamic>[];
                      break;
                    default:
                      def = '';
                  }
                  updated = SlotSetAction(
                    slotId: action.slotId,
                    setValue: def,
                    onlyIfAbsent: action.onlyIfAbsent,
                  );
                } else if (v == 'set_null') {
                  updated = SlotSetAction(slotId: action.slotId, setNull: true);
                } else {
                  updated = SlotSetAction(slotId: action.slotId, clear: true);
                }
                onUpdate(updated);
              },
              decoration: const InputDecoration(labelText: 'Действие'),
            ),
          ),
          if (kind == 'set_value') ...[
            const SizedBox(height: 8),
            buildValueEditor(index, slot, action),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('only_if_absent'),
                const SizedBox(width: 6),
                Checkbox(
                  value: action.onlyIfAbsent,
                  onChanged: (v) {
                    onUpdate(
                      SlotSetAction(
                        slotId: action.slotId,
                        setValue: action.setValue,
                        onlyIfAbsent: v ?? false,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Удалить действие',
            ),
          ),
        ],
      ),
    );
  }
}

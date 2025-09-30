import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Панель свойств шага с редактированием ветвлений
class StepProps extends StatefulWidget {
  const StepProps({super.key, required this.step, required this.allSteps, required this.onUpdate});
  final DialogStep step;
  final List<DialogStep> allSteps;
  final ValueChanged<DialogStep> onUpdate;

  @override
  State<StepProps> createState() => _StepPropsState();
}

class _StepPropsState extends State<StepProps> {
  late DialogStep _current;
  String? _selectedSlotKey;

  @override
  void initState() {
    super.initState();
    _current = widget.step;
    _selectedSlotKey = _current.branchLogic.keys.isEmpty ? null : _current.branchLogic.keys.first;
  }

  @override
  void didUpdateWidget(covariant StepProps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id || oldWidget.step.branchLogic != widget.step.branchLogic) {
      _current = widget.step;
      if (_current.branchLogic.containsKey(_selectedSlotKey) == false) {
        _selectedSlotKey = _current.branchLogic.keys.isEmpty ? null : _current.branchLogic.keys.first;
      }
      setState(() {});
    }
  }

  void _apply(VoidCallback fn) {
    setState(() {
      fn();
      widget.onUpdate(_current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.allSteps;
    final slotKeys = _current.branchLogic.keys.toList();
    final rows = (_selectedSlotKey != null)
        ? _current.branchLogic[_selectedSlotKey!]!.entries.toList()
        : <MapEntry<String, int>>[];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          Text('ID: ${_current.id}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Ветвления', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Добавить ключ (slot_id) ветвления',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final ctrl = TextEditingController();
                      return AlertDialog(
                        title: const Text('Новый slot_id'),
                        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'например: 26')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                          FilledButton(
                            onPressed: () {
                              final key = ctrl.text.trim();
                              if (key.isNotEmpty && !_current.branchLogic.containsKey(key)) {
                                _apply(() {
                                  final map = Map<String, Map<String, int>>.from(_current.branchLogic);
                                  map[key] = <String, int>{};
                                  _current = DialogStep(
                                    id: _current.id,
                                    name: _current.name,
                                    label: _current.label,
                                    instructions: _current.instructions,
                                    requiredSlotsIds: _current.requiredSlotsIds,
                                    optionalSlotsIds: _current.optionalSlotsIds,
                                    next: _current.next,
                                    branchLogic: map,
                                  );
                                  _selectedSlotKey = key;
                                });
                              }
                              Navigator.pop(ctx);
                            },
                            child: const Text('Добавить'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSlotKey,
            items: [
              for (final k in slotKeys) DropdownMenuItem(value: k, child: Text('slot: $k')),
            ],
            onChanged: (v) => setState(() => _selectedSlotKey = v),
            decoration: const InputDecoration(isDense: true, labelText: 'Ключ ветвления (slot_id)'),
          ),
          if (_selectedSlotKey != null) ...[
            const SizedBox(height: 12),
            Text('Правила для slot=$_selectedSlotKey', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (int i = 0; i < rows.length; i++)
              _BranchRow(
                valueText: rows[i].key,
                nextId: rows[i].value,
                allSteps: steps,
                onChanged: (newValue, newNext) {
                  _apply(() {
                    final m = Map<String, Map<String, int>>.from(_current.branchLogic);
                    final inner = Map<String, int>.from(m[_selectedSlotKey!]!);
                    inner.remove(rows[i].key);
                    inner[newValue] = newNext;
                    m[_selectedSlotKey!] = inner;
                    _current = DialogStep(
                      id: _current.id,
                      name: _current.name,
                      label: _current.label,
                      instructions: _current.instructions,
                      requiredSlotsIds: _current.requiredSlotsIds,
                      optionalSlotsIds: _current.optionalSlotsIds,
                      next: _current.next,
                      branchLogic: m,
                    );
                  });
                },
                onDelete: () {
                  _apply(() {
                    final m = Map<String, Map<String, int>>.from(_current.branchLogic);
                    final inner = Map<String, int>.from(m[_selectedSlotKey!]!);
                    inner.remove(rows[i].key);
                    m[_selectedSlotKey!] = inner;
                    _current = DialogStep(
                      id: _current.id,
                      name: _current.name,
                      label: _current.label,
                      instructions: _current.instructions,
                      requiredSlotsIds: _current.requiredSlotsIds,
                      optionalSlotsIds: _current.optionalSlotsIds,
                      next: _current.next,
                      branchLogic: m,
                    );
                  });
                },
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Добавить правило'),
                onPressed: () {
                  _apply(() {
                    final m = Map<String, Map<String, int>>.from(_current.branchLogic);
                    final inner = Map<String, int>.from(m[_selectedSlotKey!]!);
                    inner['значение'] = 0; // нет перехода по умолчанию
                    m[_selectedSlotKey!] = inner;
                    _current = DialogStep(
                      id: _current.id,
                      name: _current.name,
                      label: _current.label,
                      instructions: _current.instructions,
                      requiredSlotsIds: _current.requiredSlotsIds,
                      optionalSlotsIds: _current.optionalSlotsIds,
                      next: _current.next,
                      branchLogic: m,
                    );
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({
    required this.valueText,
    required this.nextId,
    required this.allSteps,
    required this.onChanged,
    required this.onDelete,
  });
  final String valueText;
  final int nextId;
  final List<DialogStep> allSteps;
  final void Function(String value, int next) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final valueCtrl = TextEditingController(text: valueText);
    int currentNext = nextId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(isDense: true, labelText: 'Значение'),
              onChanged: (v) => onChanged(v, currentNext),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: currentNext,
              isDense: true,
              items: [
                for (final s in allSteps)
                  DropdownMenuItem(value: s.id, child: Text('${s.id}: ${s.label.isNotEmpty ? s.label : s.name}')),
              ],
              onChanged: (v) {
                if (v != null) {
                  currentNext = v;
                  onChanged(valueCtrl.text, v);
                }
              },
              decoration: const InputDecoration(labelText: 'Переход к шагу'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}

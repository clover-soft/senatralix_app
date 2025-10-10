import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_simple_props.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_router_props.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_action_item.dart';
import 'dart:async';
import 'dart:convert';

class StepProps extends ConsumerWidget {
  const StepProps({super.key, required this.stepId});

  final int stepId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(dialogsConfigControllerProvider);
    final steps = cfg.steps;
    final current = steps.firstWhere((e) => e.id == stepId);

    // Доступные ячейки памяти (слоты)
    final slotsAsync = ref.watch(dialogSlotsProvider);
    final List<DialogSlot> availableSlots = slotsAsync.maybeWhen(
      data: (slots) => slots,
      orElse: () => const <DialogSlot>[],
    );

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: current.name);
    final labelCtrl = TextEditingController(text: current.label);
    final instrCtrl = TextEditingController(text: current.instructions);
    int? nextId = current.next;
    // Локальные наборы выбранных ячеек памяти
    final Set<int> selectedOptional = {...current.optionalSlotsIds};
    final Set<int> selectedRequired = {...current.requiredSlotsIds};
    // Выбранная для добавления ячейка (для Dropdown)
    int? slotToAdd;
    // Тип шага: по branchLogic
    bool isRouter = current.branchLogic.isNotEmpty;
    // Редактируемая копия логики ветвления
    final Map<String, Map<String, int>> branchMap = {
      for (final entry in current.branchLogic.entries)
        entry.key: Map<String, int>.from(entry.value),
    };

    // Локальные списки действий on_enter/on_exit
    List<SlotSetAction> enterActions = List<SlotSetAction>.from(
      current.onEnter?.setSlots ?? const <SlotSetAction>[],
    );
    List<SlotSetAction> exitActions = List<SlotSetAction>.from(
      current.onExit?.setSlots ?? const <SlotSetAction>[],
    );

    // Хелперы удалены: редактор действий содержит собственную логику преобразований

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      // Если это маршрутизатор — игнорируем next и обнуляем
      if (isRouter) {
        nextId = null;
      }
      // Сформируем итоговые списки: обязательные и опциональные (без пересечений)
      final allSelected = <int>{...selectedOptional, ...selectedRequired};
      final requiredIds = selectedRequired.intersection(allSelected).toList();
      final optionalIds = allSelected.difference(selectedRequired).toList();

      // Если это маршрутизатор: добавим очистку слота ветвления в on_exit
      if (isRouter && branchMap.isNotEmpty) {
        final branchSlotKey = branchMap.keys.first; // ожидается один ключ
        final branchSlotId = int.tryParse(branchSlotKey);
        if (branchSlotId != null) {
          final already = exitActions.any((a) => a.slotId == branchSlotId && a.clear);
          if (!already) {
            // Удалим возможные другие действия по этому слоту и добавим clear
            exitActions.removeWhere((a) => a.slotId == branchSlotId);
            exitActions.add(SlotSetAction(slotId: branchSlotId, clear: true));
          }
        }
      }

      final updated = DialogStep(
        id: current.id,
        name: nameCtrl.text.trim(),
        label: labelCtrl.text.trim(),
        instructions: instrCtrl.text,
        requiredSlotsIds: requiredIds,
        optionalSlotsIds: optionalIds,
        next: nextId,
        branchLogic: isRouter ? branchMap : <String, Map<String, int>>{},
        onEnter: enterActions.isEmpty
            ? null
            : StepHookActions(setSlots: enterActions),
        onExit: exitActions.isEmpty
            ? null
            : StepHookActions(setSlots: exitActions),
      );
      // 1) Обновляем локальное состояние редактора (для мгновенной перерисовки графа)
      ref.read(dialogsEditorControllerProvider.notifier).updateStep(updated);
      // 2) Сообщаем бизнес-контроллеру о смене шага и сохраняем целиком
      final cfg = ref.read(dialogsConfigControllerProvider.notifier);
      cfg.updateStep(updated);
      // Запускаем отложенное сохранение, чтобы не бомбить API
      cfg.saveFullDebounced();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изменения будут сохранены')),
        );
        Navigator.of(context).pop(true);
      }
    }

    return AlertDialog(
      title: Text('Настройки шага ${current.label}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Заголовок (label)',
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Заполните заголовок';
                    if (s.length > 64) return 'Максимум 64 символа';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Системное имя (name)',
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Заполните имя';
                    if (s.length > 64) return 'Максимум 64 символа';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: instrCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Инструкции / описание',
                  ),
                ),
                const SizedBox(height: 16),
                // Переключатель типа шага
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Простой шаг'),
                              icon: Icon(Icons.edit_note),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Маршрутизатор'),
                              icon: Icon(Icons.alt_route),
                            ),
                          ],
                          selected: {isRouter},
                          onSelectionChanged: (set) {
                            setState(() => isRouter = set.contains(true));
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!isRouter)
                          StepSimpleProps(
                            current: current,
                            steps: steps,
                            availableSlots: availableSlots,
                            selectedOptional: selectedOptional,
                            selectedRequired: selectedRequired,
                            slotToAdd: slotToAdd,
                            onSetSlotToAdd: (v) =>
                                setState(() => slotToAdd = v),
                            nextId: nextId,
                            onNextChanged: (v) => setState(() => nextId = v),
                          )
                        else
                          StepRouterProps(
                            current: current,
                            steps: steps,
                            availableSlots: availableSlots,
                            branchMap: branchMap,
                            onSelectSlot: (slotId) {
                              setState(() {
                                final key = slotId.toString();
                                final existing = Map<String, int>.from(
                                  branchMap[key] ?? <String, int>{},
                                );
                                branchMap
                                  ..clear()
                                  ..[key] = existing;
                              });
                            },
                            onSetOptionNext: (slotId, value, next) {
                              setState(() {
                                final key = slotId.toString();
                                final map = branchMap.putIfAbsent(
                                  key,
                                  () => <String, int>{},
                                );
                                if (next == null) {
                                  map.remove(value);
                                } else {
                                  map[value] = next;
                                }
                              });
                            },
                          ),

                        const SizedBox(height: 16),

                        // Редактор on_enter / on_exit
                        _HookActionsEditor(
                          title: 'Действия при входе (on_enter)',
                          actions: enterActions,
                          availableSlots: availableSlots,
                          onChanged: (list) =>
                              setState(() => enterActions = list),
                        ),
                        const SizedBox(height: 12),
                        _HookActionsEditor(
                          title: 'Действия при выходе (on_exit)',
                          actions: exitActions,
                          availableSlots: availableSlots,
                          onChanged: (list) =>
                              setState(() => exitActions = list),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: () async => save(),
          icon: const Icon(Icons.save),
          label: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _HookActionsEditor extends StatefulWidget {
  const _HookActionsEditor({
    required this.title,
    required this.actions,
    required this.availableSlots,
    required this.onChanged,
  });

  final String title;
  final List<SlotSetAction> actions;
  final List<DialogSlot> availableSlots;
  final ValueChanged<List<SlotSetAction>> onChanged;

  @override
  State<_HookActionsEditor> createState() => _HookActionsEditorState();
}

class _HookActionsEditorState extends State<_HookActionsEditor> {
  List<SlotSetAction> get _items => widget.actions;

  void _notify() => widget.onChanged(List<SlotSetAction>.from(_items));

  DialogSlot? _slotById(int id) => widget.availableSlots.firstWhere(
    (s) => s.id == id,
    orElse: () => const DialogSlot(
      id: 0,
      name: '',
      label: '',
      prompt: '',
      options: [],
      hints: [],
      metadata: {},
      slotType: 'string',
    ),
  );

  void _add() {
    final firstId = widget.availableSlots.isNotEmpty
        ? widget.availableSlots.first.id
        : 0;
    setState(() {
      _items.add(SlotSetAction(slotId: firstId, setNull: true));
      _notify();
    });
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index);
      _notify();
    });
  }

  Widget _buildValueEditor(int index, DialogSlot slot, SlotSetAction act) {
    // Только для setValue
    final v = act.setValue;
    switch (slot.slotType) {
      case 'boolean':
        final boolVal = (v is bool) ? v : false;
        return Row(
          children: [
            const SizedBox(width: 8),
            const Text('Значение:'),
            const SizedBox(width: 8),
            Switch(
              value: boolVal,
              onChanged: (nv) {
                setState(() {
                  _items[index] = SlotSetAction(
                    slotId: act.slotId,
                    setValue: nv,
                    onlyIfAbsent: act.onlyIfAbsent,
                  );
                  _notify();
                });
              },
            ),
          ],
        );
      case 'integer':
      case 'digit':
        final text = TextEditingController(
          text: (v is int ? v : int.tryParse('${v ?? ''}') ?? 0).toString(),
        );
        return SizedBox(
          width: 140,
          child: TextField(
            controller: text,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'int'),
            onChanged: (t) {
              final nv = int.tryParse(t) ?? 0;
              _items[index] = SlotSetAction(
                slotId: act.slotId,
                setValue: nv,
                onlyIfAbsent: act.onlyIfAbsent,
              );
              _notify();
            },
          ),
        );
      case 'number':
        final text = TextEditingController(
          text: (v is num ? v : num.tryParse('${v ?? ''}') ?? 0).toString(),
        );
        return SizedBox(
          width: 160,
          child: TextField(
            controller: text,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'float'),
            onChanged: (t) {
              final nv = double.tryParse(t) ?? 0.0;
              _items[index] = SlotSetAction(
                slotId: act.slotId,
                setValue: nv,
                onlyIfAbsent: act.onlyIfAbsent,
              );
              _notify();
            },
          ),
        );
      case 'enum':
        final opts = slot.options;
        final cur = (v is String && opts.contains(v))
            ? v
            : (opts.isNotEmpty ? opts.first : '');
        return DropdownButton<String>(
          value: cur.isEmpty ? null : cur,
          hint: const Text('Значение'),
          items: opts
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (nv) {
            setState(() {
              _items[index] = SlotSetAction(
                slotId: act.slotId,
                setValue: nv ?? '',
                onlyIfAbsent: act.onlyIfAbsent,
              );
              _notify();
            });
          },
        );
      case 'json':
      case 'repeatable':
        final text = TextEditingController(
          text: v == null ? '' : const JsonEncoder.withIndent('  ').convert(v),
        );
        return SizedBox(
          width: 320,
          child: TextField(
            controller: text,
            decoration: const InputDecoration(labelText: 'JSON'),
            maxLines: 4,
            onChanged: (t) {
              dynamic parsed = t;
              try {
                parsed = jsonDecode(t);
              } catch (_) {}
              _items[index] = SlotSetAction(
                slotId: act.slotId,
                setValue: parsed,
                onlyIfAbsent: act.onlyIfAbsent,
              );
              _notify();
            },
          ),
        );
      default:
        final text = TextEditingController(text: v?.toString() ?? '');
        return SizedBox(
          width: 240,
          child: TextField(
            controller: text,
            decoration: const InputDecoration(labelText: 'Текст'),
            onChanged: (t) {
              _items[index] = SlotSetAction(
                slotId: act.slotId,
                setValue: t,
                onlyIfAbsent: act.onlyIfAbsent,
              );
              _notify();
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Добавить действие'),
          )
        else
          Column(
            children: [
              for (int i = 0; i < _items.length; i++)
                StepActionItem(
                  index: i,
                  action: _items[i],
                  slots: widget.availableSlots,
                  onUpdate: (act) {
                    setState(() {
                      _items[i] = act;
                      _notify();
                    });
                  },
                  onRemove: () => _removeAt(i),
                  buildValueEditor: _buildValueEditor,
                  slotById: _slotById,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить действие'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

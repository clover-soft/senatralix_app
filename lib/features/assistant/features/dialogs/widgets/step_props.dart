import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_editor_providers.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_simple_props.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/step_router_props.dart';
import 'dart:async';

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

      final updated = DialogStep(
        id: current.id,
        name: nameCtrl.text.trim(),
        label: labelCtrl.text.trim(),
        instructions: instrCtrl.text,
        requiredSlotsIds: requiredIds,
        optionalSlotsIds: optionalIds,
        next: nextId,
        branchLogic: isRouter ? branchMap : <String, Map<String, int>>{},
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

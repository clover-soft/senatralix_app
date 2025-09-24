import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/script_command_step.dart';
import '../models/script_list_item.dart';
import '../providers/assistant_scripts_provider.dart';
import 'script_step_editor_dialog.dart';

/// Карточка со списком шагов скрипта и поддержкой drag'n'drop
class ScriptStepsList extends ConsumerWidget {
  const ScriptStepsList({super.key, required this.existingItem});

  final ScriptListItem? existingItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (existingItem == null || existingItem!.id == 0) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Сохраните скрипт, чтобы управлять шагами.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final commandId = existingItem!.id;
    final stepsAsync = ref.watch(scriptStepsProvider(commandId));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Шаги скрипта',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            stepsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Не удалось загрузить шаги: $error',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              data: (steps) {
                if (steps.isEmpty) {
                  return Text(
                    'Шаги не добавлены.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                return _ScriptStepsReorderable(
                  commandId: commandId,
                  initialSteps: steps,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScriptStepsReorderable extends ConsumerStatefulWidget {
  const _ScriptStepsReorderable({
    required this.commandId,
    required this.initialSteps,
  });

  final int commandId;
  final List<ScriptCommandStep> initialSteps;

  @override
  ConsumerState<_ScriptStepsReorderable> createState() =>
      _ScriptStepsReorderableState();
}

class _ScriptStepsReorderableState
    extends ConsumerState<_ScriptStepsReorderable> {
  late List<ScriptCommandStep> _steps;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _steps = _normalize(widget.initialSteps);
  }

  @override
  void didUpdateWidget(covariant _ScriptStepsReorderable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.initialSteps, widget.initialSteps)) {
      _steps = _normalize(widget.initialSteps);
    }
  }

  List<ScriptCommandStep> _normalize(List<ScriptCommandStep> source) {
    return List<ScriptCommandStep>.generate(
      source.length,
      (index) => source[index].copyWith(priority: index + 1),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final prev = List<ScriptCommandStep>.from(_steps);
    if (oldIndex < newIndex) newIndex -= 1;

    final reordered = List<ScriptCommandStep>.from(_steps);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final normalized = _normalize(reordered);
    setState(() => _steps = normalized);

    try {
      await ref
          .read(
            scriptStepsReorderProvider(
              (commandId: widget.commandId, stepIds: _steps.map((e) => e.id).toList()),
            ).future,
          )
          .timeout(const Duration(seconds: 1));
      ref.invalidate(scriptStepsProvider(widget.commandId));
      _showSnack('Порядок шагов обновлён');
    } catch (e) {
      _showSnack('Не удалось поменять порядок: $e');
      setState(() => _steps = prev);
    }
  }

  Future<void> _onToggleActive(ScriptCommandStep step, bool value) async {
    if (_isProcessing) return;
    final previous = step.isActive;
    setState(() {
      final idx = _steps.indexWhere((s) => s.id == step.id);
      if (idx >= 0) {
        _steps[idx] = _steps[idx].copyWith(isActive: value);
      }
    });

    try {
      await ref
          .read(
            scriptStepActiveProvider((stepId: step.id, isActive: value)).future,
          )
          .timeout(const Duration(seconds: 1));
      ref.invalidate(scriptStepsProvider(widget.commandId));
      _showSnack(value ? 'Шаг включён' : 'Шаг выключен');
    } catch (e) {
      _showSnack('Не удалось обновить активность: $e');
      setState(() {
        final idx = _steps.indexWhere((s) => s.id == step.id);
        if (idx >= 0) {
          _steps[idx] = _steps[idx].copyWith(isActive: previous);
        }
      });
    }
  }

  Future<void> _onDelete(ScriptCommandStep step) async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить шаг?'),
        content: Text('Шаг "${step.name}" будет удалён безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prev = List<ScriptCommandStep>.from(_steps);
    setState(() {
      _isProcessing = true;
      _steps = _normalize(
        _steps.where((s) => s.id != step.id).toList(),
      );
    });

    try {
      await ref
          .read(scriptStepDeleteProvider(step.id).future)
          .timeout(const Duration(seconds: 1));
      ref.invalidate(scriptStepsProvider(widget.commandId));
      _showSnack('Шаг удалён');
    } catch (e) {
      _showSnack('Не удалось удалить шаг: $e');
      setState(() => _steps = prev);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _onEdit(ScriptCommandStep step) async {
    final updated = await showDialog<ScriptCommandStep>(
      context: context,
      builder: (context) => ScriptStepEditorDialog(step: step),
    );
    if (updated == null) return;

    setState(() {
      final idx = _steps.indexWhere((s) => s.id == updated.id);
      if (idx != -1) {
        _steps[idx] = updated;
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final step = _steps[index];
        return Padding(
          key: ValueKey('step-${step.id}'),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _StepTile(
            index: index,
            step: step,
            onEdit: () => _onEdit(step),
            onDelete: () => _onDelete(step),
            onToggleActive: (value) => _onToggleActive(step, value),
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final int index;
  final ScriptCommandStep step;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PriorityBadge(priority: step.priority),
              const SizedBox(width: 12),
              Switch(
                value: step.isActive,
                onChanged: onToggleActive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.actionName.isNotEmpty
                          ? 'Действие: ${step.actionName}'
                          : 'Действие: не указано',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ReorderableDragStartListener(
                index: index,
                child: Tooltip(
                  message: 'Переместить',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.drag_indicator),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Удалить',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '$priority',
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
  }
}

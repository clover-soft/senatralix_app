import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentralix_app/features/assistant/features/tools/data/tool_presets.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_tools_provider.dart';

/// Карточка со списком инструментов ассистента и поддержкой drag'n'drop
class ToolsListCard extends ConsumerStatefulWidget {
  const ToolsListCard({
    super.key,
    required this.assistantId,
    required this.initialTools,
    this.maxHeight,
  });

  final String assistantId;
  final List<AssistantTool> initialTools;
  final double? maxHeight;

  @override
  ConsumerState<ToolsListCard> createState() => _ToolsListCardState();
}

class _ToolsDragTargetArea extends StatelessWidget {
  const _ToolsDragTargetArea({
    required this.tools,
    required this.onReorder,
    required this.onToggle,
    required this.onDelete,
    required this.onPresetDrop,
  });

  final List<AssistantTool> tools;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(AssistantTool, bool) onToggle;
  final void Function(AssistantTool) onDelete;
  final Future<void> Function(ToolPreset) onPresetDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<ToolPreset>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) async {
        await onPresetDrop(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        final borderColor = highlight
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant;

        if (tools.isEmpty) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: highlight ? 2 : 1.2,
              ),
              color: highlight
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.colorScheme.surfaceContainerHigh,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: highlight
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  highlight
                      ? 'Отпустите, чтобы добавить инструмент'
                      : 'Перетащите пресет, чтобы добавить первый инструмент',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: highlight
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            top: highlight ? 12 : 0,
            left: highlight ? 8 : 0,
            right: highlight ? 8 : 0,
          ),
          decoration: highlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.8),
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                )
              : null,
          child: Scrollbar(
            thumbVisibility: true,
            child: ReorderableListView.builder(
              padding: EdgeInsets.zero,
              buildDefaultDragHandles: false,
              onReorder: onReorder,
              itemCount: tools.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final tool = tools[index];
                return Padding(
                  key: ValueKey('tool-${tool.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _ToolTile(
                    tool: tool,
                    index: index,
                    onToggle: (value) => onToggle(tool, value),
                    onDelete: () => onDelete(tool),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ToolsListCardState extends ConsumerState<ToolsListCard> {
  late List<AssistantTool> _tools;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _tools = List<AssistantTool>.from(widget.initialTools);
  }

  @override
  void didUpdateWidget(covariant ToolsListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.initialTools, widget.initialTools)) {
      _tools = List<AssistantTool>.from(widget.initialTools);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_isBusy) return;
    if (oldIndex < newIndex) newIndex -= 1;
    final prev = List<AssistantTool>.from(_tools);
    final reordered = List<AssistantTool>.from(_tools);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() => _tools = reordered);

    try {
      await ref.read(assistantToolsProvider.notifier).reorder(
            assistantId: widget.assistantId,
            ordered: reordered,
          );
    } catch (e) {
      setState(() => _tools = prev);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось изменить порядок: $e')));
      }
    }
  }

  Future<void> _onToggle(AssistantTool tool, bool value) async {
    final idx = _tools.indexWhere((t) => t.id == tool.id);
    if (idx == -1) return;
    final prev = _tools[idx];
    setState(() => _tools[idx] = prev.copyWith(isActive: value));

    try {
      await ref.read(assistantToolsProvider.notifier).setActive(
            assistantId: widget.assistantId,
            toolId: tool.id,
            isActive: value,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось обновить статус: $e')));
      setState(() => _tools[idx] = prev);
    }
  }

  Future<void> _onDelete(AssistantTool tool) async {
    if (_isBusy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить инструмент?'),
        content: Text(
          'Инструмент "${tool.displayName.isNotEmpty ? tool.displayName : tool.name}" будет удалён безвозвратно.',
        ),
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
    if (confirm != true) return;

    setState(() => _isBusy = true);
    final prev = List<AssistantTool>.from(_tools);
    setState(() => _tools = prev.where((e) => e.id != tool.id).toList());

    try {
      await ref
          .read(assistantToolsProvider.notifier)
          .delete(assistantId: widget.assistantId, toolId: tool.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось удалить: $e')));
      setState(() => _tools = prev);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onPresetDrop(ToolPreset preset) async {
    if (_isBusy) return;

    final nameCtrl = TextEditingController(text: preset.title);
    final descCtrl = TextEditingController(text: preset.description);
    bool isActive = true;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создание инструмента "${preset.title}"'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Отображаемое название'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Активен'),
                  const SizedBox(width: 8),
                  StatefulBuilder(
                    builder: (context, setLocal) => Switch(
                      value: isActive,
                      onChanged: (v) => setLocal(() => isActive = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название инструмента')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (accepted != true) return;

    setState(() => _isBusy = true);
    try {
      final created = await ref.read(assistantToolsProvider.notifier).createFunctionTool(
            assistantId: widget.assistantId,
            name: preset.name,
            displayName: nameCtrl.text.trim(),
            description: descCtrl.text.trim(),
            parameters: Map<String, dynamic>.from(preset.parameters),
            isActive: isActive,
          );
      setState(() => _tools = [..._tools, created]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось создать инструмент: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Инструменты ассистента',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_isBusy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Если maxHeight задан (широкая раскладка) — используем Expanded,
            // чтобы занять оставшуюся высоту карточки без переполнения.
            if (widget.maxHeight != null)
              Expanded(
                child: _ToolsDragTargetArea(
                  tools: _tools,
                  onReorder: _onReorder,
                  onToggle: _onToggle,
                  onDelete: _onDelete,
                  onPresetDrop: _onPresetDrop,
                ),
              )
            else
              SizedBox(
                height: (widget.maxHeight ?? 480).clamp(320.0, 1000.0),
                child: _ToolsDragTargetArea(
                  tools: _tools,
                  onReorder: _onReorder,
                  onToggle: _onToggle,
                  onDelete: _onDelete,
                  onPresetDrop: _onPresetDrop,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.tool,
    required this.index,
    required this.onToggle,
    required this.onDelete,
  });

  final AssistantTool tool;
  final int index;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = tool.name == 'transferCall'
        ? Icons.phone_forwarded
        : tool.name == 'hangupCall'
            ? Icons.call_end
            : Icons.extension;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tool.displayName.isNotEmpty ? tool.displayName : tool.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (tool.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tool.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${tool.id} • ${tool.name} • ${tool.isActive ? 'Активен' : 'Отключён'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: tool.isActive, onChanged: onToggle),
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.drag_indicator),
              ),
            ),
            IconButton(
              tooltip: 'Удалить',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

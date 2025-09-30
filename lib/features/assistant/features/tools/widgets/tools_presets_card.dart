import 'package:flutter/material.dart';

import 'package:sentralix_app/features/assistant/features/tools/data/tool_presets.dart';

/// Карточка пресетов инструментов. Каждый пресет — Draggable<ToolPreset>.
class ToolsPresetsCard extends StatelessWidget {
  const ToolsPresetsCard({super.key});

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
            Text(
              'Пресеты инструментов',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Зажмите карточку и перенесите её в область списка, чтобы добавить новый инструмент',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: kToolPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final preset = kToolPresets[index];
                    return _ToolPresetTile(preset: preset);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolPresetTile extends StatefulWidget {
  const _ToolPresetTile({required this.preset});

  final ToolPreset preset;

  @override
  State<_ToolPresetTile> createState() => _ToolPresetTileState();
}

class _ToolPresetTileState extends State<_ToolPresetTile> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = _ToolPresetCard(
      preset: widget.preset,
      isDragging: _dragging,
      theme: theme,
    );

    return MouseRegion(
      cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: Draggable<ToolPreset>(
        data: widget.preset,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _ToolPresetFeedback(preset: widget.preset, theme: theme),
        childWhenDragging: Opacity(opacity: 0.4, child: tile),
        onDragStarted: () => setState(() => _dragging = true),
        onDragEnd: (_) => setState(() => _dragging = false),
        onDraggableCanceled: (_, __) => setState(() => _dragging = false),
        onDragCompleted: () => setState(() => _dragging = false),
        child: tile,
      ),
    );
  }
}

class _ToolPresetCard extends StatelessWidget {
  const _ToolPresetCard({
    required this.preset,
    required this.isDragging,
    required this.theme,
  });

  final ToolPreset preset;
  final bool isDragging;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isDragging ? 1.6 : 1),
        color: isDragging
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                Icons.extension,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (preset.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Перетащите в список инструментов',
              child: Icon(
                Icons.drag_indicator,
                size: 20,
                color: borderColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolPresetFeedback extends StatelessWidget {
  const _ToolPresetFeedback({required this.preset, required this.theme});

  final ToolPreset preset;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.primary, width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                  Icons.extension,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                preset.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.drag_indicator,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

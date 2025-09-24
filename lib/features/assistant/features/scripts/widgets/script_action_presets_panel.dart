import 'package:flutter/material.dart';

import '../data/presets/script_action_preset.dart';
import '../data/presets/script_action_presets.dart';

/// Панель с пресетами действий скрипта для drag'n'drop
class ScriptActionPresetsPanel extends StatelessWidget {
  const ScriptActionPresetsPanel({super.key, this.enabled = true});

  /// Разрешить перетаскивание пресетов (только для сохранённых команд)
  final bool enabled;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Пресеты шагов',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Зажмите карточку и перенесите её в список шагов, чтобы создать новый шаг.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kScriptActionPresets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final preset = kScriptActionPresets[index];
                return _PresetDraggableTile(preset: preset, enabled: enabled);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetDraggableTile extends StatefulWidget {
  const _PresetDraggableTile({required this.preset, required this.enabled});

  final ScriptActionPreset preset;
  final bool enabled;

  @override
  State<_PresetDraggableTile> createState() => _PresetDraggableTileState();
}

class _PresetDraggableTileState extends State<_PresetDraggableTile> {
  bool _isDragging = false;

  void _setDragging(bool value) {
    if (!mounted) return;
    setState(() => _isDragging = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = _PresetTile(
      preset: widget.preset,
      theme: theme,
      isDragging: _isDragging,
    );

    final content = MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      child: Draggable<ScriptActionPreset>(
        data: widget.preset,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _PresetDragFeedback(preset: widget.preset, theme: theme),
        childWhenDragging: Opacity(opacity: 0.4, child: tile),
        onDragStarted: () => _setDragging(true),
        onDragEnd: (_) => _setDragging(false),
        onDraggableCanceled: (_, __) => _setDragging(false),
        onDragCompleted: () => _setDragging(false),
        child: tile,
      ),
    );

    if (!widget.enabled) {
      return Opacity(
        opacity: 0.5,
        child: AbsorbPointer(child: tile),
      );
    }

    return content;
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.theme,
    required this.isDragging,
  });

  final ScriptActionPreset preset;
  final ThemeData theme;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final outline = isDragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline, width: isDragging ? 1.6 : 1),
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
              child: Text(
                preset.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Перетащите в список шагов',
              child: Icon(Icons.drag_indicator, size: 20, color: outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetDragFeedback extends StatelessWidget {
  const _PresetDragFeedback({required this.preset, required this.theme});

  final ScriptActionPreset preset;
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

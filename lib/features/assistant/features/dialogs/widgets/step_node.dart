import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/widgets/dialogs_node_actions_panel.dart';

/// Виджет ноды графа (шаг сценария)
class StepNode extends StatelessWidget {
  const StepNode({
    super.key,
    required this.step,
    required this.selected,
    this.onAddNext,
    this.onSettings,
    this.onDelete,
  });
  final DialogStep step;
  final bool selected;
  final VoidCallback? onAddNext;
  final VoidCallback? onSettings;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // База для тени: темнее в тёмной теме, мягче в светлой
    final shadowColor = (isDark ? Colors.black : Colors.black).withValues(
      alpha: isDark ? 0.28 : 0.14,
    );
    final shadowBlur = selected ? 12.0 : 9.0;
    final shadowOffset = selected ? const Offset(0, 3) : const Offset(0, 2);
    final shadowSpread = selected ? 0.4 : 0.2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
          // Резервируем место под панель действий снизу справа
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              // Основная мягкая тень
              BoxShadow(
                color: shadowColor,
                blurRadius: shadowBlur,
                spreadRadius: shadowSpread,
                offset: shadowOffset,
              ),
              // Лёгкая подсветка снизу для лучшего отделения на тёмной теме
              if (isDark)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          // Оборачиваем содержимое в прокрутку и жёстко ограничиваем высоту
          // равной доступной высоте контейнера (исключает RenderFlex overflow)
          clipBehavior: Clip.hardEdge,
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final h = cons.maxHeight.isFinite ? cons.maxHeight : null;
              return SizedBox(
                height: h,
                child: SingleChildScrollView(
                  primary: false,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step.label.isNotEmpty ? step.label : step.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            step.next?.toString() ?? '—',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      if (step.branchLogic.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final entry in step.branchLogic.entries)
                              for (final v in entry.value.entries)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.orange.shade400,
                                    ),
                                  ),
                                  child: Text(
                                    '${v.key} → ${v.value}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: DialogsNodeActionsPanel(
            // Скрываем кнопку "+" если для шага уже назначен следующий шаг
            onAddNext: step.next == null ? onAddNext : null,
            onSettings: onSettings,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }
}

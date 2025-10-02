import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Виджет ноды графа (шаг сценария)
class StepNode extends StatefulWidget {
  const StepNode({
    super.key,
    required this.step,
    required this.selected,
    this.onAddNext,
  });
  final DialogStep step;
  final bool selected;
  final VoidCallback? onAddNext;

  @override
  State<StepNode> createState() => _StepNodeState();
}

class _StepNodeState extends State<StepNode> {
  bool _hoverHandle = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = (isDark ? Colors.black : Colors.black).withOpacity(
      isDark ? 0.28 : 0.14,
    );
    final shadowBlur = widget.selected ? 12.0 : 9.0;
    final shadowOffset = widget.selected
        ? const Offset(0, 3)
        : const Offset(0, 2);
    final shadowSpread = widget.selected ? 0.4 : 0.2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
          // Резерв под нижний хэндл, чтобы он попадал в границы hit-теста
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 26),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(
              color: widget.selected ? scheme.primary : scheme.outlineVariant,
              width: widget.selected ? 2 : 1,
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
                  color: Colors.white.withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.step.label.isNotEmpty
                    ? widget.step.label
                    : widget.step.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                widget.step.name,
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
                    widget.step.next?.toString() ?? '—',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              if (widget.step.branchLogic.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in widget.step.branchLogic.entries)
                      for (final v in entry.value.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade400),
                          ),
                          child: Text(
                            '${v.key} → ${v.value}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Хэндл добавления next: снизу по центру (ориентация сверху-вниз)
        Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: Center(
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoverHandle = true),
              onExit: (_) => setState(() => _hoverHandle = false),
              child: Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: widget.onAddNext,
                  radius: 22,
                  containedInkWell: true,
                  child: AnimatedScale(
                    scale: _hoverHandle ? 1.5 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

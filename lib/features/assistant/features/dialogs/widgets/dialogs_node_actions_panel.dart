import 'package:flutter/material.dart';

/// Панель действий ноды: добавить next, настройки, удалить
class DialogsNodeActionsPanel extends StatelessWidget {
  const DialogsNodeActionsPanel({
    super.key,
    required this.onAddNext,
    required this.onSettings,
    required this.onDelete,
  });

  final VoidCallback? onAddNext;
  final VoidCallback? onSettings;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget action({
      required String tooltip,
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      return _HoverScale(
        child: Tooltip(
          message: tooltip,
          child: InkResponse(
            onTap: onTap,
            radius: 22,
            containedInkWell: true,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          action(tooltip: 'Добавить шаг', icon: Icons.add, onTap: onAddNext),
          const SizedBox(width: 8),
          action(
            tooltip: 'Настройки шага',
            icon: Icons.settings,
            onTap: onSettings,
          ),
          const SizedBox(width: 8),
          action(
            tooltip: 'Удалить шаг',
            icon: Icons.delete_outline,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Ховер-обёртка с увеличением масштаба
class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.5 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

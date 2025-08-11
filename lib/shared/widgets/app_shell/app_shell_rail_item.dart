import 'package:flutter/material.dart';

class AppShellRailItem extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool selected; // active state like NavigationRailDestination
  const AppShellRailItem({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  State<AppShellRailItem> createState() => _AppShellRailItemState();
}

class _AppShellRailItemState extends State<AppShellRailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).navigationRailTheme;
    final Color indicatorColor =
        navTheme.indicatorColor ?? const Color(0x143F51B5);
    final Color unselectedIconColor =
        navTheme.unselectedIconTheme?.color ?? Colors.grey;
    final Color selectedIconColor =
        navTheme.selectedIconTheme?.color ??
        Theme.of(context).colorScheme.primary;
    final TextStyle? selectedLabelStyle = navTheme.selectedLabelTextStyle;
    final TextStyle? unselectedLabelStyle = navTheme.unselectedLabelTextStyle;

    // Highlight when selected or hovered
    final bool highlight = widget.selected || _hover;
    final Color iconColor = highlight ? selectedIconColor : unselectedIconColor;

    return SizedBox(
      height: 48,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: true,
        onEnter: (_) {
          setState(() => _hover = true);
        },
        onExit: (_) {
          setState(() => _hover = false);
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              // pill-shaped icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                height: 36,
                width: 56,
                margin: const EdgeInsets.only(right: 12, left: 12),
                decoration: ShapeDecoration(
                  color: highlight ? indicatorColor : Colors.transparent,
                  shape: navTheme.indicatorShape ?? const StadiumBorder(),
                ),
                child: Center(child: Icon(widget.icon, color: iconColor)),
              ),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: (highlight
                      ? selectedLabelStyle
                      : unselectedLabelStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

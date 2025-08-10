// comment: Trailing container for AppShell NavigationRail
import 'package:flutter/material.dart';

class AppShellTrailing extends StatelessWidget {
  final double width;
  final double expandedWidth;
  final bool expanded;
  const AppShellTrailing({
    super.key,
    required this.width,
    required this.expandedWidth,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        // color: Colors.green,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          // height: 80,
          width: expanded ? expandedWidth : width,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  _ProfileRailItem(expanded: expanded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRailItem extends StatefulWidget {
  final bool expanded;
  const _ProfileRailItem({required this.expanded});

  @override
  State<_ProfileRailItem> createState() => _ProfileRailItemState();
}

class _ProfileRailItemState extends State<_ProfileRailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final railTheme = NavigationRailTheme.of(context);
    final iconUnsel = railTheme.unselectedIconTheme ?? IconTheme.of(context);
    final iconSel =
        railTheme.selectedIconTheme ??
        iconUnsel.copyWith(color: Theme.of(context).colorScheme.primary);
    final labelUnsel =
        railTheme.unselectedLabelTextStyle ??
        Theme.of(context).textTheme.bodyMedium!;
    // Only icon should highlight on hover. Lock label style and color so it never changes on hover.
    final iconTheme = _hover ? iconSel : iconUnsel;
    final fallbackLabelColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;
    final labelStyle = labelUnsel.copyWith(
      color: labelUnsel.color ?? fallbackLabelColor,
    );

    // Hover background stays transparent; only icon changes color

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          // TODO: navigate to profile when ready
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: SizedBox(
              height: 56,
              child: widget.expanded
                  ? ClipRect(
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            IconTheme.merge(
                              data: iconTheme,
                              child: const Icon(Icons.person_outline),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Профиль',
                                style: labelStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: IconTheme.merge(
                        data: iconTheme,
                        child: const Icon(Icons.person_outline),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

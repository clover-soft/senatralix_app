import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/sessions/styles/subfeature_styles.dart';

class TimelineTitleBar extends StatelessWidget {
  final String title;
  final DateTime? callStart;
  const TimelineTitleBar({super.key, required this.title, this.callStart});

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d.$mo.$y $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final styles = SubfeatureStyles.of(context);
    final line = callStart != null && _fmtDateTime(callStart).isNotEmpty
        ? '$title • ${_fmtDateTime(callStart)}'
        : title;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Center(
          child: Text(
            line,
            style: styles.titleBarTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

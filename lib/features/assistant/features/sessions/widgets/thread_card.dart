import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/thread_item.dart';

/// Карточка треда (элемент списка)
class ThreadCard extends StatelessWidget {
  final ThreadItem item;
  final VoidCallback? onTap;

  const ThreadCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final created = _fmtDateTime(item.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                created,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title.isEmpty ? 'Без названия' : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '${d.year}.$mm.$dd $hh:$mi';
  }
}

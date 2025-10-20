import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/timeline_entry.dart';
import 'package:sentralix_app/features/assistant/features/sessions/styles/subfeature_styles.dart';

/// Сообщение в стиле чата. Один виджет для всех ролей (assistant/user/system)
class TimelineMessageBubble extends StatelessWidget {
  final AssistantMessageEntry message;

  /// Горизонтальное смещение хвостика от края пузыря (в пикселях)
  final double tailOffset;
  final bool highlight;
  const TimelineMessageBubble({
    super.key,
    required this.message,
    this.tailOffset = -10,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == MessageRole.assistant;
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    final styles = SubfeatureStyles.of(context);
    final bubbleStyle = isAssistant
        ? styles.assistantBubble
        : isUser
            ? styles.userBubble
            : styles.systemBubble;
    final border = highlight
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
        : (bubbleStyle.borderWidth > 0
            ? Border.all(color: bubbleStyle.borderColor, width: bubbleStyle.borderWidth)
            : null);
    final headerStyle = styles.headerTextStyle.copyWith(color: bubbleStyle.textColor);
    final contentStyle = styles.contentTextStyle.copyWith(color: bubbleStyle.textColor);

    final align = isSystem
        ? MainAxisAlignment.center
        : (isAssistant ? MainAxisAlignment.end : MainAxisAlignment.start);

    String two(int v) => v < 10 ? '0$v' : '$v';
    final t = message.createdAt;
    final timeStr = '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: align,
        children: [
          Flexible(
            child: Align(
              alignment: isSystem
                  ? Alignment.center
                  : (isAssistant ? Alignment.centerRight : Alignment.centerLeft),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                // Пузырь сообщения
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: bubbleStyle.background,
                    borderRadius: bubbleStyle.borderRadius,
                    border: border,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSystem)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 14, color: headerStyle.color),
                                const SizedBox(width: 6),
                                Text('Система', style: headerStyle),
                              ],
                            ),
                          )
                        else if (isAssistant)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Ассистент',
                              style: headerStyle,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Пользователь',
                              style: headerStyle,
                            ),
                          ),
                        Text(
                          message.content,
                          style: contentStyle,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(timeStr, style: styles.timeTextStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Хвостик: только для ассистента/пользователя
                if (!isSystem)
                  Positioned(
                    bottom: 0,
                    left: isUser ? tailOffset : null,
                    right: isAssistant ? tailOffset : null,
                    child: _BubbleTail(
                      color: bubbleStyle.background,
                      direction: isAssistant
                          ? _TailDirection.right
                          : _TailDirection.left,
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TailDirection { left, right }

class _BubbleTail extends StatelessWidget {
  final Color color;
  final _TailDirection direction;
  const _BubbleTail({required this.color, required this.direction});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 8),
      painter: _TailPainter(color: color, direction: direction, inset: 0),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  final _TailDirection direction;
  final double inset;
  _TailPainter({
    required this.color,
    required this.direction,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (direction == _TailDirection.left) {
      // Хвостик смотрит влево, нижний край на уровне низа пузыря
      path.moveTo(inset, size.height - inset); // нижняя точка у края
      path.lineTo(size.width - inset, size.height - inset); // нижняя правая
      path.lineTo(size.width - inset, inset); // верхняя правая
    } else {
      // Хвостик смотрит вправо, нижний край на уровне низа пузыря
      path.moveTo(
        size.width - inset,
        size.height - inset,
      ); // нижняя точка у края
      path.lineTo(inset, size.height - inset); // нижняя левая
      path.lineTo(inset, inset); // верхняя левая
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.direction != direction ||
        oldDelegate.inset != inset;
  }
}

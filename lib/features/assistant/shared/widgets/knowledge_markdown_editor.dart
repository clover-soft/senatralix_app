import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Поле редактирования Markdown для базы знаний ассистента
class KnowledgeMarkdownEditor extends StatelessWidget {
  const KnowledgeMarkdownEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    this.flexible = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Если true, основной блок редактора будет обёрнут в Expanded и займёт
  /// доступную высоту внутри родительского Flex (например, внутри SizedBox).
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF6F8FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final baseTextStyle = TextStyle(
      fontFamilyFallback: const ['NotoColorEmoji'],
      color: textColor,
    );
    final textStyle = GoogleFonts.robotoMono(textStyle: baseTextStyle);

    final editorBody = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Theme(
          data: theme.copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: textColor.withValues(alpha: 0.25),
              selectionHandleColor: textColor,
            ),
          ),
          child: TextField(
            controller: controller,
            style: textStyle,
            cursorColor: isDark ? Colors.grey.shade300 : Colors.black,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Текст в формате Markdown'),
        const SizedBox(height: 6),
        if (flexible) Expanded(child: editorBody) else editorBody,
        const SizedBox(height: 4),
        Text(
          'Текст в формате Markdown. Рекомендуется не слишком большие тексты.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

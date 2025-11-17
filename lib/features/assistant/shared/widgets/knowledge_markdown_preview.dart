import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

/// Блок предпросмотра Markdown для базы знаний ассистента
class KnowledgeMarkdownPreview extends StatelessWidget {
  const KnowledgeMarkdownPreview({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF6F8FA);
    final textColor = isDark ? Colors.white : Colors.black;

    final baseTextStyle = TextStyle(
      fontFamilyFallback: const ['NotoColorEmoji'],
      color: textColor,
    );
    final textStyle = GoogleFonts.robotoMono(textStyle: baseTextStyle);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectionArea(
        child: DefaultTextStyle(
          style: textStyle,
          child: GptMarkdown(markdown, style: textStyle),
        ),
      ),
    );
  }
}

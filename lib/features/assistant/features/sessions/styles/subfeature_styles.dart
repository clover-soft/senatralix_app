import 'package:flutter/material.dart';

/// Стилевой набор подфичи "Sessions/Timeline (чат)"
/// Содержит: цвета/бордеры пузырей (assistant/user/system),
/// шрифты заголовков и содержимого, фон чата.
class SubfeatureStyles {
  final Color chatBackground; // базовый цвет под изображением

  // Фон чата: изображение + градиент сверху
  final ImageProvider backgroundImage;
  final BoxFit backgroundFit;
  final Alignment backgroundAlignment;
  final Gradient backgroundGradient;
  final double gradientOpacity; // 0..1
  final double backgroundImageOpacity; // 0..1

  // Фон правой панели саммари (должен перекрывать текстуру)
  final Color summaryPanelBackground;

  final BubbleStyle assistantBubble;
  final BubbleStyle userBubble;
  final BubbleStyle systemBubble;

  /// Основной текст сообщений (контент)
  final TextStyle contentTextStyle;

  /// Заголовки внутри пузырей (например, подпись роли)
  final TextStyle headerTextStyle;
  /// Стиль временных меток (HH:mm:ss) внизу справа пузырей
  final TextStyle timeTextStyle;
  /// Стиль заголовка панели над плеером/тайтла
  final TextStyle titleBarTextStyle;

  const SubfeatureStyles({
    required this.chatBackground,
    required this.backgroundImage,
    this.backgroundFit = BoxFit.cover,
    this.backgroundAlignment = Alignment.center,
    required this.backgroundGradient,
    this.gradientOpacity = 0.06,
    required this.backgroundImageOpacity,
    required this.summaryPanelBackground,
    required this.assistantBubble,
    required this.userBubble,
    required this.systemBubble,
    required this.contentTextStyle,
    required this.headerTextStyle,
    required this.timeTextStyle,
    required this.titleBarTextStyle,
  });

  /// Светлая тема для чата
  factory SubfeatureStyles.light() {
    return SubfeatureStyles(
      chatBackground: const Color(0xFFF7F7F7),
      backgroundImage: const AssetImage('lib/assets/backgrounds/4.png'),
      backgroundFit: BoxFit.cover,
      backgroundAlignment: Alignment.center,
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 163, 174, 7), // 0% внизу-справа
          Color.fromARGB(204, 18, 123, 20), // ~80% в середине
          Color.fromARGB(255, 163, 174, 7), // 0% внизу-справа
        ],
      ),
      gradientOpacity: 0.6,
      backgroundImageOpacity: 0.4,
      summaryPanelBackground: const Color(0xFFFDFDFE),
      assistantBubble: BubbleStyle(
        background: const Color.fromARGB(255, 236, 255, 208),
        textColor: const Color.fromARGB(255, 70, 70, 70),
        borderColor: const Color.fromARGB(255, 236, 255, 208),
        borderWidth: 0.0,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(0), // под хвост ассистента справа
        ),
      ),
      userBubble: BubbleStyle(
        background: const Color.fromARGB(255, 255, 255, 255),
        textColor: const Color.fromARGB(255, 70, 70, 70),
        borderColor: const Color.fromARGB(255, 255, 255, 255),
        borderWidth: 0.0,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(0), // под хвост пользователя слева
          bottomRight: Radius.circular(16),
        ),
      ),
      systemBubble: BubbleStyle(
        // 50% прозрачности фона пузыря системы
        background: const Color(0x80F1F5F9),
        // Текст остаётся полностью непрозрачным
        textColor: const Color(0xFF334155),
        // Бордер убран
        borderColor: const Color(0x00000000),
        borderWidth: 0.0,
        borderRadius: BorderRadius.circular(12),
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: Color(0xFF0F172A),
      ),
      headerTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
      timeTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 10,
        height: 1.1,
        fontWeight: FontWeight.w500,
        color: Color(0xA664748B), // приглушённый серый
      ),
      titleBarTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  /// Тёмная тема для чата
  factory SubfeatureStyles.dark() {
    return SubfeatureStyles(
      // те же базовые параметры, что и в light()
      chatBackground: const Color(0xFFF7F7F7),
      backgroundImage: const AssetImage('lib/assets/backgrounds/4.png'),
      backgroundFit: BoxFit.cover,
      backgroundAlignment: Alignment.center,
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 163, 174, 7),
          Color.fromARGB(204, 18, 123, 20),
          Color.fromARGB(255, 163, 174, 7),
        ],
      ),
      gradientOpacity: 0.6,
      backgroundImageOpacity: 0.4,
      summaryPanelBackground: const Color(0xFFFDFDFE),
      // пузыри как в light()
      assistantBubble: BubbleStyle(
        background: const Color.fromARGB(255, 236, 255, 208),
        textColor: const Color.fromARGB(255, 70, 70, 70),
        borderColor: const Color.fromARGB(255, 236, 255, 208),
        borderWidth: 0.0,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(0),
        ),
      ),
      userBubble: BubbleStyle(
        background: const Color.fromARGB(255, 255, 255, 255),
        textColor: const Color.fromARGB(255, 70, 70, 70),
        borderColor: const Color.fromARGB(255, 255, 255, 255),
        borderWidth: 0.0,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(16),
        ),
      ),
      systemBubble: BubbleStyle(
        background: const Color(0x80F1F5F9),
        textColor: const Color(0xFF334155),
        borderColor: const Color(0x00000000),
        borderWidth: 0.0,
        borderRadius: BorderRadius.circular(12),
      ),
      // типографика как в light()
      contentTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: Color(0xFF0F172A),
      ),
      headerTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
      timeTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 10,
        height: 1.1,
        fontWeight: FontWeight.w500,
        color: Color(0xA664748B),
      ),
      titleBarTextStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  /// Выбор темы на основе Brightness
  factory SubfeatureStyles.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? SubfeatureStyles.dark()
        : SubfeatureStyles.light();
  }

  /// Готовый фон чата: изображение + градиентная вуаль сверху
  Widget buildChatBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(color: chatBackground)),
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: backgroundImage,
              fit: backgroundFit,
              alignment: backgroundAlignment,
              opacity: backgroundImageOpacity,
            ),
          ),
        ),
        Opacity(
          opacity: gradientOpacity,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class BubbleStyle {
  final Color background;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const BubbleStyle({
    required this.background,
    required this.textColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });
}

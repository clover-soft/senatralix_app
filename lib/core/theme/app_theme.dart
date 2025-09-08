import 'package:flutter/material.dart';

// lib/utils/theme.dart
enum AppThemeMode { light, dark }

class AppTheme {
  ThemeData themeData(AppThemeMode mode) {
    final isLight = mode == AppThemeMode.light;

    // M3: согласованная схема из seed-цвета
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 11, 78, 122),
      // seedColor: const Color.fromARGB(255, 32, 161, 20),
      brightness: isLight ? Brightness.light : Brightness.dark,
    );

    // Включаем Material 3 и задаём базовую схему + шрифт Akrobat
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Akrobat',
    );

    // Применяем Akrobat к текстовым темам
    final akrobatTextTheme = theme.textTheme.apply(fontFamily: 'Akrobat');
    final akrobatPrimaryTextTheme = theme.primaryTextTheme.apply(
      fontFamily: 'Akrobat',
    );

    // Цвет AppBar берём из схемы, чтобы зависел от seedColor
    final scheme = theme.colorScheme;
    final Color appBarBg = scheme.primary;

    return theme.copyWith(
      // Не фиксируем primary/onPrimary — используем то, что дал ColorScheme.fromSeed
      colorScheme: scheme,
      // Текстовые стили с учётом Akrobat и тонкой подстройки цветов
      textTheme: akrobatTextTheme.copyWith(
        bodyMedium: akrobatTextTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.grey[800] : Colors.grey[300],
        ),
        titleMedium: akrobatTextTheme.titleMedium?.copyWith(
          color: isLight ? Colors.grey[800] : Colors.grey[300],
        ),
      ),
      primaryTextTheme: akrobatPrimaryTextTheme,
      // NavigationRail под нашу палитру/шрифт (M3 совместим)
      navigationRailTheme: theme.navigationRailTheme.copyWith(
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(color: scheme.secondary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: akrobatTextTheme.labelMedium?.copyWith(
          color: scheme.secondary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: akrobatTextTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: theme.cardTheme.copyWith(
        color: isLight ? scheme.surface : scheme.surface,
        shadowColor: Colors.transparent,
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: appBarBg,
        titleTextStyle: akrobatPrimaryTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: (akrobatPrimaryTextTheme.titleLarge?.fontSize ?? 20) + 2,
          color: scheme.onPrimary,
        ),
        toolbarTextStyle: akrobatPrimaryTextTheme.bodyMedium?.copyWith(
          color: scheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      dividerTheme: theme.dividerTheme.copyWith(
        color: appBarBg,
        thickness: 1,
        space: 0,
      ),
      extensions: <ThemeExtension<dynamic>>[
        isLight ? CustomColors.light : CustomColors.dark,
      ],
    );
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color requestLinkColor;

  const CustomColors({required this.requestLinkColor});

  @override
  CustomColors copyWith({Color? requestLinkColor}) {
    return CustomColors(
      requestLinkColor: requestLinkColor ?? this.requestLinkColor,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      requestLinkColor: Color.lerp(
        requestLinkColor,
        other.requestLinkColor,
        t,
      )!,
    );
  }

  static const light = CustomColors(requestLinkColor: Color(0xFF0055ff));

  static const dark = CustomColors(
    requestLinkColor: Color.fromARGB(255, 60, 94, 195),
  );
}

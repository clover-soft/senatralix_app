import 'package:flutter/material.dart';

// lib/utils/theme.dart
enum AppThemeMode { light, dark }

class AppTheme {
  ThemeData themeData(AppThemeMode mode) {
    final isLight = mode == AppThemeMode.light;

    final baseTheme = ThemeData.from(
      colorScheme: isLight ? ColorScheme.light() : ColorScheme.dark(),
    );

    // Apply default font family Akrobat across text themes
    final akrobatTextTheme = baseTheme.textTheme.apply(fontFamily: 'Akrobat');
    final akrobatPrimaryTextTheme = baseTheme.primaryTextTheme.apply(fontFamily: 'Akrobat');

    final Color? appBarBg = isLight ? const Color(0xFF0F507B) : Colors.grey[900];

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: isLight ? const Color(0xFF0F507B) : Colors.blueGrey,
        onPrimary: isLight ? Colors.white : Colors.grey[200],
      ),
      // Preserve Akrobat by deriving overrides from akrobatTextTheme
      textTheme: akrobatTextTheme.copyWith(
        bodyMedium: akrobatTextTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.grey[800] : Colors.grey[400],
        ),
        titleMedium: akrobatTextTheme.titleMedium?.copyWith(
          color: isLight ? Colors.grey[800] : Colors.grey[400],
        ),
      ),
      primaryTextTheme: akrobatPrimaryTextTheme,
      // NavigationRail theming (indicator, icon/label colors) using Akrobat
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: const Color(0x143F51B5),
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: const IconThemeData(color: Color(0xFF3F51B5)),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        selectedLabelTextStyle:
            akrobatTextTheme.labelMedium?.copyWith(color: const Color(0xFF3F51B5)),
        unselectedLabelTextStyle:
            akrobatTextTheme.labelMedium?.copyWith(color: Colors.grey),
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.grey[200] : Colors.grey[900],
        shadowColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        // comment: AppBar title uses Akrobat SemiBold and larger size
        titleTextStyle: akrobatPrimaryTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: (akrobatPrimaryTextTheme.titleLarge?.fontSize ?? 20) + 2,
          color: isLight ? Colors.white : Colors.grey[200],
        ),
        toolbarTextStyle: akrobatPrimaryTextTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : Colors.grey[200],
        ),
        iconTheme: IconThemeData(
          color: isLight ? Colors.grey[50] : Colors.grey[400],
        ),
      ),
      dividerTheme: DividerThemeData(
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

  const CustomColors({
    required this.requestLinkColor,
  });

  @override
  CustomColors copyWith({
    Color? requestLinkColor,
  }) {
    return CustomColors(
      requestLinkColor: requestLinkColor ?? this.requestLinkColor,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      requestLinkColor:
          Color.lerp(requestLinkColor, other.requestLinkColor, t)!,
    );
  }

  static const light = CustomColors(
    requestLinkColor: Color(0xFF0055ff),
  );

  static const dark = CustomColors(
    requestLinkColor: Color.fromARGB(255, 60, 94, 195),
  );
}

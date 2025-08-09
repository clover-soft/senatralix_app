import 'package:flutter/material.dart';

// lib/utils/theme.dart
enum AppThemeMode { light, dark }

class AppTheme {
  ThemeData themeData(AppThemeMode mode) {
    final isLight = mode == AppThemeMode.light;

    final baseTheme = ThemeData.from(
      colorScheme: isLight ? ColorScheme.light() : ColorScheme.dark(),
    );

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: isLight ? const Color(0xFF0F507B) : Colors.blueGrey,
        onPrimary: isLight ? Colors.white : Colors.grey[200],
      ),
      textTheme: baseTheme.textTheme.copyWith(
        bodyMedium: TextStyle(
          color: isLight ? Colors.grey[800] : Colors.grey[400],
        ),
        titleMedium: TextStyle(
          color: isLight ? Colors.grey[800] : Colors.grey[400],
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.grey[200] : Colors.grey[900],
        shadowColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? const Color(0xFF0F507B) : Colors.grey[900],
        iconTheme: IconThemeData(
          color: isLight ? Colors.grey[50] : Colors.grey[400],
        ),
        titleTextStyle: TextStyle(
          color: isLight ? Colors.grey[50] : Colors.grey[400],
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        isLight ? CustomColors.light : CustomColors.dark,
      ],
    );
  }

  static Color getTaskDateSwitcherBgColor({
    required DateTime date,
    required BuildContext context,
  }) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    if (date.day == DateTime.now().day) {
      return customColors.dateSwitcherBgTodayColor;
    } else if (date.compareTo(DateTime.now()) < 0) {
      return customColors.dateSwitcherBgPastColor;
    } else {
      return customColors.dateSwitcherBgFutureColor;
    }
  }

  static Color getColoByTaskStatus({
    required int status,
    bool confirmed = false,
  }) {
    switch (status) {
      case 0:
        if (confirmed) {
          return const Color(0xFF006699);
        } else {
          return const Color(0xFFD0D0D0);
        }
      case 1:
      case 2:
      case 6:
        return const Color(0xFF009966);
      case 4:
        return const Color(0xFFD0D0D0);
      case 9:
        return const Color(0xFFBB2020);
      default:
        return const Color(0xFFD0D0D0);
    }
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color taskTitleColor;
  final Color taskAddressColor;
  final Color expansionTileColor;
  final Color requestRowHeaderColor;
  final Color requestRowBgColor;
  final Color requestRowEvenBgColor;
  final Color dateSwitcherBgPastColor;
  final Color dateSwitcherBgTodayColor;
  final Color dateSwitcherBgFutureColor;
  final Color dateSwitcherTextColor;
  final Color requestLinkColor;
  final Color requestTaskNameBgColor;

  const CustomColors({
    required this.taskTitleColor,
    required this.taskAddressColor,
    required this.expansionTileColor,
    required this.requestRowHeaderColor,
    required this.requestRowBgColor,
    required this.requestRowEvenBgColor,
    required this.dateSwitcherBgPastColor,
    required this.dateSwitcherBgTodayColor,
    required this.dateSwitcherBgFutureColor,
    required this.dateSwitcherTextColor,
    required this.requestLinkColor,
    required this.requestTaskNameBgColor,
  });

  @override
  CustomColors copyWith({
    Color? customTextColor,
    Color? taskAddressColor,
    Color? expansionTileColor,
    Color? requestRowHeaderColor,
    Color? requestRowBgColor,
    Color? requestRowEvenBgColor,
    Color? dateSwitcherBgPastColor,
    Color? dateSwitcherBgTodayColor,
    Color? dateSwitcherBgFutureColor,
    Color? dateSwitcherTextColor,
    Color? requestLinkColor,
    Color? requestTaskNameBgColor,
  }) {
    return CustomColors(
      taskTitleColor: customTextColor ?? taskTitleColor,
      taskAddressColor: taskAddressColor ?? this.taskAddressColor,
      expansionTileColor: expansionTileColor ?? this.expansionTileColor,
      requestRowHeaderColor:
          requestRowHeaderColor ?? this.requestRowHeaderColor,
      requestRowBgColor: requestRowBgColor ?? this.requestRowBgColor,
      requestRowEvenBgColor:
          requestRowEvenBgColor ?? this.requestRowEvenBgColor,
      dateSwitcherBgPastColor:
          dateSwitcherBgPastColor ?? this.dateSwitcherBgPastColor,
      dateSwitcherBgTodayColor:
          dateSwitcherBgTodayColor ?? this.dateSwitcherBgTodayColor,
      dateSwitcherBgFutureColor:
          dateSwitcherBgFutureColor ?? this.dateSwitcherBgFutureColor,
      dateSwitcherTextColor:
          dateSwitcherTextColor ?? this.dateSwitcherTextColor,
      requestLinkColor: requestLinkColor ?? this.requestLinkColor,
      requestTaskNameBgColor:
          requestTaskNameBgColor ?? this.requestTaskNameBgColor,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      taskTitleColor: Color.lerp(taskTitleColor, other.taskTitleColor, t)!,
      taskAddressColor: Color.lerp(
        taskAddressColor,
        other.taskAddressColor,
        t,
      )!,
      expansionTileColor: Color.lerp(
        expansionTileColor,
        other.expansionTileColor,
        t,
      )!,
      requestRowHeaderColor: Color.lerp(
        requestRowHeaderColor,
        other.requestRowHeaderColor,
        t,
      )!,
      requestRowBgColor: Color.lerp(
        requestRowBgColor,
        other.requestRowBgColor,
        t,
      )!,
      requestRowEvenBgColor: Color.lerp(
        requestRowEvenBgColor,
        other.requestRowEvenBgColor,
        t,
      )!,
      dateSwitcherBgPastColor: Color.lerp(
        dateSwitcherBgPastColor,
        other.dateSwitcherBgPastColor,
        t,
      )!,
      dateSwitcherBgTodayColor: Color.lerp(
        dateSwitcherBgTodayColor,
        other.dateSwitcherBgTodayColor,
        t,
      )!,
      dateSwitcherBgFutureColor: Color.lerp(
        dateSwitcherBgFutureColor,
        other.dateSwitcherBgFutureColor,
        t,
      )!,
      dateSwitcherTextColor: Color.lerp(
        dateSwitcherTextColor,
        other.dateSwitcherTextColor,
        t,
      )!,
      requestLinkColor: Color.lerp(
        requestLinkColor,
        other.requestLinkColor,
        t,
      )!,
      requestTaskNameBgColor: Color.lerp(
        requestTaskNameBgColor,
        other.requestTaskNameBgColor,
        t,
      )!,
    );
  }

  static const light = CustomColors(
    taskTitleColor: Color(0xFF006699),
    taskAddressColor: Color(0xFF990099),
    expansionTileColor: Color(0xFFe7f1ff),
    requestRowHeaderColor: Color(0xFF009966),
    requestRowBgColor: Color(0xFFFFFFFF),
    requestRowEvenBgColor: Color(0xFFEFEFEF),
    dateSwitcherBgPastColor: Color(0xFFD0D0D0),
    dateSwitcherBgTodayColor: Color(0xFFEDFFF0),
    dateSwitcherBgFutureColor: Color(0xFFFFFFEE),
    dateSwitcherTextColor: Color(0xFF101010),
    requestLinkColor: Color(0xFF0055ff),
    requestTaskNameBgColor: Color(0xFFEDF9FF),
  );

  static const dark = CustomColors(
    taskTitleColor: Color.fromARGB(255, 120, 210, 255),
    taskAddressColor: Color.fromARGB(255, 185, 131, 185),
    expansionTileColor: Color(0xFF202020),
    requestRowHeaderColor: Color(0xFF009966),
    requestRowBgColor: Color(0xFF202020),
    requestRowEvenBgColor: Color(0xFF303030),
    dateSwitcherBgPastColor: Color(0xFF323232),
    dateSwitcherBgTodayColor: Color.fromARGB(255, 32, 51, 35),
    dateSwitcherBgFutureColor: Color.fromARGB(255, 47, 47, 31),
    dateSwitcherTextColor: Color(0xFFD0D0D0),
    requestLinkColor: Color.fromARGB(255, 60, 94, 195),
    requestTaskNameBgColor: Color.fromARGB(255, 38, 53, 60),
  );
}

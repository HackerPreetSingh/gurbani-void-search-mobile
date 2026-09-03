import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light({bool isBold = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF005B4E),
      brightness: Brightness.light,
    );

    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = isBold
        ? baseTextTheme.copyWith(
            displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
            displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
            displaySmall: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
            headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
            headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
            headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            bodySmall: baseTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
          )
        : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }

  static final dark = light(isBold: false);
}

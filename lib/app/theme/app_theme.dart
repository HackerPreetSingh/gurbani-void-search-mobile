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
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
            labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
          )
        : baseTextTheme.copyWith(
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 15),
          );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'MuktaGurmukhi',
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
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontSize: 22,
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
        selectedLabelTextStyle: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: colorScheme.primary),
        unselectedLabelTextStyle: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.grey.shade700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData dark({bool isBold = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00897B),
      brightness: Brightness.dark,
      surface: const Color(0xFF12181B),
      onSurface: Colors.white,
    );

    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = isBold
        ? baseTextTheme.copyWith(
            displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            displaySmall: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          )
        : baseTextTheme.copyWith(
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 15),
          );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'MuktaGurmukhi',
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF12181B),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: const Color(0xFF12181B),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF222C32),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF12181B),
        indicatorColor: colorScheme.secondaryContainer,
        selectedLabelTextStyle: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.tealAccent),
        unselectedLabelTextStyle: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.white70),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A2226),
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

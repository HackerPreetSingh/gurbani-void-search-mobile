import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/core_providers.dart';
import '../features/settings/presentation/display_settings_notifier.dart';
import 'theme/app_theme.dart';

class GurbaniSearchApp extends ConsumerWidget {
  const GurbaniSearchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;
    final themeMode = ref.watch(themeModeSettingsProvider).value ?? ThemeMode.light;

    return MaterialApp.router(
      title: 'Gurbani Sagar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(isBold: isBold),
      darkTheme: AppTheme.dark(isBold: isBold),
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

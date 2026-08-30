import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../settings/domain/models/display_settings.dart';
import '../../../../settings/presentation/display_settings_notifier.dart';
import '../../../shared/presentation/widgets/gurbani_settings_control.dart';

class ShabadSettingsDialog extends ConsumerWidget {
  final DisplaySettings initialSettings;

  const ShabadSettingsDialog({super.key, required this.initialSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSettings = ref.watch(shabadSettingsProvider).value ?? initialSettings;
    final notifier = ref.read(shabadSettingsProvider.notifier);

    return AlertDialog(
      title: const Text('Display Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GurbaniSettingsControl(
              label: 'Gurmukhi',
              isVisible: true,
              size: currentSettings.fontSizeGurmukhi,
              isSizeOnly: true,
              onToggle: (_) {},
              onSizeChanged: (val) => notifier.updateFontSizeGurmukhi(val),
            ),
            const Divider(),
            GurbaniSettingsControl(
              label: 'Hindi',
              isVisible: currentSettings.showHindi,
              size: currentSettings.fontSizeHindi,
              onToggle: (_) => notifier.toggleHindi(),
              onSizeChanged: (val) => notifier.updateFontSizeHindi(val),
            ),
            GurbaniSettingsControl(
              label: 'English',
              isVisible: currentSettings.showTransliteration,
              size: currentSettings.fontSizeEnglish,
              onToggle: (_) => notifier.toggleTransliteration(),
              onSizeChanged: (val) => notifier.updateFontSizeEnglish(val),
            ),
            GurbaniSettingsControl(
              label: 'English Meaning',
              isVisible: currentSettings.showEnglishMeaning,
              size: currentSettings.fontSizeMeaning,
              onToggle: (_) => notifier.toggleEnglishMeaning(),
              onSizeChanged: (val) => notifier.updateFontSizeMeaning(val),
            ),
            GurbaniSettingsControl(
              label: 'Punjabi Meaning',
              isVisible: currentSettings.showPunjabiMeaning,
              size: currentSettings.fontSizePunjabiMeaning,
              onToggle: (_) => notifier.togglePunjabiMeaning(),
              onSizeChanged: (val) => notifier.updateFontSizePunjabiMeaning(val),
            ),
            GurbaniSettingsControl(
              label: 'Pauses',
              isVisible: currentSettings.showVishrams,
              size: 0,
              isVisibilityOnly: true,
              onToggle: (_) => notifier.toggleVishrams(),
              onSizeChanged: (_) {},
            ),
            GurbaniSettingsControl(
              label: 'Larivaar',
              isVisible: currentSettings.showLarivaar,
              size: 0,
              isVisibilityOnly: true,
              onToggle: (_) => notifier.toggleLarivaar(),
              onSizeChanged: (_) {},
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

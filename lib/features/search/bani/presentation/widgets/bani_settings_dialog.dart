import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../settings/domain/models/display_settings.dart';
import '../../../../settings/presentation/display_settings_notifier.dart';
import '../../../shared/presentation/widgets/gurbani_settings_control.dart';

class BaniSettingsDialog extends ConsumerWidget {
  final DisplaySettings initialSettings;
  final int? baniId;

  const BaniSettingsDialog({
    super.key,
    required this.initialSettings,
    this.baniId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSettings = ref.watch(baniSettingsProvider).value ?? initialSettings;
    final notifier = ref.read(baniSettingsProvider.notifier);

    return AlertDialog(
      title: const Text('Display Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bani Maryada Version',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BaniMaryada>(
                  value: currentSettings.maryada,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: BaniMaryada.sgpc,
                      child: Text('SGPC / Darbar Sahib (Default)'),
                    ),
                    DropdownMenuItem(
                      value: BaniMaryada.taksal,
                      child: Text('Damdami Taksal'),
                    ),
                    DropdownMenuItem(
                      value: BaniMaryada.budhaDal,
                      child: Text('Shiromani Panth Akali Budha Dal'),
                    ),
                    DropdownMenuItem(
                      value: BaniMaryada.medium,
                      child: Text('Medium / Standard'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateMaryada(val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
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
            if (baniId == 4) ...[
              const Divider(),
              GurbaniSettingsControl(
                label: 'Paragraph View',
                isVisible: currentSettings.showJaapSahibParagraphView,
                size: 0,
                isVisibilityOnly: true,
                onToggle: (_) => notifier.toggleJaapSahibParagraphView(),
                onSizeChanged: (_) {},
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

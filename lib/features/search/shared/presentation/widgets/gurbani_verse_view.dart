import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/gurbani_search_result.dart';
import '../../../../settings/domain/models/display_settings.dart';
import '../../../domain/providers/search_providers.dart';

import '../../../../settings/presentation/display_settings_notifier.dart';

class GurbaniVerseView extends ConsumerWidget {
  final GurbaniSearchResult verse;
  final DisplaySettings settings;
  final bool isHighlighted;
  final Color? gurmukhiColor;

  const GurbaniVerseView({
    super.key,
    required this.verse,
    required this.settings,
    this.isHighlighted = false,
    this.gurmukhiColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;
    final bool hasHindi = verse.transliterationHi != null && verse.transliterationHi!.trim().isNotEmpty && !verse.transliterationHi!.toLowerCase().contains('null');
    final bool hasTranslit = verse.transliteration != null && verse.transliteration!.trim().isNotEmpty && !verse.transliteration!.toLowerCase().contains('null');
    final bool hasEnglishMeaning = verse.translation != null && verse.translation!.trim().isNotEmpty && !verse.translation!.toLowerCase().contains('null');
    final bool hasPunjabiMeaning = verse.translationPa != null && verse.translationPa!.trim().isNotEmpty && !verse.translationPa!.toLowerCase().contains('null');

    return Container(
      width: double.infinity,
      color: isHighlighted ? Colors.teal.withAlpha(25) : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildGurmukhiText(ref, verse.gurmukhi, verse.visraams, settings, isBold),
          if (settings.showHindi && hasHindi) ...[
            const SizedBox(height: 4),
            Text(verse.transliterationHi!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: settings.fontSizeHindi,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: gurmukhiColor ?? Colors.red.shade900,
                )),
          ],
          if (settings.showTransliteration && hasTranslit) ...[
            const SizedBox(height: 4),
            Text(verse.transliteration!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: settings.fontSizeEnglish,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: gurmukhiColor?.withAlpha(180) ?? Colors.blueGrey,
                )),
          ],
          if (settings.showEnglishMeaning && hasEnglishMeaning) ...[
            const SizedBox(height: 4),
            Text(verse.translation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: settings.fontSizeMeaning,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                )),
          ],
          if (settings.showPunjabiMeaning && hasPunjabiMeaning) ...[
            const SizedBox(height: 4),
            Text(verse.translationPa!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: settings.fontSizePunjabiMeaning,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: gurmukhiColor ?? Colors.teal.shade900,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildGurmukhiText(WidgetRef ref, String gurmukhi, String? visraamsJson, DisplaySettings settings, bool isBold) {
    final baseStyle = TextStyle(
      fontSize: settings.fontSizeGurmukhi,
      fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
      height: 1.4,
      color: gurmukhiColor ?? Colors.black,
    );

    final vishramService = ref.read(vishramServiceProvider);
    final span = vishramService.buildGurmukhiText(
      gurmukhi, 
      visraamsJson, 
      baseStyle, 
      settings.showVishrams,
      settings.showLarivaar,
    );

    return Text.rich(
      span as TextSpan,
      textAlign: TextAlign.center,
    );
  }
}

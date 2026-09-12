import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/bani.dart';
import '../../../../settings/domain/models/display_settings.dart';
import '../../../domain/providers/search_providers.dart';

class BaniParagraphView extends ConsumerWidget {
  final List<BaniVerse> verses;
  final DisplaySettings settings;
  final String? highlightVerseId;
  final Map<String, GlobalKey> verseKeys;

  const BaniParagraphView({
    super.key,
    required this.verses,
    required this.settings,
    this.highlightVerseId,
    required this.verseKeys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = TextStyle(
      fontSize: settings.fontSizeGurmukhi,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: isDark ? Colors.white : Colors.black,
    );

    final vishramService = ref.read(vishramServiceProvider);
    final List<InlineSpan> paragraphSpans = [];

    for (int i = 0; i < verses.length; i++) {
      final bv = verses[i];
      final verse = bv.verse;
      final bool isHighlighted = highlightVerseId != null && verse.stableId == highlightVerseId;

      final verseSpan = vishramService.buildGurmukhiText(
        verse.gurmukhi,
        verse.visraams,
        isHighlighted
            ? baseStyle.copyWith(backgroundColor: Colors.teal.withAlpha(50))
            : baseStyle,
        settings.showVishrams,
        settings.showLarivaar,
      );

      paragraphSpans.add(verseSpan);

      // Add inter-verse spacing for continuous paragraph flow
      if (i < verses.length - 1) {
        paragraphSpans.add(TextSpan(
          text: '   ',
          style: baseStyle,
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
      child: Text.rich(
        TextSpan(children: paragraphSpans),
        textAlign: TextAlign.center,
      ),
    );
  }
}

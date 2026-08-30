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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: verses.map((bv) {
          final verse = bv.verse;
          final bool isHighlighted = highlightVerseId != null && verse.stableId == highlightVerseId;
          final key = verseKeys.putIfAbsent(verse.stableId, () => GlobalKey());
          
          return Container(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.teal.withAlpha(25) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildGurmukhiText(ref, verse.gurmukhi, verse.visraams, settings),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGurmukhiText(WidgetRef ref, String gurmukhi, String? visraamsJson, DisplaySettings settings) {
    final baseStyle = TextStyle(
      fontSize: settings.fontSizeGurmukhi,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: Colors.black,
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

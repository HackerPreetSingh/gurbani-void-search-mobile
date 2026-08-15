import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/providers/search_providers.dart';
import '../domain/providers/shabad_providers.dart';
import '../../settings/domain/models/display_settings.dart';
import '../../settings/presentation/display_settings_notifier.dart';

class ShabadPage extends ConsumerStatefulWidget {
  final String shabadId;
  final String? highlightVerseId;

  const ShabadPage({super.key, required this.shabadId, this.highlightVerseId});

  @override
  ConsumerState<ShabadPage> createState() => _ShabadPageState();
}

class _ShabadPageState extends ConsumerState<ShabadPage> {
  @override
  Widget build(BuildContext context) {
    // [AI_GUARD:PERMANENT_LOG] Tracking shabad page build. Do not remove or modify.
    print('${AppConstants.logTag} [${DateTime.now()}] [shabad_page.dart] WIDGET_BUILD: id=${widget.shabadId}');
    
    final shabadAsync = ref.watch(shabadDetailsProvider(widget.shabadId));
    final settingsAsync = ref.watch(displaySettingsProvider);
    final settings = settingsAsync.value ?? DisplaySettings.defaults();

    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: shabadAsync.when(
          data: (verses) {
            if (verses.isEmpty) {
              // [AI_GUARD:PERMANENT_LOG] No data found for this ID
              print('${AppConstants.logTag} [${DateTime.now()}] [shabad_page.dart] DATA_EMPTY: No verses found for shabad ${widget.shabadId}');
              return Scaffold(
                appBar: AppBar(title: const Text('Shabad View')),
                body: const Center(child: Text('Shabad not found.')),
              );
            }

            final firstVerse = verses.first;
            // [AI_GUARD:PERMANENT_LOG] Checking header metadata presence
            final bool hasRaag = firstVerse.raagName != null &&
                firstVerse.raagName!.trim().isNotEmpty &&
                !firstVerse.raagName!.toLowerCase().contains('unknown') &&
                !firstVerse.raagName!.toLowerCase().contains('null');
            final bool hasWriter = firstVerse.writerName != null &&
                firstVerse.writerName!.trim().isNotEmpty &&
                !firstVerse.writerName!.toLowerCase().contains('unknown') &&
                !firstVerse.writerName!.toLowerCase().contains('null');
            final bool hasSource = firstVerse.sourceName.trim().isNotEmpty &&
                !firstVerse.sourceName.toLowerCase().contains('unknown') &&
                !firstVerse.sourceName.toLowerCase().contains('null');

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('Shabad View'),
                  floating: true, // App bar shows up as soon as user scrolls down
                  snap: true,     // App bar snaps into view
                  pinned: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _showSettingsDialog(context, settings),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    color: Colors.teal.withAlpha(15),
                    child: Column(
                      children: [
                        if (hasRaag)
                          Text(firstVerse.raagName!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                        if (hasWriter)
                          Text(firstVerse.writerName!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                        if (hasSource) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${firstVerse.sourceName}${firstVerse.ang != null ? " • Ang ${firstVerse.ang}" : ""}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final verse = verses[index];
                        // [AI_GUARD:PERMANENT_LOG] Robust null/empty check for each verse line
                        final bool hasHindi = verse.transliterationHi != null && verse.transliterationHi!.trim().isNotEmpty && !verse.transliterationHi!.toLowerCase().contains('null');
                        final bool hasTranslit = verse.transliteration != null && verse.transliteration!.trim().isNotEmpty && !verse.transliteration!.toLowerCase().contains('null');
                        final bool hasEnglishMeaning = verse.translation != null && verse.translation!.trim().isNotEmpty && !verse.translation!.toLowerCase().contains('null');
                        final bool hasPunjabiMeaning = verse.translationPa != null && verse.translationPa!.trim().isNotEmpty && !verse.translationPa!.toLowerCase().contains('null');

                        final bool isHighlighted = widget.highlightVerseId != null && verse.stableId == widget.highlightVerseId;

                        return Container(
                          width: double.infinity,
                          color: isHighlighted ? Colors.teal.withAlpha(25) : null,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildGurmukhiText(verse.gurmukhi, verse.visraams, settings),
                              if (settings.showHindi && hasHindi) ...[
                                const SizedBox(height: 12),
                                Text(verse.transliterationHi!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeHindi, color: Colors.red.shade900)),
                              ],
                              if (settings.showTransliteration && hasTranslit) ...[
                                const SizedBox(height: 12),
                                Text(verse.transliteration!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeEnglish, color: Colors.blueGrey)),
                              ],
                              if (settings.showEnglishMeaning && hasEnglishMeaning) ...[
                                const SizedBox(height: 12),
                                Text(verse.translation!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeMeaning, fontStyle: FontStyle.italic, color: Colors.black87)),
                              ],
                              if (settings.showPunjabiMeaning && hasPunjabiMeaning) ...[
                                const SizedBox(height: 12),
                                Text(verse.translationPa!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizePunjabiMeaning, color: Colors.teal.shade900)),
                              ],
                            ],
                          ),
                        );
                      },
                      childCount: verses.length,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            // [AI_GUARD:PERMANENT_LOG] Error in shabad data loading
            print('${AppConstants.logTag} [${DateTime.now()}] [shabad_page.dart] ERROR: $err\nSTACK: $stack');
            return Center(child: Text('Error: $err'));
          },
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, DisplaySettings settings) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSettings = ref.watch(displaySettingsProvider).value ?? settings;
            final notifier = ref.read(displaySettingsProvider.notifier);

            return AlertDialog(
              title: const Text('Display Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnifiedControl(
                      label: 'Gurmukhi',
                      isVisible: true,
                      size: currentSettings.fontSizeGurmukhi,
                      isSizeOnly: true,
                      onToggle: (_) {},
                      onSizeChanged: (val) => notifier.updateFontSizeGurmukhi(val),
                    ),
                    const Divider(),
                    _buildUnifiedControl(
                      label: 'Hindi',
                      isVisible: currentSettings.showHindi,
                      size: currentSettings.fontSizeHindi,
                      onToggle: (_) => notifier.toggleHindi(),
                      onSizeChanged: (val) => notifier.updateFontSizeHindi(val),
                    ),
                    _buildUnifiedControl(
                      label: 'English',
                      isVisible: currentSettings.showTransliteration,
                      size: currentSettings.fontSizeEnglish,
                      onToggle: (_) => notifier.toggleTransliteration(),
                      onSizeChanged: (val) => notifier.updateFontSizeEnglish(val),
                    ),
                    _buildUnifiedControl(
                      label: 'English Meaning',
                      isVisible: currentSettings.showEnglishMeaning,
                      size: currentSettings.fontSizeMeaning,
                      onToggle: (_) => notifier.toggleEnglishMeaning(),
                      onSizeChanged: (val) => notifier.updateFontSizeMeaning(val),
                    ),
                    _buildUnifiedControl(
                      label: 'Punjabi Meaning',
                      isVisible: currentSettings.showPunjabiMeaning,
                      size: currentSettings.fontSizePunjabiMeaning,
                      onToggle: (_) => notifier.togglePunjabiMeaning(),
                      onSizeChanged: (val) => notifier.updateFontSizePunjabiMeaning(val),
                    ),
                    _buildUnifiedControl(
                      label: 'Pauses',
                      isVisible: currentSettings.showVishrams,
                      size: 0,
                      isVisibilityOnly: true,
                      onToggle: (_) => notifier.toggleVishrams(),
                      onSizeChanged: (_) {},
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUnifiedControl({
    required String label,
    required bool isVisible,
    required double size,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onSizeChanged,
    bool isSizeOnly = false,
    bool isVisibilityOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          if (!isVisibilityOnly)
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => onSizeChanged(size - 2),
                ),
                Text(size.toInt().toString(), style: const TextStyle(fontSize: 12)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onSizeChanged(size + 2),
                ),
              ],
            ),
          if (!isSizeOnly)
            Switch.adaptive(
              value: isVisible,
              onChanged: onToggle,
              activeTrackColor: Colors.teal,
            ),
        ],
      ),
    );
  }

  Widget _buildGurmukhiText(String gurmukhi, String? visraamsJson, DisplaySettings settings) {
    final baseStyle = TextStyle(
      fontSize: settings.fontSizeGurmukhi,
      fontWeight: FontWeight.w500,
      height: 1.6,
      color: Colors.black,
    );

    final vishramService = ref.read(vishramServiceProvider);
    final span = vishramService.buildGurmukhiText(gurmukhi, visraamsJson, baseStyle, settings.showVishrams);

    return Text.rich(
      span as TextSpan,
      textAlign: TextAlign.center,
    );
  }
}

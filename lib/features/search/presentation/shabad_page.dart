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
  final Map<String, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.highlightVerseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // [AI_GUARD:PERMANENT_LOG] Delaying scroll to allow opening shabad on top first
        Future.delayed(const Duration(milliseconds: 600), () {
          _scrollToHighlightedVerse();
        });
      });
    }
  }

  void _scrollToHighlightedVerse() {
    if (!mounted || widget.highlightVerseId == null) return;
    
    final key = _verseKeys[widget.highlightVerseId];
    if (key != null && key.currentContext != null) {
      // [AI_GUARD:PERMANENT_LOG] Executing smooth scroll to highlighted tukk
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        alignment: 0.5, // Center the tukk in the screen
      );
    } else {
      // [AI_GUARD:PERMANENT_LOG] Widget not yet built (lazy loading). Retrying once.
      print('${AppConstants.logTag} [shabad_page.dart] INFO: Highlight widget not found in tree, retrying scroll...');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToHighlightedVerse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // [AI_GUARD:PERMANENT_LOG] Tracking shabad page build. Do not remove or modify.
    print('${AppConstants.logTag} [${DateTime.now()}] [shabad_page.dart] WIDGET_BUILD: id=${widget.shabadId}');
    
    final shabadAsync = ref.watch(shabadDetailsProvider(widget.shabadId));
    final settingsAsync = ref.watch(shabadSettingsProvider);
    final settings = settingsAsync.value ?? DisplaySettings.defaults();

    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: shabadAsync.when(
            data: (verses) {
              if (verses.isEmpty) {
                // [AI_GUARD:PERMANENT_LOG] No data found for this ID
                print('${AppConstants.logTag} [${DateTime.now()}] [shabad_page.dart] DATA_EMPTY: No verses found for shabad ${widget.shabadId}');
                return Scaffold(
                  key: const ValueKey('empty'),
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
                key: const ValueKey('data'),
                cacheExtent: 2000, 
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
                          
                          // [AI_GUARD:PERMANENT_LOG] Assigning global key for auto-scrolling
                          final key = _verseKeys.putIfAbsent(verse.stableId, () => GlobalKey());

                            return Container(
                            key: key,
                            width: double.infinity,
                            color: isHighlighted ? Colors.teal.withAlpha(25) : null,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildGurmukhiText(verse.gurmukhi, verse.visraams, settings),
                              if (settings.showHindi && hasHindi) ...[
                                // [AI_GUARD:PERMANENT_LOG] Displaying Hindi transliteration
                                const SizedBox(height: 4),
                                Text(verse.transliterationHi!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeHindi, color: Colors.red.shade900)),
                              ],
                              if (settings.showTransliteration && hasTranslit) ...[
                                // [AI_GUARD:PERMANENT_LOG] Displaying English transliteration
                                const SizedBox(height: 4),
                                Text(verse.transliteration!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeEnglish, color: Colors.blueGrey)),
                              ],
                              if (settings.showEnglishMeaning && hasEnglishMeaning) ...[
                                // [AI_GUARD:PERMANENT_LOG] Displaying English meaning
                                const SizedBox(height: 4),
                                Text(verse.translation!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeMeaning, fontStyle: FontStyle.italic, color: Colors.black87)),
                              ],
                              if (settings.showPunjabiMeaning && hasPunjabiMeaning) ...[
                                // [AI_GUARD:PERMANENT_LOG] Displaying Punjabi meaning
                                const SizedBox(height: 4),
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
            loading: () => const Center(
              key: ValueKey('loading'),
              child: Hero(
                tag: 'shabad_loader',
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) {
              // [AI_GUARD:PERMANENT_LOG] Error in shabad data loading
              print('${AppConstants.logTag} [${DateTime.now()}] [shabad_page.dart] ERROR: $err\nSTACK: $stack');
              return Center(key: const ValueKey('error'), child: Text('Error: $err'));
            },
          ),
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
            final currentSettings = ref.watch(shabadSettingsProvider).value ?? settings;
            final notifier = ref.read(shabadSettingsProvider.notifier);

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
                    _buildUnifiedControl(
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

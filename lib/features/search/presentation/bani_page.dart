import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/providers/bani_providers.dart';
import '../../settings/domain/models/display_settings.dart';
import '../../settings/presentation/display_settings_notifier.dart';
import '../domain/providers/search_providers.dart';

class BaniPage extends ConsumerStatefulWidget {
  final int baniId;
  final String? highlightVerseId;

  const BaniPage({super.key, required this.baniId, this.highlightVerseId});

  @override
  ConsumerState<BaniPage> createState() => _BaniPageState();
}

class _BaniPageState extends ConsumerState<BaniPage> {
  final Map<String, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.highlightVerseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // [AI_GUARD:PERMANENT_LOG] Delaying scroll to allow opening bani on top first
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
      // [AI_GUARD:PERMANENT_LOG] Widget not yet built (lazy loading). Retrying.
      // Banis can be very long, so we use a higher cacheExtent and a retry.
      print('${AppConstants.logTag} [bani_page.dart] INFO: Highlight widget not found in tree, retrying scroll...');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToHighlightedVerse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // [AI_GUARD:PERMANENT_LOG] Tracking bani page build. Do not remove or modify.
    print('${AppConstants.logTag} [${DateTime.now()}] [bani_page.dart] WIDGET_BUILD: id=${widget.baniId}, highlight=${widget.highlightVerseId}');
    
    final baniDetailsAsync = ref.watch(baniDetailsProvider(widget.baniId));
    final settingsAsync = ref.watch(baniSettingsProvider);
    final settings = settingsAsync.value ?? DisplaySettings.defaults();

    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: baniDetailsAsync.when(
            data: (verses) {
              if (verses.isEmpty) {
                // [AI_GUARD:PERMANENT_LOG] No data found for this ID
                print('${AppConstants.logTag} [${DateTime.now()}] [bani_page.dart] DATA_EMPTY: No verses found for bani ${widget.baniId}');
                return Scaffold(
                  key: const ValueKey('empty'),
                  appBar: AppBar(title: const Text('Bani View')),
                  body: const Center(child: Text('Bani content not found.')),
                );
              }

              final firstVerse = verses.first.verse;
              final bool isJaapSahib = widget.baniId == 4;

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
                    title: Text(firstVerse.gurmukhi.length > 20 ? 'Bani View' : firstVerse.gurmukhi),
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
                  if (isJaapSahib)
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, pIndex) {
                            final List<int> pIds = verses.map((v) => v.paragraph ?? 0).toSet().toList()..sort();
                            final pId = pIds[pIndex];
                            final pVerses = verses.where((v) => (v.paragraph ?? 0) == pId).toList();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: pVerses.map((bv) {
                                  final verse = bv.verse;
                                  final bool isHighlighted = widget.highlightVerseId != null && verse.stableId == widget.highlightVerseId;
                                  final key = _verseKeys.putIfAbsent(verse.stableId, () => GlobalKey());
                                  
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
                          },
                          childCount: verses.map((v) => v.paragraph ?? 0).toSet().length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final baniVerse = verses[index];
                            final verse = baniVerse.verse;
                            
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
                                  _buildGurmukhiText(ref, verse.gurmukhi, verse.visraams, settings),
                                  if (settings.showHindi && hasHindi) ...[
                                    const SizedBox(height: 4),
                                    Text(verse.transliterationHi!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: settings.fontSizeHindi, color: Colors.red.shade900)),
                                  ],
                                  if (settings.showTransliteration && hasTranslit) ...[
                                    const SizedBox(height: 4),
                                    Text(verse.transliteration!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: settings.fontSizeEnglish, color: Colors.blueGrey)),
                                  ],
                                  if (settings.showEnglishMeaning && hasEnglishMeaning) ...[
                                    const SizedBox(height: 4),
                                    Text(verse.translation!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: settings.fontSizeMeaning, fontStyle: FontStyle.italic, color: Colors.black87)),
                                  ],
                                  if (settings.showPunjabiMeaning && hasPunjabiMeaning) ...[
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
                tag: 'bani_loader',
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) {
              // [AI_GUARD:PERMANENT_LOG] Error in bani data loading
              print('${AppConstants.logTag} [${DateTime.now()}] [bani_page.dart] ERROR: $err\nSTACK: $stack');
              return Center(key: const ValueKey('error'), child: Text('Error: $err'));
            },
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, DisplaySettings settings) {
    // [AI_GUARD:PERMANENT_LOG] Dialog open
    print('${AppConstants.logTag} [${DateTime.now()}] [bani_page.dart] UI_ACTION: Open settings dialog');
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSettings = ref.watch(baniSettingsProvider).value ?? settings;
            final notifier = ref.read(baniSettingsProvider.notifier);

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

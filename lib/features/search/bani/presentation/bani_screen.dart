import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bani.dart';
import '../../domain/providers/bani_providers.dart';
import '../../../settings/domain/models/display_settings.dart';
import '../../../settings/presentation/display_settings_notifier.dart';
import '../../shared/presentation/widgets/gurbani_header.dart';
import '../../shared/presentation/widgets/gurbani_verse_view.dart';
import '../../shared/presentation/widgets/pinch_to_zoom_wrapper.dart';
import 'widgets/bani_settings_dialog.dart';
import 'widgets/bani_paragraph_view.dart';

class BaniScreen extends ConsumerStatefulWidget {
  final int baniId;
  final String? highlightVerseId;

  const BaniScreen({super.key, required this.baniId, this.highlightVerseId});

  @override
  ConsumerState<BaniScreen> createState() => _BaniScreenState();
}

class _BaniScreenState extends ConsumerState<BaniScreen> {
  final Map<String, GlobalKey> _verseKeys = {};
  
  // Pagination for Sukhmani Sahib
  int _currentSectionIndex = 0;
  List<List<BaniVerse>> _sections = [];

  @override
  void initState() {
    super.initState();
  }

  void _prepareSections(List<BaniVerse> allVerses) {
    if (widget.baniId != 31 || _sections.isNotEmpty) return;

    List<BaniVerse> currentGroup = [];
    for (var v in allVerses) {
      if (v.header > 0 && v.verse.gurmukhi.contains('ਸਲੋਕੁ') && currentGroup.length > 5) {
        _sections.add(List.from(currentGroup));
        currentGroup.clear();
      }
      currentGroup.add(v);
    }
    if (currentGroup.isNotEmpty) {
      _sections.add(currentGroup);
    }

    // If highlight is requested, find which section it's in
    if (widget.highlightVerseId != null) {
      for (int i = 0; i < _sections.length; i++) {
        if (_sections[i].any((v) => v.verse.stableId == widget.highlightVerseId)) {
          _currentSectionIndex = i;
          break;
        }
      }
      _scrollToHighlightedVerse();
    }
  }

  void _scrollToHighlightedVerse() {
    if (!mounted || widget.highlightVerseId == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final key = _verseKeys[widget.highlightVerseId];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.1,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final baniDetailsAsync = ref.watch(baniDetailsProvider(widget.baniId));
    final settingsAsync = ref.watch(baniSettingsProvider);
    final settings = settingsAsync.value ?? DisplaySettings.defaults();

    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PinchToZoomWrapper(
          currentSize: settings.fontSizeGurmukhi,
          onSizeChanged: (newSize) => ref.read(baniSettingsProvider.notifier).updateFontSizeGurmukhi(newSize),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: baniDetailsAsync.when(
              data: (allVerses) {
                if (allVerses.isEmpty) {
                  return Scaffold(
                    key: const ValueKey('empty'),
                    appBar: AppBar(title: const Text('Bani View')),
                    body: const Center(child: Text('Bani content not found.')),
                  );
                }

                final bool isSukhmaniSahib = widget.baniId == 31;
                if (isSukhmaniSahib) {
                  _prepareSections(allVerses);
                }

                final verses = isSukhmaniSahib ? _sections[_currentSectionIndex] : allVerses;
                final firstVerse = allVerses.first.verse;
                final bool isJaapSahib = widget.baniId == 4;

                // Pre-calculate Salok Body colors for Sukhmani Sahib
                final List<Color?> verseColors = List.filled(verses.length, null);
                if (isSukhmaniSahib) {
                  bool inSalokBody = false;
                  for (int i = 0; i < verses.length; i++) {
                    final bv = verses[i];
                    if (bv.header > 0) {
                      if (bv.verse.gurmukhi.contains('ਸਲੋਕੁ')) {
                        inSalokBody = true;
                      } else if (bv.verse.gurmukhi.contains('ਅਸਟਪਦੀ')) {
                        inSalokBody = false;
                      }
                    }
                    if (inSalokBody) {
                      verseColors[i] = const Color(0xFF0D47A1); // Dark Blue
                    }
                  }
                }

                return Stack(
                  children: [
                    CustomScrollView(
                      key: ValueKey('data_${widget.baniId}_$_currentSectionIndex'),
                      // [AI_GUARD:PERMANENT_LOG] Each section section renders independently for better performance
                      cacheExtent: 2000, 
                      slivers: [
                        SliverAppBar(
                          title: Text(isSukhmaniSahib 
                            ? 'Ashtapadi ${_currentSectionIndex + 1}' 
                            : (firstVerse.gurmukhi.length > 20 ? 'Bani View' : firstVerse.gurmukhi)),
                          floating: true, 
                          snap: true,
                          pinned: false,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => _showSettingsDialog(context, settings),
                            ),
                          ],
                        ),
                        // Only show header on page 1 of Sukhmani or for other Banis
                        if (_currentSectionIndex == 0 || !isSukhmaniSahib)
                          SliverToBoxAdapter(
                            child: GurbaniHeader(firstVerse: firstVerse),
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

                                  return BaniParagraphView(
                                    verses: pVerses,
                                    settings: settings,
                                    highlightVerseId: widget.highlightVerseId,
                                    verseKeys: _verseKeys,
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
                                  final isHighlighted = widget.highlightVerseId != null && verse.stableId == widget.highlightVerseId;
                                  final key = _verseKeys.putIfAbsent(verse.stableId, () => GlobalKey());

                                  return GurbaniVerseView(
                                    key: key,
                                    verse: verse,
                                    settings: settings,
                                    isHighlighted: isHighlighted,
                                    gurmukhiColor: verseColors[index],
                                  );
                                },
                                childCount: verses.length,
                              ),
                            ),
                          ),
                        // Extra space at bottom for floating buttons
                        if (isSukhmaniSahib)
                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                    if (isSukhmaniSahib)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentSectionIndex > 0)
                              FloatingActionButton.small(
                                heroTag: 'prev_btn',
                                onPressed: () {
                                  setState(() => _currentSectionIndex--);
                                  _verseKeys.clear(); // Reset keys for new section
                                },
                                backgroundColor: Colors.teal.withAlpha(200),
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.arrow_back_ios_new),
                              )
                            else
                              const SizedBox.shrink(),
                            if (_currentSectionIndex < _sections.length - 1)
                              FloatingActionButton.small(
                                heroTag: 'next_btn',
                                onPressed: () {
                                  setState(() => _currentSectionIndex++);
                                  _verseKeys.clear(); // Reset keys for new section
                                },
                                backgroundColor: Colors.teal.withAlpha(200),
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.arrow_forward_ios),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                key: ValueKey('loading'),
                child: Hero(tag: 'bani_loader', child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Center(key: const ValueKey('error'), child: Text('Error: $err')),
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, DisplaySettings settings) {
    showDialog(
      context: context,
      builder: (context) => BaniSettingsDialog(initialSettings: settings),
    );
  }
}

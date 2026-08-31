import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../domain/providers/shabad_providers.dart';
import '../../../settings/domain/models/display_settings.dart';
import '../../../settings/presentation/display_settings_notifier.dart';
import '../../shared/presentation/widgets/gurbani_header.dart';
import '../../shared/presentation/widgets/gurbani_verse_view.dart';
import '../../shared/presentation/widgets/pinch_to_zoom_wrapper.dart';
import '../../../../features/prakaran/presentation/widgets/add_to_prakaran_dialog.dart';
import 'widgets/shabad_settings_dialog.dart';

class ShabadScreen extends ConsumerStatefulWidget {
  final String shabadId;
  final String? highlightVerseId;

  const ShabadScreen({super.key, required this.shabadId, this.highlightVerseId});

  @override
  ConsumerState<ShabadScreen> createState() => _ShabadScreenState();
}

class _ShabadScreenState extends ConsumerState<ShabadScreen> {
  final Map<String, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    if (widget.highlightVerseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _scrollToHighlightedVerse();
        });
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _scrollToHighlightedVerse() {
    if (!mounted || widget.highlightVerseId == null) return;
    
    final key = _verseKeys[widget.highlightVerseId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToHighlightedVerse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shabadAsync = ref.watch(shabadDetailsProvider(widget.shabadId));
    final settingsAsync = ref.watch(shabadSettingsProvider);
    final settings = settingsAsync.value ?? DisplaySettings.defaults();

    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PinchToZoomWrapper(
          currentSize: settings.fontSizeGurmukhi,
          onSizeChanged: (newSize) => ref.read(shabadSettingsProvider.notifier).updateFontSizeGurmukhi(newSize),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: shabadAsync.when(
              data: (verses) {
                if (verses.isEmpty) {
                  return Scaffold(
                    key: const ValueKey('empty'),
                    appBar: AppBar(title: const Text('Shabad View')),
                    body: const Center(child: Text('Shabad not found.')),
                  );
                }

                return CustomScrollView(
                  key: const ValueKey('data'),
                  cacheExtent: 5000, 
                  slivers: [
                    SliverAppBar(
                      title: const Text('Shabad View'),
                      floating: true, 
                      snap: true,
                      pinned: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.create_new_folder_outlined),
                          onPressed: () => _showAddToPrakaranDialog(context, verses.first.gurmukhi),
                          tooltip: 'Add to Prakaran',
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => _showSettingsDialog(context, settings),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: GurbaniHeader(firstVerse: verses.first),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final verse = verses[index];
                            final isHighlighted = widget.highlightVerseId != null && verse.stableId == widget.highlightVerseId;
                            final key = _verseKeys.putIfAbsent(verse.stableId, () => GlobalKey());

                            return GurbaniVerseView(
                              key: key,
                              verse: verse,
                              settings: settings,
                              isHighlighted: isHighlighted,
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
      builder: (context) => ShabadSettingsDialog(initialSettings: settings),
    );
  }

  void _showAddToPrakaranDialog(BuildContext context, String firstVerseGurmukhi) {
    showDialog(
      context: context,
      builder: (context) => AddToPrakaranDialog(
        shabadId: widget.shabadId,
        titleGurmukhi: firstVerseGurmukhi,
      ),
    );
  }
}

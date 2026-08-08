import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/search_providers.dart';
import '../domain/providers/shabad_providers.dart';
import '../../settings/domain/models/display_settings.dart';
import '../../settings/presentation/display_settings_notifier.dart';

class ShabadPage extends ConsumerStatefulWidget {
  final String shabadId;

  const ShabadPage({super.key, required this.shabadId});

  @override
  ConsumerState<ShabadPage> createState() => _ShabadPageState();
}

class _ShabadPageState extends ConsumerState<ShabadPage> {
  @override
  Widget build(BuildContext context) {
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
              return Scaffold(
                appBar: AppBar(title: const Text('Shabad View')),
                body: const Center(child: Text('Shabad not found.')),
              );
            }

            final firstVerse = verses.first;
            final bool hasRaag = firstVerse.raagName != null &&
                firstVerse.raagName!.isNotEmpty &&
                !firstVerse.raagName!.toLowerCase().contains('unknown');
            final bool hasWriter = firstVerse.writerName != null &&
                firstVerse.writerName!.isNotEmpty &&
                !firstVerse.writerName!.toLowerCase().contains('unknown');

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('Shabad View'),
                  floating: false,
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
                        const SizedBox(height: 4),
                        Text('${firstVerse.sourceName} • Ang ${firstVerse.ang ?? "-"}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final verse = verses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 48.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildGurmukhiText(verse.gurmukhi, verse.visraams, settings),
                              if (settings.showHindi && verse.transliterationHi != null && verse.transliterationHi!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(verse.transliterationHi!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeHindi, color: Colors.red.shade900)),
                              ],
                              if (settings.showTransliteration && verse.transliteration != null && verse.transliteration!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(verse.transliteration!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeEnglish, color: Colors.blueGrey)),
                              ],
                              if (settings.showEnglishMeaning && verse.translation != null && verse.translation!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(verse.translation!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: settings.fontSizeMeaning, fontStyle: FontStyle.italic, color: Colors.black87)),
                              ],
                              if (settings.showPunjabiMeaning && verse.translationPa != null && verse.translationPa!.isNotEmpty) ...[
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
          error: (err, stack) => Center(child: Text('Error: $err')),
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
              activeColor: Colors.teal,
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

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/shabad_providers.dart';

class ShabadPage extends ConsumerStatefulWidget {
  final String shabadId;

  const ShabadPage({super.key, required this.shabadId});

  @override
  ConsumerState<ShabadPage> createState() => _ShabadPageState();
}

class _ShabadPageState extends ConsumerState<ShabadPage> {
  bool _showTranslation = true;
  bool _showTransliteration = false;
  bool _showHindi = false;
  bool _showVishrams = true;

  double _fontSizeGurmukhi = 28;
  double _fontSizeHindi = 20;
  double _fontSizeEnglish = 16;
  double _fontSizeMeaning = 16;

  @override
  Widget build(BuildContext context) {
    final shabadAsync = ref.watch(shabadDetailsProvider(widget.shabadId));

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
                      onPressed: () => _showSettingsDialog(context),
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
                              _buildGurmukhiText(verse.gurmukhi, verse.visraams),
                              if (_showHindi && verse.transliterationHi != null && verse.transliterationHi!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(verse.transliterationHi!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: _fontSizeHindi, color: Colors.red.shade900)),
                              ],
                              if (_showTransliteration && verse.transliteration != null && verse.transliteration!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(verse.transliteration!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: _fontSizeEnglish, color: Colors.blueGrey)),
                              ],
                              if (_showTranslation && verse.translation != null && verse.translation!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(verse.translation!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: _fontSizeMeaning, fontStyle: FontStyle.italic, color: Colors.black87)),
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Display Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnifiedControl(
                      label: 'Gurmukhi',
                      isVisible: true,
                      size: _fontSizeGurmukhi,
                      isSizeOnly: true,
                      onToggle: (_) {},
                      onSizeChanged: (val) {
                        setState(() => _fontSizeGurmukhi = val);
                        setDialogState(() {});
                      },
                    ),
                    const Divider(),
                    _buildUnifiedControl(
                      label: 'Hindi',
                      isVisible: _showHindi,
                      size: _fontSizeHindi,
                      onToggle: (v) {
                        setState(() => _showHindi = v);
                        setDialogState(() {});
                      },
                      onSizeChanged: (val) {
                        setState(() => _fontSizeHindi = val);
                        setDialogState(() {});
                      },
                    ),
                    _buildUnifiedControl(
                      label: 'English',
                      isVisible: _showTransliteration,
                      size: _fontSizeEnglish,
                      onToggle: (v) {
                        setState(() => _showTransliteration = v);
                        setDialogState(() {});
                      },
                      onSizeChanged: (val) {
                        setState(() => _fontSizeEnglish = val);
                        setDialogState(() {});
                      },
                    ),
                    _buildUnifiedControl(
                      label: 'Meaning',
                      isVisible: _showTranslation,
                      size: _fontSizeMeaning,
                      onToggle: (v) {
                        setState(() => _showTranslation = v);
                        setDialogState(() {});
                      },
                      onSizeChanged: (val) {
                        setState(() => _fontSizeMeaning = val);
                        setDialogState(() {});
                      },
                    ),
                    _buildUnifiedControl(
                      label: 'Pauses',
                      isVisible: _showVishrams,
                      size: 0,
                      isVisibilityOnly: true,
                      onToggle: (v) {
                        setState(() => _showVishrams = v);
                        setDialogState(() {});
                      },
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

  Widget _buildGurmukhiText(String gurmukhi, String? visraamsJson) {
    final baseStyle = TextStyle(
      fontSize: _fontSizeGurmukhi,
      fontWeight: FontWeight.w500,
      height: 1.6,
      color: Colors.black,
    );

    // Logging the data incoming from DB
    dev.log('Rendering Line: "$gurmukhi"', name: 'GurbaniUI');
    dev.log('Vishram Data: $visraamsJson', name: 'GurbaniUI');

    if (!_showVishrams || visraamsJson == null || visraamsJson.isEmpty || visraamsJson == '[]') {
      return Text(gurmukhi, textAlign: TextAlign.center, style: baseStyle);
    }

    try {
      final List<dynamic> vList = jsonDecode(visraamsJson);
      // Using precise word splitting logic (ignoring multiple spaces)
      final words = gurmukhi.trim().split(RegExp(r'\s+'));
      final List<InlineSpan> spans = [];

      dev.log('Split Words Count: ${words.length}', name: 'GurbaniUI');

      for (int i = 0; i < words.length; i++) {
        String? type;
        for (final v in vList) {
          final p = v['p'];
          final pIndex = p is int ? p : int.tryParse(p.toString());
          if (pIndex == i) {
            type = v['t'];
            dev.log('Highlight Triggered for Word [$i]: "${words[i]}" type: $type', name: 'GurbaniUI');
            break;
          }
        }
        
        Color? bgColor;
        Color? textColor;
        if (type == 'v') {
          bgColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
        } else if (type == 'y') {
          bgColor = Colors.blue.shade100;
          textColor = Colors.blue.shade900;
        }

        spans.add(TextSpan(
          text: words[i],
          style: TextStyle(
            backgroundColor: bgColor,
            color: textColor ?? Colors.black,
            fontWeight: textColor != null ? FontWeight.w900 : FontWeight.w500,
          ),
        ));

        if (i < words.length - 1) {
          spans.add(const TextSpan(text: ' ', style: TextStyle(backgroundColor: null, color: Colors.black)));
        }
      }

      // Add double danda if it was lost during splitting
      if (gurmukhi.endsWith('॥') && !words.last.contains('॥')) {
        spans.add(const TextSpan(text: ' ॥', style: TextStyle(color: Colors.black)));
      }

      return Text.rich(
        TextSpan(style: baseStyle, children: spans),
        textAlign: TextAlign.center,
      );
    } catch (e) {
      dev.log('Highlighting Logic Failed: $e', name: 'GurbaniUI', error: e);
      return Text(gurmukhi, textAlign: TextAlign.center, style: baseStyle);
    }
  }
}

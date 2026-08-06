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
  bool _showTransliteration = true;
  bool _showHindi = false;

  @override
  Widget build(BuildContext context) {
    final shabadAsync = ref.watch(shabadDetailsProvider(widget.shabadId));

    return Scaffold(
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
              // 1. SCROLLABLE APP BAR
              SliverAppBar(
                title: const Text('Shabad View'),
                floating: false,
                pinned: false,
                actions: [
                  PopupMenuButton<void>(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Display Options',
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: _buildMenuOption('Hindi', _showHindi, (v) {
                          setState(() => _showHindi = v);
                          Navigator.pop(context);
                        }),
                      ),
                      PopupMenuItem(
                        child: _buildMenuOption('English', _showTransliteration, (v) {
                          setState(() => _showTransliteration = v);
                          Navigator.pop(context);
                        }),
                      ),
                      PopupMenuItem(
                        child: _buildMenuOption('Meaning', _showTranslation, (v) {
                          setState(() => _showTranslation = v);
                          Navigator.pop(context);
                        }),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. SCROLLABLE METADATA
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(30),
                  child: Column(
                    children: [
                      if (hasRaag)
                        Text(firstVerse.raagName!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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

              // 3. VERSES LIST
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
                            Text(
                              verse.gurmukhi,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500, height: 1.6),
                            ),
                            if (_showHindi && verse.transliterationHi != null && verse.transliterationHi!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(verse.transliterationHi!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, color: Colors.deepOrangeAccent)),
                            ],
                            if (_showTransliteration && verse.transliteration != null && verse.transliteration!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(verse.transliteration!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
                            ],
                            if (_showTranslation && verse.translation != null && verse.translation!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(verse.translation!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87)),
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
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }

  Widget _buildMenuOption(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

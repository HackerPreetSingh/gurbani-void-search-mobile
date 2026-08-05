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
      appBar: AppBar(
        title: const Text('Shabad View'),
        actions: [
          IconButton(
            icon: Text('हिਂ',
                style: TextStyle(
                  color: _showHindi ? Colors.white : Colors.white60,
                  fontWeight: _showHindi ? FontWeight.bold : FontWeight.normal,
                )),
            onPressed: () => setState(() => _showHindi = !_showHindi),
            tooltip: 'Toggle Hindi',
          ),
          IconButton(
            icon: Icon(_showTransliteration
                ? Icons.font_download
                : Icons.font_download_outlined),
            onPressed: () =>
                setState(() => _showTransliteration = !_showTransliteration),
            tooltip: 'Toggle Transliteration',
          ),
          IconButton(
            icon: Icon(
                _showTranslation ? Icons.translate : Icons.translate_outlined),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
            tooltip: 'Toggle Translation',
          ),
        ],
      ),
      body: shabadAsync.when(
        data: (verses) {
          if (verses.isEmpty) return const Center(child: Text('Shabad not found.'));

          final firstVerse = verses.first;

          // Build cleaner header metadata
          final bool hasRaag = firstVerse.raagName != null &&
              firstVerse.raagName!.toLowerCase() != 'unknown' &&
              firstVerse.raagName!.isNotEmpty;
          final bool hasWriter = firstVerse.writerName != null &&
              firstVerse.writerName!.toLowerCase() != 'unknown' &&
              firstVerse.writerName!.isNotEmpty;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withAlpha(50),
                child: Column(
                  children: [
                    if (hasRaag)
                      Text(
                        firstVerse.raagName!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    if (hasWriter)
                      Text(
                        firstVerse.writerName!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    Text(
                      '${firstVerse.sourceName} • Ang ${firstVerse.ang ?? "-"}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: verses.length,
                  separatorBuilder: (context, index) => const Divider(height: 48),
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          verse.gurmukhi,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        if (_showHindi &&
                            verse.transliterationHi != null &&
                            verse.transliterationHi!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            verse.transliterationHi!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.orange),
                          ),
                        ],
                        if (_showTransliteration &&
                            verse.transliteration != null &&
                            verse.transliteration!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            verse.transliteration!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.blueGrey),
                          ),
                        ],
                        if (_showTranslation &&
                            verse.translation != null &&
                            verse.translation!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            verse.translation!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading Shabad: $err'),
          ),
        ),
      ),
    );
  }
}

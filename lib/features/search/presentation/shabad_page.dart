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
      ),
      body: shabadAsync.when(
        data: (verses) {
          if (verses.isEmpty) return const Center(child: Text('Shabad not found.'));

          final firstVerse = verses.first;
          
          // STRICT Metadata visibility logic
          final bool hasRaag = firstVerse.raagName != null &&
              firstVerse.raagName!.isNotEmpty &&
              !firstVerse.raagName!.toLowerCase().contains('unknown');
              
          final bool hasWriter = firstVerse.writerName != null &&
              firstVerse.writerName!.isNotEmpty &&
              !firstVerse.writerName!.toLowerCase().contains('unknown');

          return Column(
            children: [
              // CLEAN HEADER & DISPLAY CONTROLS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      child: Divider(),
                    ),

                    // RADIO-STYLE DISPLAY CONTROLS
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildOption('Hindi', _showHindi, (v) => setState(() => _showHindi = v)),
                        _buildOption('English', _showTransliteration, (v) => setState(() => _showTransliteration = v)),
                        _buildOption('Meaning', _showTranslation, (v) => setState(() => _showTranslation = v)),
                      ],
                    ),
                  ],
                ),
              ),

              // VERSES LIST
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: verses.length,
                  separatorBuilder: (context, index) => const Divider(height: 48, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    return Column(
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
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOption(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

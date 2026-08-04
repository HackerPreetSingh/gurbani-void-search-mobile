import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/shabad_providers.dart';

class ShabadPage extends ConsumerWidget {
  final String shabadId;

  const ShabadPage({super.key, required this.shabadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shabadAsync = ref.watch(shabadDetailsProvider(shabadId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shabad View'),
      ),
      body: shabadAsync.when(
        data: (verses) {
          if (verses.isEmpty) return const Center(child: Text('Shabad not found.'));

          final firstVerse = verses.first;
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                child: Column(
                  children: [
                    Text(
                      firstVerse.raagName ?? 'Unknown Raag',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      firstVerse.writerName ?? 'Unknown Author',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Ang ${firstVerse.ang ?? "-"}',
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
                        if (verse.transliteration != null && verse.transliteration!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            verse.transliteration!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, color: Colors.blueGrey),
                          ),
                        ],
                        if (verse.translation != null && verse.translation!.isNotEmpty) ...[
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

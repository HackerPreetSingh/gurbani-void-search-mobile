import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/gurbani_search_result.dart';
import '../domain/providers/search_providers.dart';
import 'search_view_model.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurbani Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(corpusImportServiceProvider).importFromAsset(
                  'assets/corpus/sample_corpus.json',
                );
                ref.invalidate(searchViewModelProvider);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Corpus imported successfully!')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Import failed: $e')),
                );
              }
            },
            tooltip: 'Import Sample Corpus',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search Gurmukhi...',
              onChanged: (value) {
                ref.read(searchViewModelProvider.notifier).onQueryChanged(value);
              },
              leading: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: searchState.when(
              data: (response) {
                if (response == null) {
                  return const Center(child: Text('Start searching...'));
                }
                return _buildResults(context, ref, response);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, WidgetRef ref, PunjabiSearchResponse response) {
    if (response.status == PunjabiSearchStatus.noCorpus) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No corpus found.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(corpusImportServiceProvider).importFromAsset(
                    'assets/corpus/sample_corpus.json',
                  );
                  ref.invalidate(searchViewModelProvider);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Corpus imported successfully!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              },
              child: const Text('Import Sample Corpus'),
            ),
          ],
        ),
      );
    }

    if (response.results.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return ListView.builder(
      itemCount: response.results.length,
      itemBuilder: (context, index) {
        final result = response.results[index];
        return ListTile(
          title: Text(
            result.gurmukhi,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${result.sourceName} • Ang ${result.ang ?? 'N/A'}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            result.match == SearchResultMatch.initial ? 'Initial' : 'Word',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        );
      },
    );
  }
}

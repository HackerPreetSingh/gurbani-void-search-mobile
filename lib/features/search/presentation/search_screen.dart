import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/gurbani_search_result.dart';
import 'search_view_model.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurbani Search'),
        actions: [
          TextButton.icon(
            onPressed: () => vm.toggleHistoryMode(),
            icon: Icon(vm.isHistoryMode ? Icons.search : Icons.history),
            label: Text(vm.isHistoryMode ? 'Search' : 'History'),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
          if (vm.isHistoryMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () => vm.clearHistory(),
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search Gurmukhi or Roman...',
              onChanged: (value) => vm.onQueryChanged(value),
              leading: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: searchState.when(
              data: (response) {
                if (response == null) {
                  return const Center(child: Text('Type at least 3 characters to search...'));
                }
                if (response.results.isEmpty) {
                  return Center(child: Text(vm.isHistoryMode ? 'No history found.' : 'No results found.'));
                }
                return ListView.builder(
                  itemCount: response.results.length,
                  itemBuilder: (context, index) => _buildResultTile(context, ref, response.results[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Search Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, WidgetRef ref, GurbaniSearchResult result) {
    final subtitleParts = [
      if (result.raagName != null && !result.raagName!.toLowerCase().contains('unknown') && result.raagName!.isNotEmpty)
        result.raagName,
      if (result.writerName != null && !result.writerName!.toLowerCase().contains('unknown') && result.writerName!.isNotEmpty)
        result.writerName,
      '${result.sourceName} • Ang ${result.ang ?? "-"}'
    ];

    return ListTile(
      onTap: () async {
        if (result.shabadId != null) {
          // Await the history addition to ensure it's saved before potentially viewing history again
          await ref.read(searchViewModelProvider.notifier).addToHistory(result);
          if (context.mounted) {
            context.push('/shabad/${result.shabadId}');
          }
        }
      },
      title: Text(result.gurmukhi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitleParts.join(' • '), style: const TextStyle(fontSize: 14, color: Colors.teal)),
    );
  }
}

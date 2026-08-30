import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/core_providers.dart';
import '../../foundation/presentation/foundation_page.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/providers/shabad_providers.dart';
import 'search_view_model.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbStatus = ref.watch(databaseStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurbani Search'),
      ),
      body: dbStatus.when(
        data: (status) {
          if (!status.isAvailable) {
            return const FoundationPage();
          }
          return _buildSearchContent(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: 'Search Gurmukhi or Roman...',
                  onChanged: (value) => vm.onQueryChanged(value),
                  leading: const Icon(Icons.search),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => vm.toggleHistoryMode(),
                icon: Icon(vm.isHistoryMode ? Icons.search : Icons.history),
                tooltip: vm.isHistoryMode ? 'Search' : 'History',
              ),
              if (vm.isHistoryMode)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: () => vm.clearHistory(),
                  tooltip: 'Clear History',
                ),
            ],
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
          // [AI_GUARD:PERMANENT_LOG] Starting pre-load for smooth transition.
          print('[GURBANI_LOG] [${DateTime.now()}] [search_screen.dart] UI_ACTION: Pre-loading shabad ${result.shabadId}...');
          
          await ref.read(searchViewModelProvider.notifier).addToHistory(result);
          await ref.read(shabadDetailsProvider(result.shabadId!).future);
          
          if (context.mounted) {
             print('[GURBANI_LOG] [${DateTime.now()}] [search_screen.dart] UI_ACTION: Pre-load complete. Pushing shabad page.');
             context.push('/shabad/${result.shabadId}?verseId=${result.stableId}');
          }
        }
      },
      title: Text(result.gurmukhi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitleParts.join(' • '), style: const TextStyle(fontSize: 14, color: Colors.teal)),
    );
  }
}

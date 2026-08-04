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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurbani Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search Gurmukhi or Roman...',
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
                  return const Center(child: Text('Type at least 3 characters to search...'));
                }
                return _buildResults(context, response);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Search Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, PunjabiSearchResponse response) {
    if (response.results.isEmpty) {
      return const Center(child: Text('No results found in production database.'));
    }

    return ListView.builder(
      itemCount: response.results.length,
      itemBuilder: (context, index) {
        final result = response.results[index];
        return ListTile(
          onTap: () {
            context.push('/shabad/${result.shabadId}');
          },
          title: Text(
            result.gurmukhi,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.raagName ?? "Unknown Raag"} • ${result.writerName ?? "Unknown Author"} • Ang ${result.ang ?? "-"}',
                style: const TextStyle(fontSize: 14, color: Colors.teal),
              ),
              if (result.translation != null)
                Text(
                  result.translation!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          isThreeLine: result.translation != null,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/core_providers.dart';
import '../../foundation/presentation/foundation_page.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/providers/shabad_providers.dart';
import 'search_view_model.dart';
import 'providers/keyboard_providers.dart';
import 'widgets/custom_keyboard.dart';
import '../../prakaran/presentation/prakaran_list_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      if (ref.read(searchQueryProvider) != query) {
        // Syncing controller changes to provider (when typing with system keyboard)
        ref.read(searchQueryProvider.notifier).setQuery(query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbStatus = ref.watch(databaseStatusProvider);
    
    // Sync external query changes back to controller (when using custom keyboard)
    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: next.length),
        );
      }
      ref.read(searchViewModelProvider.notifier).onQueryChanged(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurbani Search'),
        leading: IconButton(
          icon: const Icon(Icons.folder_special_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrakaranListScreen()),
          ),
          tooltip: 'My Prakarans',
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.keyboard_outlined),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Keyboard Settings',
            ),
          ),
        ],
      ),
      endDrawer: _buildKeyboardDrawer(),
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
      bottomNavigationBar: dbStatus.when(
        data: (status) => status.isAvailable ? const CustomKeyboard() : null,
        loading: () => null,
        error: (err, stack) => null,
      ),
    );
  }

  Widget _buildKeyboardDrawer() {
    final keyboardType = ref.watch(keyboardTypeProvider);
    final isVisible = ref.watch(customKeyboardVisibleProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.keyboard, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'Keyboard Settings',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Show Custom Keyboard'),
            value: isVisible,
            onChanged: (val) => ref.read(customKeyboardVisibleProvider.notifier).setVisible(val),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          RadioListTile<KeyboardType>(
            title: const Text('Punjabi (Gurmukhi)'),
            value: KeyboardType.punjabi,
            groupValue: keyboardType,
            onChanged: (val) {
              if (val != null) {
                ref.read(keyboardTypeProvider.notifier).setType(val);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<KeyboardType>(
            title: const Text('English (Phonetic)'),
            value: KeyboardType.english,
            groupValue: keyboardType,
            onChanged: (val) {
              if (val != null) {
                ref.read(keyboardTypeProvider.notifier).setType(val);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);
    final isCustomKeyboardVisible = ref.watch(customKeyboardVisibleProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search...',
                  onTap: () {
                    if (isCustomKeyboardVisible) {
                      // Custom keyboard is visible, system keyboard will also appear by default.
                    }
                  },
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).setQuery('');
                        },
                      ),
                  ],
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
          await ref.read(searchViewModelProvider.notifier).addToHistory(result);
          await ref.read(shabadDetailsProvider(result.shabadId!).future);
          
          if (context.mounted) {
             context.push('/shabad/${result.shabadId}?verseId=${result.stableId}');
          }
        }
      },
      title: Text(result.gurmukhi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitleParts.join(' • '), style: const TextStyle(fontSize: 14, color: Colors.teal)),
    );
  }
}

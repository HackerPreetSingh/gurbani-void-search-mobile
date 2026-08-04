import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/gurbani_search_result.dart';
import '../domain/providers/search_providers.dart';
import '../domain/services/gurmukhi_search_text.dart';

class SearchViewModel extends Notifier<AsyncValue<PunjabiSearchResponse?>> {
  @override
  AsyncValue<PunjabiSearchResponse?> build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const AsyncValue.data(null);
  }

  Timer? _debounceTimer;
  String _lastQuery = '';

  void onQueryChanged(String query) {
    if (_lastQuery == query) return;
    _lastQuery = query;

    _debounceTimer?.cancel();

    if (query.trim().length < 3) {
      state = const AsyncValue.data(null);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String rawQuery) async {
    final query = GurmukhiSearchText.parseQuery(rawQuery);
    
    if (!query.isSearchable) {
      state = AsyncValue.data(PunjabiSearchResponse(
        status: PunjabiSearchStatus.unsupportedQuery,
        query: query,
      ));
      return;
    }

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(punjabiSearchRepositoryProvider);
      final response = await repository.search(query);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final searchViewModelProvider =
    NotifierProvider<SearchViewModel, AsyncValue<PunjabiSearchResponse?>>(
  () => SearchViewModel(),
);

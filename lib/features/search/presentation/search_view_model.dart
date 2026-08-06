import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/providers/search_providers.dart';
import '../domain/services/gurmukhi_search_text.dart';

class SearchViewModel extends Notifier<AsyncValue<PunjabiSearchResponse?>> {
  @override
  AsyncValue<PunjabiSearchResponse?> build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const AsyncValue.data(null);
  }

  Timer? _debounceTimer;
  String _lastQuery = '';
  bool _isHistoryMode = false;

  bool get isHistoryMode => _isHistoryMode;

  Future<void> toggleHistoryMode() async {
    _isHistoryMode = !_isHistoryMode;
    if (_isHistoryMode) {
      await loadHistory();
    } else {
      if (_lastQuery.length >= 3) {
        await _performSearch(_lastQuery);
      } else {
        state = const AsyncValue.data(null);
      }
    }
  }

  void onQueryChanged(String query) {
    if (_lastQuery == query) return;
    _lastQuery = query;
    _debounceTimer?.cancel();
    _isHistoryMode = false;

    if (query.trim().length < 3) {
      state = const AsyncValue.data(null);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () => _performSearch(query));
  }

  Future<void> _performSearch(String rawQuery) async {
    final query = GurmukhiSearchText.parseQuery(rawQuery);
    state = const AsyncValue.loading();
    try {
      final res = await ref.read(punjabiSearchRepositoryProvider).search(query);
      state = AsyncValue.data(res);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final results = await ref.read(punjabiSearchRepositoryProvider).getHistory();
      state = AsyncValue.data(PunjabiSearchResponse(
        status: PunjabiSearchStatus.complete,
        query: 'History',
        results: results,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearHistory() async {
    await ref.read(punjabiSearchRepositoryProvider).clearHistory();
    if (_isHistoryMode) {
      await loadHistory();
    }
  }

  Future<void> addToHistory(GurbaniSearchResult result) async {
    await ref.read(punjabiSearchRepositoryProvider).addToHistory(result, _lastQuery);
    // If we are currently in history mode, refresh the list immediately
    if (_isHistoryMode) {
      await loadHistory();
    }
  }
}

final searchViewModelProvider = NotifierProvider<SearchViewModel, AsyncValue<PunjabiSearchResponse?>>(
  () => SearchViewModel(),
);

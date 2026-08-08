import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/providers/search_providers.dart';
import '../domain/services/gurmukhi_search_text.dart';

class SearchViewModel extends Notifier<AsyncValue<PunjabiSearchResponse?>> {
  @override
  AsyncValue<PunjabiSearchResponse?> build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
    });
    return const AsyncValue.data(null);
  }

  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  int _searchVersion = 0;
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
    _cancelToken?.cancel();
    _isHistoryMode = false;

    if (query.trim().length < 3) {
      state = const AsyncValue.data(null);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () => _performSearch(query));
  }

  Future<void> _performSearch(String rawQuery) async {
    final query = GurmukhiSearchText.parseQuery(rawQuery);
    
    _searchVersion++;
    final currentVersion = _searchVersion;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = const AsyncValue.loading();
    try {
      final res = await ref.read(punjabiSearchRepositoryProvider).search(
        query,
        cancelToken: _cancelToken,
      );
      
      if (currentVersion == _searchVersion) {
        state = AsyncValue.data(res);
      }
    } catch (e, st) {
      if (currentVersion == _searchVersion && e is! DioException) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> loadHistory() async {
    _searchVersion++;
    final currentVersion = _searchVersion;

    state = const AsyncValue.loading();
    try {
      final results = await ref.read(punjabiSearchRepositoryProvider).getHistory();
      if (currentVersion == _searchVersion) {
        state = AsyncValue.data(PunjabiSearchResponse(
          status: PunjabiSearchStatus.complete,
          query: 'History',
          results: results,
        ));
      }
    } catch (e, st) {
      if (currentVersion == _searchVersion) {
        state = AsyncValue.error(e, st);
      }
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

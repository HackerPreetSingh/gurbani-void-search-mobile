import 'package:dio/dio.dart';
import '../models/gurbani_corpus.dart';
import '../models/gurbani_search_result.dart';
import '../models/punjabi_search_query.dart';

import '../models/shabad_navigation.dart';

abstract interface class PunjabiSearchRepository {
  Future<GurbaniCorpusSummary?> activeCorpus();

  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  });

  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 500,
    CancelToken? cancelToken,
  });

  Future<List<GurbaniSearchResult>> getLocalShabad(
    String shabadId, {
    CancelToken? cancelToken,
  });

  Future<ShabadNavigation> getShabadNavigation(String shabadId);

  Future<void> addToHistory(GurbaniSearchResult result, String query);
  
  Future<List<GurbaniSearchResult>> getHistory();

  Future<void> clearHistory();
}

class CorpusImportException implements Exception {
  const CorpusImportException(this.message);
  final String message;
  @override
  String toString() => 'Corpus import failed: \$message';
}

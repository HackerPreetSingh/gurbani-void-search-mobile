import '../models/gurbani_corpus.dart';
import '../models/gurbani_search_result.dart';
import '../models/punjabi_search_query.dart';

abstract interface class PunjabiSearchRepository {
  Future<GurbaniCorpusSummary?> activeCorpus();

  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  });

  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 40,
  });
}

class CorpusImportException implements Exception {
  const CorpusImportException(this.message);

  final String message;

  @override
  String toString() => 'Corpus import failed: \$message';
}

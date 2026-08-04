import 'gurbani_corpus.dart';
import 'punjabi_search_query.dart';

enum SearchResultMatch { word, initial }

class GurbaniSearchResult {
  const GurbaniSearchResult({
    required this.stableId,
    required this.gurmukhi,
    required this.sourceName,
    required this.displayOrder,
    required this.match,
    this.writerName,
    this.raagName,
    this.ang,
  });

  final String stableId;
  final String gurmukhi;
  final String sourceName;
  final String? writerName;
  final String? raagName;
  final int? ang;
  final int displayOrder;
  final SearchResultMatch match;
}

enum PunjabiSearchStatus { emptyQuery, unsupportedQuery, noCorpus, complete }

class PunjabiSearchResponse {
  const PunjabiSearchResponse({
    required this.status,
    required this.query,
    this.corpus,
    this.results = const [],
  });

  final PunjabiSearchStatus status;
  final PunjabiSearchQuery query;
  final GurbaniCorpusSummary? corpus;
  final List<GurbaniSearchResult> results;
}

import 'gurbani_corpus.dart';

enum SearchResultMatch { word, initial }

class GurbaniSearchResult {
  const GurbaniSearchResult({
    required this.stableId,
    required this.gurmukhi,
    required this.sourceName,
    required this.displayOrder,
    required this.match,
    this.shabadId,
    this.writerName,
    this.raagName,
    this.ang,
    this.transliteration,
    this.transliterationHi,
    this.translation,
  });

  final String stableId;
  final String? shabadId;
  final String gurmukhi;
  final String sourceName;
  final String? writerName;
  final String? raagName;
  final int? ang;
  final int displayOrder;
  final SearchResultMatch match;
  final String? transliteration;
  final String? transliterationHi;
  final String? translation;
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
  final dynamic query;
  final GurbaniCorpusSummary? corpus;
  final List<GurbaniSearchResult> results;
}

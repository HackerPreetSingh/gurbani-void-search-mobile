import 'package:dio/dio.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/repositories/punjabi_search_repository.dart';

class BaniDbApiRepository implements PunjabiSearchRepository {
  BaniDbApiRepository(this._dio);

  final Dio _dio;
  static const _baseUrl = 'https://api.banidb.com/v2';

  @override
  Future<GurbaniCorpusSummary?> activeCorpus() async {
    return GurbaniCorpusSummary(
      id: 'banidb-live',
      displayName: 'BaniDB Live API',
      version: 'v2',
      lineCount: 150000,
      attribution: 'BaniDB Production',
      importedAtUtc: DateTime.now(),
    );
  }

  @override
  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  }) {
    throw UnimplementedError('Corpus management handled by BaniDB API.');
  }

  @override
  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 40,
  }) async {
    int searchType = 2; // Default to Word search
    bool isGurmukhi = true;

    if (query.kind == PunjabiSearchKind.gurmukhiInitial || 
        query.kind == PunjabiSearchKind.gurmukhiAmbiguous) {
      searchType = 0; // From start
    } else if (query.kind == PunjabiSearchKind.romanInitial) {
      searchType = 7; // Roman initials anywhere
      isGurmukhi = false;
    } else if (query.kind == PunjabiSearchKind.romanWord) {
      searchType = 4; // Roman word
      isGurmukhi = false;
    }

    try {
      var response = await _fetchFromApi(query.raw, searchType, isGurmukhi, limit, query);
      
      // Fallback for initials
      if (response.results.isEmpty && (searchType == 0 || searchType == 7)) {
        final fallbackType = isGurmukhi ? 1 : 7; // BaniDB type 7 is already 'anywhere' for Roman
        if (isGurmukhi) {
           response = await _fetchFromApi(query.raw, fallbackType, isGurmukhi, limit, query);
        }
      }

      return response;
    } catch (e) {
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.complete,
        query: query,
        results: [],
      );
    }
  }

  Future<PunjabiSearchResponse> _fetchFromApi(
    String rawQuery, 
    int searchType, 
    bool isGurmukhi, 
    int limit,
    PunjabiSearchQuery query,
  ) async {
    final encodedQuery = Uri.encodeComponent(rawQuery.trim());
    final url = '$_baseUrl/search/$encodedQuery';

    final response = await _dio.get(
      url,
      queryParameters: {
        'searchtype': searchType,
        'results': limit,
        'isGurmukhi': isGurmukhi ? 1 : 0,
      },
    );

    final List<dynamic> verses = response.data['verses'] ?? [];
    
    final results = verses.map((v) {
      final Map<String, dynamic> verse = v as Map<String, dynamic>;
      final Map<String, dynamic>? verseObj = verse['verse'] as Map<String, dynamic>?;
      final Map<String, dynamic>? source = verse['source'] as Map<String, dynamic>?;
      final Map<String, dynamic>? writer = verse['writer'] as Map<String, dynamic>?;
      final Map<String, dynamic>? raag = verse['raag'] as Map<String, dynamic>?;
      final Map<String, dynamic>? translit = verse['transliteration'] as Map<String, dynamic>?;
      final Map<String, dynamic>? translation = verse['translation'] as Map<String, dynamic>?;
      final Map<String, dynamic>? translationEn = translation?['en'] as Map<String, dynamic>?;

      return GurbaniSearchResult(
        stableId: (verse['verseId'] ?? verse['id'] ?? '0').toString(),
        shabadId: (verse['shabadId'] ?? verse['shabadID'] ?? '0').toString(),
        gurmukhi: verseObj?['unicode'] ?? verse['gurmukhi'] ?? '',
        sourceName: source?['english'] ?? verse['sourceEnglish'] ?? 'Unknown',
        writerName: writer?['english'],
        raagName: raag?['english'],
        ang: verse['pageNo'] ?? source?['pageNo'],
        displayOrder: verse['lineNo'] ?? 0,
        match: (searchType == 0 || searchType == 7 || searchType == 1) 
            ? SearchResultMatch.initial 
            : SearchResultMatch.word,
        transliteration: translit?['english'] ?? translit?['en'],
        translation: translationEn?['bdb'] ?? translationEn?['combined'],
      );
    }).toList();

    return PunjabiSearchResponse(
      status: PunjabiSearchStatus.complete,
      query: query,
      results: results,
    );
  }
}

import 'package:dio/dio.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/repositories/punjabi_search_repository.dart';
import 'local_search_data_source.dart';
import 'remote_search_data_source.dart';
import 'metadata_data_source.dart';
import 'search_result_mapper.dart';
import '../domain/services/gurmukhi_processor.dart';

class SqlitePunjabiSearchRepository implements PunjabiSearchRepository {
  SqlitePunjabiSearchRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._metadataDataSource,
    this._mapper,
  );

  final LocalSearchDataSource _localDataSource;
  final RemoteSearchDataSource _remoteDataSource;
  final MetadataDataSource _metadataDataSource;
  final SearchResultMapper _mapper;

  @override
  Future<GurbaniCorpusSummary?> activeCorpus() => _localDataSource.activeCorpus();

  @override
  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 40,
    CancelToken? cancelToken,
  }) async {
    final methodStart = DateTime.now();
    print('[GURBANI_LOG] [$methodStart] SEARCH_ENGINE_ENTRY: query="${query.raw}"');

    try {
      print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_1: Ensuring metadata cached...');
      await _metadataDataSource.ensureMetadataCached();
      
      final String raw = query.raw.replaceAll(RegExp(r'\s+'), '');
      print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_2: Space-stripped query: "$raw"');
      
      final charCodeQuery = GurmukhiProcessor.queryToFirstLetterStr(query.raw);
      final charCodeQueryWildcard = '$charCodeQuery,z';
      
      const operators = {'+', '-', '*', '"', '\''};
      bool hasOperators = query.raw.split('').any((c) => operators.contains(c));

      List<Map<String, dynamic>> rows = [];

      if (hasOperators) {
        print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_3: Using Operator-based Search');
        final queryObj = _firstLetterStartToQuery(charCodeQuery);
        rows = await _localDataSource.search(
          condition: queryObj['condition'],
          parameters: queryObj['parameters'],
          limit: limit,
        );
      } else {
        print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_3: Using Standard Numeric Search with Bindi Fallback');
        final queryObj = _generateBindiQuery(charCodeQuery, charCodeQueryWildcard);
        
        String? orderBy;
        if (raw.length < 3) {
          orderBy = 'LENGTH(first_letter_str) ASC, id ASC';
        }

        rows = await _localDataSource.search(
          condition: queryObj['condition'],
          parameters: queryObj['parameters'],
          limit: limit,
          orderBy: orderBy,
        );
      }

      if (rows.isEmpty) {
        // Strictly one-to-one word mapping.
        // If user types 'mkmgh', we search for exactly 'mkmgh' initials.
        // No characters are stripped because each alphabet represents a distinct word.
        final searchStr = raw.toLowerCase();
        print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_4: Numeric failed. Trying Strategy 2 (initials_en LIKE "%$searchStr%")...');
        
        rows = await _localDataSource.search(
          condition: 'initials_en LIKE ?',
          parameters: ['%$searchStr%'],
          limit: limit,
        );
      }

      if (rows.isEmpty && _isRoman(raw)) {
         print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_5: Primary strategies failed. Deep permuting...');
         final variations = _generateAllPhoneticVariations(raw);
         for (final v in variations) {
           if (v == raw.toLowerCase()) continue;
           final charCode = GurmukhiProcessor.queryToFirstLetterStr(v);
           final vRows = await _localDataSource.search(
             condition: 'first_letter_str BETWEEN ? AND ?',
             parameters: [charCode, '$charCode,z'],
             limit: limit,
           );
           if (vRows.isNotEmpty) {
             print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_STEP_6: SUCCESS via variation: "$v"');
             rows = vRows;
             break;
           }
         }
      }

      if (rows.isNotEmpty) {
        final results = rows.map((r) => _mapper.mapRow(r)).toList();
        final duration = DateTime.now().difference(methodStart).inMilliseconds;
        print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_COMPLETE: Hits: ${results.length}. Duration: ${duration}ms');
        return PunjabiSearchResponse(
          status: PunjabiSearchStatus.complete,
          query: query,
          results: results,
          source: 'Local',
        );
      }
    } catch (e, stack) {
       print('[GURBANI_LOG] SEARCH_ERROR: $e\n$stack');
    }

    if (cancelToken?.isCancelled == true) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: [], source: 'Local');
    }

    print('[GURBANI_LOG] [${DateTime.now()}] SEARCH_FALLBACK: Requesting Remote API...');
    try {
      final verses = await _remoteDataSource.search(query, limit: limit, cancelToken: cancelToken);
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.complete,
        query: query,
        results: verses.map((v) => _mapper.mapApi(v)).toList(),
        source: 'BaniDB',
      );
    } catch (e) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: [], source: 'BaniDB');
    }
  }

  @override
  Future<List<GurbaniSearchResult>> getLocalShabad(
    String shabadId, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _metadataDataSource.ensureMetadataCached();
      final rows = await _localDataSource.getLocalShabad(shabadId);
      if (rows.isNotEmpty) return rows.map((r) => _mapper.mapRow(r)).toList();
    } catch (_) {}

    try {
      final data = await _remoteDataSource.getShabad(shabadId, cancelToken: cancelToken);
      if (data == null) return [];
      final Map<String, dynamic>? shabadInfo = data['shabadInfo'] as Map<String, dynamic>?;
      final List verses = data['verses'] ?? [];
      return verses.map((v) => _mapper.mapApi(v, shabadInfo: shabadInfo)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addToHistory(GurbaniSearchResult result, String query) => 
      _localDataSource.addToHistory(result, query);

  @override
  Future<List<GurbaniSearchResult>> getHistory() async {
    final rows = await _localDataSource.getHistory();
    return rows.map((r) => _mapper.mapHistoryRow(r)).toList();
  }

  @override
  Future<void> clearHistory() => _localDataSource.clearHistory();

  // Helper Ported Methods:
  
  Map<String, dynamic> _firstLetterStartToQuery(String charCodeQuery) {
    final regex = RegExp(r'[+-]?[^+-]+');
    final matches = regex.allMatches(charCodeQuery).map((m) => m.group(0)!).toList();
    final conditions = <String>[];
    final parameters = <dynamic>[];

    for (var match in matches) {
      String modifiedMatch = match.replaceAll(RegExp("[*\"']"), '');
      if (matches.length == 1 && !match.contains('+') && !match.contains('-')) {
        conditions.add('first_letter_str LIKE ?');
        parameters.add('$modifiedMatch%');
      } else if (match.startsWith('-')) {
        modifiedMatch = modifiedMatch.substring(1);
        conditions.add('first_letter_str NOT LIKE ?');
        parameters.add('%$modifiedMatch%');
      } else {
        if (match.startsWith('+')) modifiedMatch = modifiedMatch.substring(1);
        conditions.add('first_letter_str LIKE ?');
        parameters.add('%$modifiedMatch%');
      }
    }
    return {'condition': conditions.join(' AND '), 'parameters': parameters};
  }

  Map<String, dynamic> _generateBindiQuery(String charCodeQuery, String charCodeQueryWildcard) {
    final bindiMap = {'103': '090', '106': '122', '115': '083', '075': '094', '080': '038'};
    String updatedQuery = charCodeQuery;
    String updatedWildcard = charCodeQueryWildcard;
    for (var entry in bindiMap.entries) {
      updatedQuery = updatedQuery.replaceAll(entry.key, entry.value);
      updatedWildcard = updatedWildcard.replaceAll(entry.key, entry.value);
    }
    if (updatedQuery != charCodeQuery) {
      return {
        'condition': '(first_letter_str BETWEEN ? AND ? OR first_letter_str BETWEEN ? AND ?)',
        'parameters': [charCodeQuery, charCodeQueryWildcard, updatedQuery, updatedWildcard],
      };
    }
    return {
      'condition': 'first_letter_str BETWEEN ? AND ?',
      'parameters': [charCodeQuery, charCodeQueryWildcard],
    };
  }

  List<String> _generateAllPhoneticVariations(String input) {
    final mapping = {
      'i': ['e'], 'e': ['i'],
      'u': ['o'], 'o': ['u', 'a'],
      'a': ['o'], 'v': ['w'], 'w': ['v'], 'z': ['j'],
      's': ['S'], 'S': ['s'],
      'k': ['K'], 'K': ['k'],
      'g': ['G'], 'G': ['g'],
      'c': ['C'], 'C': ['c'],
      'j': ['J', 'z'], 'J': ['j'],
      't': ['T', 'q', 'Q'],
      'q': ['Q', 't'],
      'd': ['D'], 'D': ['d'],
      'p': ['P'], 'P': ['p'],
      'b': ['B'], 'B': ['b'],
    };
    var variations = <String>{input.toLowerCase()};
    final rawInput = input.toLowerCase();
    final limit = rawInput.length > 6 ? 6 : rawInput.length;
    for (int i = 0; i < limit; i++) {
      final char = rawInput[i];
      if (mapping.containsKey(char)) {
        final newVariations = <String>{};
        for (final variant in variations) {
          for (final substitution in mapping[char]!) {
            final variantChars = variant.split('');
            variantChars[i] = substitution;
            newVariations.add(variantChars.join(''));
          }
        }
        variations.addAll(newVariations);
        if (variations.length > 64) break; 
      }
    }
    return variations.toList();
  }

  bool _isRoman(String input) => RegExp(r'^[a-zA-Z0-9\s+-]+$').hasMatch(input);
}

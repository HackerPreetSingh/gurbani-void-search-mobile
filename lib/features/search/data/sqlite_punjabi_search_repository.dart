import 'package:dio/dio.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/models/shabad_navigation.dart';
import '../domain/repositories/punjabi_search_repository.dart';
import 'local_search_data_source.dart';
import 'remote_search_data_source.dart';
import 'metadata_data_source.dart';
import 'search_result_mapper.dart';
import '../domain/services/gurmukhi_processor.dart';
import '../domain/services/search_query_builder.dart';
import '../domain/services/search_response_processor.dart';

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
    int limit = 500,
    CancelToken? cancelToken,
  }) async {
    try {
      await _metadataDataSource.ensureMetadataCached();
      
      final String raw = query.raw.replaceAll(RegExp(r'\s+'), '');
      final charCodeQuery = GurmukhiProcessor.queryToFirstLetterStr(query.raw);
      
      const operators = {'+', '-', '*', '"', '\''};
      bool hasOperators = query.raw.split('').any((c) => operators.contains(c));

      List<Map<String, dynamic>> rows = [];

      if (hasOperators) {
        final queryObj = SearchQueryBuilder.buildOperatorQuery(charCodeQuery);
        rows = await _localDataSource.search(
          condition: queryObj['condition'],
          parameters: queryObj['parameters'],
          limit: limit,
        );
      } else {
        final bindiQuery = SearchQueryBuilder.buildBindiQuery(charCodeQuery);
        
        String? orderBy;
        if (raw.length < 3) {
          orderBy = 'LENGTH(first_letter_str) ASC, id ASC';
        }

        rows = await _localDataSource.search(
          condition: bindiQuery['condition'],
          parameters: bindiQuery['parameters'],
          limit: limit,
          orderBy: orderBy,
        );
      }

      if (rows.isEmpty) {
        rows = await _localDataSource.search(
          condition: 'initials_en LIKE ?',
          parameters: ['%${raw.toLowerCase()}%'],
          limit: limit,
        );
      }

      if (rows.isEmpty && _isRoman(raw)) {
         final variations = GurmukhiProcessor.generatePhoneticVariations(raw);
         for (final v in variations) {
           if (v == raw.toLowerCase()) continue;
           final charCode = GurmukhiProcessor.queryToFirstLetterStr(v);
           final vRows = await _localDataSource.search(
             condition: 'first_letter_str BETWEEN ? AND ?',
             parameters: [charCode, '$charCode,z'],
             limit: limit,
           );
           if (vRows.isNotEmpty) {
             rows = vRows;
             break;
           }
         }
      }

      if (rows.isNotEmpty) {
        final allResults = rows.map((r) => _mapper.mapRow(r)).toList();
        final filteredResults = SearchResponseProcessor.filterAndPrioritize(allResults);
        
        return PunjabiSearchResponse(
          status: PunjabiSearchStatus.complete,
          query: query,
          results: filteredResults,
          source: 'Local',
        );
      }
    } catch (e) {
       // Log handled by calling side or specific logger
    }

    if (cancelToken?.isCancelled == true) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: [], source: 'Local');
    }

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
    } catch (_) {}
    return [];
  }

  @override
  Future<ShabadNavigation> getShabadNavigation(String shabadId) => 
      _localDataSource.getShabadNavigation(shabadId);

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

  bool _isRoman(String input) => RegExp(r'^[a-zA-Z0-9\s+-]+$').hasMatch(input);
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/repositories/punjabi_search_repository.dart';
import 'local_search_data_source.dart';
import 'remote_search_data_source.dart';
import 'metadata_data_source.dart';
import 'search_result_mapper.dart';

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
    try {
      await _metadataDataSource.ensureMetadataCached();
      final rows = await _localDataSource.search(query.raw, limit: limit);

      if (rows.isNotEmpty) {
        return PunjabiSearchResponse(
          status: PunjabiSearchStatus.complete,
          query: query,
          results: rows.map((r) => _mapper.mapRow(r)).toList(),
        );
      }
    } catch (e) {
       if (kDebugMode) print('Local search failed: $e');
    }

    if (cancelToken?.isCancelled == true) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: []);
    }

    try {
      final verses = await _remoteDataSource.search(query, limit: limit, cancelToken: cancelToken);
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.complete,
        query: query,
        results: verses.map((v) => _mapper.mapApi(v)).toList(),
      );
    } catch (e) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: []);
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
}

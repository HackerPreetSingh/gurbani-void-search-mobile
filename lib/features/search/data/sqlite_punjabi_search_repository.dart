import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/local_database.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/repositories/punjabi_search_repository.dart';
import '../domain/services/gurmukhi_processor.dart';

class SqlitePunjabiSearchRepository implements PunjabiSearchRepository {
  SqlitePunjabiSearchRepository(this._database);

  final LocalDatabase _database;
  final _dio = Dio();

  @override
  Future<GurbaniCorpusSummary?> activeCorpus() async {
    try {
      final rows = await _database.read((executor) => executor.runSelect('SELECT COUNT(*) as c FROM verses', []));
      final count = rows.first['c'] as int;
      return GurbaniCorpusSummary(
        id: 'offline-production',
        displayName: 'Hybrid Engine',
        version: '1.2.0',
        lineCount: count,
        attribution: 'BaniDB',
        importedAtUtc: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PunjabiSearchResponse> search(PunjabiSearchQuery query, {int limit = 40}) async {
    final searchPattern = GurmukhiProcessor.queryToFirstLetterStr(query.raw);
    if (searchPattern.isEmpty) return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query);

    try {
      final rows = await _database.read((executor) => executor.runSelect('''
        SELECT v.*, s.ang, src.name_en as source_name, w.name_en as writer_name, r.name_en as raag_name
        FROM verses v
        JOIN shabads s ON v.shabad_id = s.id
        LEFT JOIN sources src ON s.source_id = src.id
        LEFT JOIN writers w ON s.writer_id = w.id
        LEFT JOIN raags r ON s.raag_id = r.id
        WHERE v.first_letter_str LIKE ? LIMIT ?
      ''', ['$searchPattern%', limit]));

      if (rows.isNotEmpty) {
        return PunjabiSearchResponse(
          status: PunjabiSearchStatus.complete,
          query: query,
          results: rows.map((r) => _mapRow(r)).toList(),
        );
      }
    } catch (e) {
       if (kDebugMode) print('Local search failed: $e');
    }

    try {
      final encodedQuery = Uri.encodeComponent(query.raw.trim());
      final response = await _dio.get('https://api.banidb.com/v2/search/$encodedQuery', queryParameters: {
        'searchtype': (query.kind == PunjabiSearchKind.romanInitial) ? 7 : 0,
        'results': limit,
      });
      final List verses = response.data['verses'] ?? [];
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.complete,
        query: query,
        results: verses.map((v) => _mapApi(v)).toList(),
      );
    } catch (e) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: []);
    }
  }

  @override
  Future<List<GurbaniSearchResult>> getLocalShabad(String shabadId) async {
    try {
      final rows = await _database.read((executor) => executor.runSelect('''
        SELECT v.*, s.ang, src.name_en as source_name, w.name_en as writer_name, r.name_en as raag_name
        FROM verses v
        JOIN shabads s ON v.shabad_id = s.id
        LEFT JOIN sources src ON s.source_id = src.id
        LEFT JOIN writers w ON s.writer_id = w.id
        LEFT JOIN raags r ON s.raag_id = r.id
        WHERE v.shabad_id = ? ORDER BY v.verse_order ASC
      ''', [int.tryParse(shabadId) ?? 0]));

      if (rows.isNotEmpty) return rows.map((r) => _mapRow(r)).toList();
    } catch (_) {}

    try {
      final res = await _dio.get('https://api.banidb.com/v2/shabads/$shabadId');
      final Map<String, dynamic> data = res.data as Map<String, dynamic>;
      final Map<String, dynamic>? shabadInfo = data['shabadInfo'] as Map<String, dynamic>?;
      final List verses = data['verses'] ?? [];
      return verses.map((v) => _mapApi(v, shabadInfo: shabadInfo)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addToHistory(GurbaniSearchResult result, String query) async {
    final sId = int.tryParse(result.shabadId ?? '');
    if (sId == null) return;
    
    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT OR REPLACE INTO search_history (shabad_id, query, gurmukhi, source_name, raag_name, writer_name, ang, viewed_at_utc) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          sId, 
          query, 
          result.gurmukhi, 
          result.sourceName, 
          result.raagName, 
          result.writerName, 
          result.ang, 
          DateTime.now().toUtc().toIso8601String()
        ],
      );
    });
  }

  @override
  Future<List<GurbaniSearchResult>> getHistory() async {
    final rows = await _database.read((executor) => executor.runSelect('''
      SELECT * FROM search_history ORDER BY viewed_at_utc DESC
    ''', []));
    
    return rows.map((r) => GurbaniSearchResult(
      stableId: 'hist_${r['shabad_id']}',
      shabadId: r['shabad_id'].toString(),
      gurmukhi: r['gurmukhi'] as String,
      sourceName: r['source_name'] as String,
      writerName: r['writer_name'] as String?,
      raagName: r['raag_name'] as String?,
      ang: r['ang'] as int?,
      displayOrder: 0,
      match: SearchResultMatch.initial,
    )).toList();
  }

  @override
  Future<void> clearHistory() async {
    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM search_history');
    });
  }

  GurbaniSearchResult _mapRow(Map<String, dynamic> r) {
    return GurbaniSearchResult(
      stableId: r['id'].toString(),
      shabadId: r['shabad_id'].toString(),
      gurmukhi: r['gurmukhi'],
      sourceName: r['source_name'] ?? 'Unknown',
      writerName: r['writer_name'],
      raagName: r['raag_name'],
      ang: r['ang'],
      displayOrder: r['verse_order'],
      match: SearchResultMatch.initial,
      transliteration: r['transliteration'],
      transliterationHi: r['transliteration_hi'],
      translation: r['translation'],
    );
  }

  GurbaniSearchResult _mapApi(Map v, {Map<String, dynamic>? shabadInfo}) {
    final String? raag = shabadInfo?['raag']?['english'] ?? v['raag']?['english'];
    final String? writer = shabadInfo?['writer']?['english'] ?? v['writer']?['english'];
    final String? source = shabadInfo?['source']?['english'] ?? v['source']?['english'] ?? 'Unknown';
    final int? ang = shabadInfo?['pageNo'] ?? v['pageNo'] ?? v['source']?['pageNo'];

    return GurbaniSearchResult(
      stableId: (v['verseId'] ?? v['id'] ?? 0).toString(),
      shabadId: (v['shabadId'] ?? 0).toString(),
      gurmukhi: v['verse']?['unicode'] ?? v['gurmukhi'] ?? '',
      sourceName: source ?? 'Unknown',
      writerName: writer,
      raagName: raag,
      ang: ang,
      displayOrder: v['lineNo'] ?? 0,
      match: SearchResultMatch.initial,
      transliteration: v['transliteration']?['english'] ?? v['transliteration']?['en'],
      transliterationHi: v['transliteration']?['hindi'] ?? v['transliteration']?['hi'],
      translation: v['translation']?['en']?['bdb'] ?? v['translation']?['en']?['combined'],
    );
  }
}

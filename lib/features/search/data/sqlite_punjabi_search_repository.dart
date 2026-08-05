import 'dart:developer' as dev;
import '../../../core/database/local_database.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/repositories/punjabi_search_repository.dart';
import '../domain/services/gurmukhi_processor.dart';

class SqlitePunjabiSearchRepository implements PunjabiSearchRepository {
  SqlitePunjabiSearchRepository(this._database);

  final LocalDatabase _database;

  @override
  Future<GurbaniCorpusSummary?> activeCorpus() async {
    try {
      final rows = await _database.read(
        (executor) => executor.runSelect('SELECT COUNT(*) as line_count FROM verses', []),
      );
      final count = (rows.single['line_count'] as num).toInt();
      
      dev.log('Active corpus check: $count lines found.', name: 'SearchRepository');
      
      if (count == 0) {
        dev.log('Corpus is empty. Triggering setup UI.', name: 'SearchRepository');
        return null;
      }

      return GurbaniCorpusSummary(
        id: 'offline-production',
        displayName: 'Full Offline Gurbani',
        version: '1.1.0',
        lineCount: count,
        attribution: 'BaniDB',
        importedAtUtc: DateTime.now(),
      );
    } catch (e) {
      dev.log('Error checking active corpus: $e', name: 'SearchRepository', error: e);
      return null;
    }
  }

  @override
  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  }) {
    throw UnimplementedError('Handled by ProductionIngestor.');
  }

  @override
  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 40,
  }) async {
    dev.log('Searching for: "${query.raw}"', name: 'SearchRepository');

    if (!query.isSearchable) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.unsupportedQuery, query: query);
    }

    final corpus = await activeCorpus();
    if (corpus == null) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.noCorpus, query: query);
    }

    final searchPattern = GurmukhiProcessor.queryToFirstLetterStr(query.raw);
    dev.log('Search pattern: "$searchPattern"', name: 'SearchRepository');
    
    if (searchPattern.isEmpty) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: []);
    }

    try {
      final rows = await _database.read((executor) => executor.runSelect('''
        SELECT 
          v.id, v.gurmukhi, v.verse_order, v.transliteration, v.transliteration_hi, v.translation,
          s.id as shabad_id,
          s.ang,
          src.name_en as source_name,
          w.name_en as writer_name,
          r.name_en as raag_name
        FROM verses v
        JOIN shabads s ON v.shabad_id = s.id
        LEFT JOIN sources src ON s.source_id = src.id
        LEFT JOIN writers w ON s.writer_id = w.id
        LEFT JOIN raags r ON s.raag_id = r.id
        WHERE v.first_letter_str LIKE ?
        ORDER BY v.id ASC
        LIMIT ?
      ''', ['$searchPattern%', limit]));

      dev.log('Found ${rows.length} results.', name: 'SearchRepository');

      final results = rows.map((row) => GurbaniSearchResult(
        stableId: (row['id'] as int).toString(),
        shabadId: (row['shabad_id'] as int).toString(),
        gurmukhi: row['gurmukhi'] as String,
        sourceName: row['source_name'] as String? ?? 'Unknown Source',
        writerName: row['writer_name'] as String?,
        raagName: row['raag_name'] as String?,
        ang: row['ang'] as int?,
        displayOrder: row['verse_order'] as int,
        match: SearchResultMatch.initial,
        transliteration: row['transliteration'] as String?,
        transliterationHi: row['transliteration_hi'] as String?,
        translation: row['translation'] as String?,
      )).toList();

      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.complete,
        query: query,
        results: results,
      );
    } catch (e) {
      dev.log('Search failed: $e', name: 'SearchRepository', error: e);
      return PunjabiSearchResponse(status: PunjabiSearchStatus.complete, query: query, results: []);
    }
  }

  @override
  Future<List<GurbaniSearchResult>> getLocalShabad(String shabadId) async {
    final sId = int.tryParse(shabadId) ?? 0;
    try {
      final rows = await _database.read((executor) => executor.runSelect('''
        SELECT 
          v.id, v.gurmukhi, v.verse_order, v.transliteration, v.transliteration_hi, v.translation,
          s.ang,
          src.name_en as source_name,
          w.name_en as writer_name,
          r.name_en as raag_name
        FROM verses v
        JOIN shabads s ON v.shabad_id = s.id
        LEFT JOIN sources src ON s.source_id = src.id
        LEFT JOIN writers w ON s.writer_id = w.id
        LEFT JOIN raags r ON s.raag_id = r.id
        WHERE v.shabad_id = ?
        ORDER BY v.verse_order ASC
      ''', [sId]));

      return rows.map((row) => GurbaniSearchResult(
        stableId: row['id'].toString(),
        shabadId: shabadId,
        gurmukhi: row['gurmukhi'] as String,
        sourceName: row['source_name'] as String? ?? 'Unknown Source',
        writerName: row['writer_name'] as String?,
        raagName: row['raag_name'] as String?,
        ang: row['ang'] as int?,
        displayOrder: row['verse_order'] as int,
        match: SearchResultMatch.word,
        transliteration: row['transliteration'] as String?,
        transliterationHi: row['transliteration_hi'] as String?,
        translation: row['translation'] as String?,
      )).toList();
    } catch (e) {
      return [];
    }
  }
}

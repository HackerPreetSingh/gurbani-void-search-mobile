import '../../../core/database/local_database.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/shabad_navigation.dart';

class LocalSearchDataSource {
  LocalSearchDataSource(this._database, this._nitnemDatabase);
  final LocalDatabase _database;
  final LocalDatabase _nitnemDatabase;

  Future<GurbaniCorpusSummary?> activeCorpus() async {
    try {
      final rows = await _database.read((executor) => executor.runSelect('SELECT COUNT(*) as c FROM verses', []));
      final count = rows.first['c'] as int;
      return GurbaniCorpusSummary(
        id: 'offline-production',
        displayName: 'Hybrid Engine',
        version: '1.3.0',
        lineCount: count,
        attribution: 'BaniDB',
        importedAtUtc: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> search({
    required String condition,
    required List<dynamic> parameters,
    int limit = 500,
    String? orderBy,
  }) async {
    // [AI_GUARD:PERMANENT_LOG] Deep logging for search query execution (Multi-DB).
    final startTime = DateTime.now();
    try {
      final orderClause = orderBy ?? '''
          (CASE WHEN source_id = 'G' THEN 0 ELSE 1 END) ASC,
          id ASC
      ''';

      // 1. Search Primary Shabad DB
      final shabadResults = await _database.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE $condition
        ORDER BY $orderClause
        LIMIT ?
      ''', [...parameters, limit]));
      
      // 2. Search Nitnem DB
      final nitnemResults = await _nitnemDatabase.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE $condition
        ORDER BY $orderClause
        LIMIT ?
      ''', [...parameters, limit]));

      // 3. Combine with tagging (to know which DB to load the shabad from later)
      final all = [
        ...shabadResults,
        ...nitnemResults
      ];

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_SEARCH_HIT: Shabad(${shabadResults.length}), Nitnem(${nitnemResults.length}) in ${duration}ms');
      
      return all;
    } catch (e) {
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_SEARCH_ERROR: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocalShabad(String shabadId) async {
    final sId = int.tryParse(shabadId) ?? 0;
    
    // Virtual IDs (999,999+) always go to Nitnem DB
    if (sId >= 999999) {
       return await _fetchFromDb(_nitnemDatabase, sId);
    }
    
    // Otherwise try Shabad DB
    final res = await _fetchFromDb(_database, sId);
    if (res.isNotEmpty) return res;

    // Last resort fallback to Nitnem DB
    return await _fetchFromDb(_nitnemDatabase, sId);
  }

  Future<List<Map<String, dynamic>>> _fetchFromDb(LocalDatabase db, int sId) async {
    final startTime = DateTime.now();
    try {
      if (sId == 0) return [];
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_FETCH_START: shabadId=$sId from ${db.dbName}');
      
      final results = await db.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE shabad_id = ? 
        ORDER BY id ASC
      ''', [sId]));
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_FETCH_COMPLETE: Found ${results.length} verses in ${duration}ms');
      
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getVersesForAng(int ang, String sourceId) async {
    final startTime = DateTime.now();
    try {
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_ANG_FETCH_START: ang=$ang, sourceId=$sourceId');
      
      final results = await _database.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE source_id = ? AND ang = ?
        ORDER BY id ASC
      ''', [sourceId, ang]));
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_ANG_FETCH_COMPLETE: Found ${results.length} verses in ${duration}ms');
      
      return results;
    } catch (e) {
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_ANG_FETCH_ERROR: $e');
      return [];
    }
  }

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

  Future<List<Map<String, dynamic>>> getHistory() async {
    return await _database.read((executor) => executor.runSelect('''
      SELECT * FROM search_history ORDER BY viewed_at_utc DESC
    ''', []));
  }

  Future<void> clearHistory() async {
    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM search_history');
    });
  }

  Future<ShabadNavigation> getShabadNavigation(String shabadId) async {
    final sId = int.tryParse(shabadId) ?? 0;
    if (sId == 0) return const ShabadNavigation();

    // Determine which DB to use
    final db = sId >= 999999 ? _nitnemDatabase : _database;

    try {
      final rows = await db.read((executor) => executor.runSelect(
        'SELECT source_id FROM shabads WHERE id = ?', [sId]
      ));

      if (rows.isEmpty) return const ShabadNavigation();
      final sourceId = rows.first['source_id'] as String;

      final prev = await db.read((executor) => executor.runSelect(
        'SELECT id FROM shabads WHERE source_id = ? AND id < ? ORDER BY id DESC LIMIT 1',
        [sourceId, sId]
      ));

      final next = await db.read((executor) => executor.runSelect(
        'SELECT id FROM shabads WHERE source_id = ? AND id > ? ORDER BY id ASC LIMIT 1',
        [sourceId, sId]
      ));

      return ShabadNavigation(
        previousId: prev.isNotEmpty ? prev.first['id'].toString() : null,
        nextId: next.isNotEmpty ? next.first['id'].toString() : null,
      );
    } catch (e) {
      return const ShabadNavigation();
    }
  }
}

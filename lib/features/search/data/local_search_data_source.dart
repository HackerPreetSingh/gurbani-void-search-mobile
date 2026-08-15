import '../../../core/database/local_database.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';

class LocalSearchDataSource {
  LocalSearchDataSource(this._database);
  final LocalDatabase _database;

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
    int limit = 40,
    String? orderBy,
  }) async {
    try {
      final orderClause = orderBy ?? '''
          (CASE WHEN source_id = 'G' THEN 0 ELSE 1 END) ASC,
          id ASC
      ''';

      return await _database.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE $condition
        ORDER BY $orderClause
        LIMIT ?
      ''', [...parameters, limit]));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocalShabad(String shabadId) async {
    // [AI_GUARD:PERMANENT_LOG] Fetching shabad by ID with strict liturgical ordering.
    // Note: We use 'id' for ordering because 'verse_order' from the API can reset 
    // mid-shabad, causing erratic sorting. Since verses are ingested sequentially, 
    // the primary key 'id' is the only reliable sort field.
    try {
      final sId = int.tryParse(shabadId) ?? 0;
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_FETCH_SHABAD: id=$sId');
      
      return await _database.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE shabad_id = ? 
        ORDER BY id ASC
      ''', [sId]));
    } catch (e) {
      print('[GURBANI_LOG] [${DateTime.now()}] [local_search_data_source.dart] DB_FETCH_ERROR: $e');
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
}

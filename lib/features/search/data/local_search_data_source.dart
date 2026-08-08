import '../../../core/database/local_database.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/services/gurmukhi_processor.dart';

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

  Future<List<Map<String, dynamic>>> search(String rawQuery, {int limit = 40}) async {
    final searchPattern = GurmukhiProcessor.queryToFirstLetterStr(rawQuery);
    if (searchPattern.isEmpty) return [];

    try {
      return await _database.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE first_letter_str LIKE ? 
        ORDER BY 
          (CASE WHEN source_id = 'G' THEN 0 ELSE 1 END) ASC,
          (CASE WHEN first_letter_str = ? THEN 0 ELSE 1 END) ASC,
          id ASC
        LIMIT ?
      ''', ['$searchPattern%', searchPattern, limit]));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocalShabad(String shabadId) async {
    try {
      return await _database.read((executor) => executor.runSelect('''
        SELECT *
        FROM verses
        WHERE shabad_id = ? ORDER BY verse_order ASC
      ''', [int.tryParse(shabadId) ?? 0]));
    } catch (_) {
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

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
    final rows = await _database.read(
      (executor) => executor.runSelect('''
        SELECT COUNT(*) as line_count FROM verses
      ''', const []),
    );
    final count = (rows.single['line_count'] as num).toInt();
    if (count == 0) return null;

    return GurbaniCorpusSummary(
      id: 'banidb-production',
      displayName: 'BaniDB Gurbani Corpus',
      version: '1.0.0',
      lineCount: count,
      attribution: 'BaniDB',
      importedAtUtc: DateTime.now(),
    );
  }

  @override
  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  }) async {
    var indexedCount = 0;

    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM verses');
      await executor.runCustom('DELETE FROM shabads');
      await executor.runCustom('DELETE FROM sources');
      await executor.runCustom('DELETE FROM writers');
      await executor.runCustom('DELETE FROM raags');

      await executor.runCustom("INSERT INTO sources (id, name_pa, name_en) VALUES ('G', 'ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ', 'Sri Guru Granth Sahib Ji')");
      await executor.runCustom("INSERT INTO writers (id, name_pa, name_en) VALUES (1, 'ਮਹਲਾ ੧', 'Guru Nanak Dev Ji')");
      await executor.runCustom("INSERT INTO raags (id, name_pa, name_en) VALUES (1, 'ਜਪੁ', 'Jap')");

      final insertShabadSql = 'INSERT INTO shabads (id, source_id, writer_id, raag_id, ang) VALUES (?, ?, ?, ?, ?)';
      final insertVerseSql = '''
        INSERT INTO verses (id, shabad_id, verse_order, gurmukhi, first_letter_str, transliteration, translation) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''';

      for (final line in lines) {
        final firstLetterStr = GurmukhiProcessor.generateFirstLetterStr(line.gurmukhi);
        final shabadId = 1; 

        try {
          await executor.runCustom(insertShabadSql, [shabadId, 'G', 1, 1, line.ang ?? 1]);
        } catch (_) {}

        await executor.runCustom(insertVerseSql, [
          indexedCount + 1,
          shabadId,
          line.displayOrder,
          line.gurmukhi,
          firstLetterStr,
          null,
          null,
        ]);
        indexedCount++;
      }
    });

    return CorpusImportReport(
      corpus: (await activeCorpus())!,
      indexedLineCount: indexedCount,
      indexedTokenCount: 0,
    );
  }

  @override
  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 40,
  }) async {
    if (!query.isSearchable) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.unsupportedQuery, query: query);
    }

    final corpus = await activeCorpus();
    if (corpus == null) {
      return PunjabiSearchResponse(status: PunjabiSearchStatus.noCorpus, query: query);
    }

    final searchCode = GurmukhiProcessor.queryToFirstLetterStr(query.raw);
    
    final rows = await _database.read((executor) => executor.runSelect('''
      SELECT 
        v.id, v.gurmukhi, v.verse_order,
        s.ang,
        src.name_pa as source_name,
        w.name_pa as writer_name,
        r.name_pa as raag_name
      FROM verses v
      JOIN shabads s ON v.shabad_id = s.id
      LEFT JOIN sources src ON s.source_id = src.id
      LEFT JOIN writers w ON s.writer_id = w.id
      LEFT JOIN raags r ON s.raag_id = r.id
      WHERE v.first_letter_str LIKE ?
      ORDER BY v.id ASC
      LIMIT ?
    ''', ['$searchCode%', limit]));

    final results = rows.map((row) => GurbaniSearchResult(
      stableId: (row['id'] as int).toString(),
      gurmukhi: row['gurmukhi'] as String,
      sourceName: row['source_name'] as String? ?? 'Unknown',
      writerName: row['writer_name'] as String?,
      raagName: row['raag_name'] as String?,
      ang: row['ang'] as int?,
      displayOrder: row['verse_order'] as int,
      match: SearchResultMatch.initial,
    )).toList();

    return PunjabiSearchResponse(
      status: PunjabiSearchStatus.complete,
      query: query,
      corpus: corpus,
      results: results,
    );
  }
}

import 'package:drift/drift.dart';

import '../../../core/database/local_database.dart';
import '../domain/models/gurbani_corpus.dart';
import '../domain/models/gurbani_search_result.dart';
import '../domain/models/punjabi_search_query.dart';
import '../domain/repositories/punjabi_search_repository.dart';
import '../domain/services/gurmukhi_search_text.dart';

class SqlitePunjabiSearchRepository implements PunjabiSearchRepository {
  SqlitePunjabiSearchRepository(this._database);

  static const _indexVersion = 1;
  static const _importBatchSize = 250;

  final LocalDatabase _database;

  @override
  Future<GurbaniCorpusSummary?> activeCorpus() async {
    final rows = await _database.read(
      (QueryExecutor executor) => executor.runSelect('''
        SELECT id, display_name, version, line_count, attribution,
               imported_at_utc
        FROM gurbani_corpora
        WHERE is_active = 1
        LIMIT 1
      ''', const []),
    );
    if (rows.isEmpty) {
      return null;
    }
    return _corpusFromRow(rows.single);
  }

  @override
  Future<CorpusImportReport> replaceCorpus({
    required GurbaniCorpusManifest manifest,
    required Iterable<GurbaniLineDraft> lines,
  }) async {
    _validateManifest(manifest);

    var indexedLineCount = 0;
    var indexedTokenCount = 0;
    final importedAtUtc = DateTime.now().toUtc();

    await _database.transaction((QueryExecutor executor) async {
      await executor.runCustom(
        'UPDATE gurbani_corpora SET is_active = 0 WHERE is_active = 1',
      );
      await executor.runCustom('DELETE FROM gurbani_corpora WHERE id = ?', [
        manifest.id,
      ]);
      await executor.runCustom(
        '''
          INSERT INTO gurbani_corpora (
            id, display_name, version, language_tag, source_url, license_url,
            attribution, content_sha256, imported_at_utc, line_count,
            index_version, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 1)
        ''',
        [
          manifest.id,
          manifest.displayName,
          manifest.version,
          manifest.languageTag,
          manifest.sourceUrl.toString(),
          manifest.licenseUrl.toString(),
          manifest.attribution,
          manifest.contentSha256.toLowerCase(),
          importedAtUtc.toIso8601String(),
          _indexVersion,
        ],
      );

      final lineRows = <List<Object?>>[];
      final tokenRows = <List<Object?>>[];

      Future<void> flushBatches() async {
        await _runBatch(executor, _insertLineSql, lineRows);
        await _runBatch(executor, _insertTokenSql, tokenRows);
      }

      for (final line in lines) {
        _validateLine(line);
        final tokens = GurmukhiSearchText.normalizedTokens(line.gurmukhi);
        if (tokens.isEmpty) {
          throw CorpusImportException(
            'Line "${line.stableId}" does not contain searchable Gurmukhi text.',
          );
        }

        lineRows.add([
          manifest.id,
          line.stableId.trim(),
          line.displayOrder,
          line.gurmukhi.trim(),
          tokens.join(' '),
          GurmukhiSearchText.initialsFromNormalizedTokens(tokens),
          line.sourceName.trim(),
          _nullableTrimmed(line.writerName),
          _nullableTrimmed(line.raagName),
          line.ang,
        ]);
        indexedLineCount += 1;

        for (var position = 0; position < tokens.length; position += 1) {
          tokenRows.add([
            manifest.id,
            line.stableId.trim(),
            position,
            tokens[position],
          ]);
          indexedTokenCount += 1;
        }

        if (lineRows.length >= _importBatchSize) {
          await flushBatches();
        }
      }
      await flushBatches();

      if (indexedLineCount != manifest.expectedLineCount) {
        throw CorpusImportException(
          'Manifest expects ${manifest.expectedLineCount} lines, but '
          '$indexedLineCount were supplied.',
        );
      }

      await executor.runCustom(
        'UPDATE gurbani_corpora SET line_count = ? WHERE id = ?',
        [indexedLineCount, manifest.id],
      );
    });

    return CorpusImportReport(
      corpus: GurbaniCorpusSummary(
        id: manifest.id,
        displayName: manifest.displayName,
        version: manifest.version,
        lineCount: indexedLineCount,
        attribution: manifest.attribution,
        importedAtUtc: importedAtUtc,
      ),
      indexedLineCount: indexedLineCount,
      indexedTokenCount: indexedTokenCount,
    );
  }

  @override
  Future<PunjabiSearchResponse> search(
    PunjabiSearchQuery query, {
    int limit = 40,
  }) async {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 100');
    }
    if (query.kind == PunjabiSearchKind.empty) {
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.emptyQuery,
        query: query,
      );
    }
    if (!query.isSearchable) {
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.unsupportedQuery,
        query: query,
      );
    }

    final corpus = await activeCorpus();
    if (corpus == null) {
      return PunjabiSearchResponse(
        status: PunjabiSearchStatus.noCorpus,
        query: query,
      );
    }

    final results = switch (query.kind) {
      PunjabiSearchKind.gurmukhiWord => _searchWords(corpus, query, limit),
      PunjabiSearchKind.gurmukhiInitial => _searchInitials(
        corpus,
        query,
        limit,
      ),
      PunjabiSearchKind.gurmukhiAmbiguous => _searchAmbiguous(
        corpus,
        query,
        limit,
      ),
      PunjabiSearchKind.empty || PunjabiSearchKind.unsupported =>
        Future<List<GurbaniSearchResult>>.value(const []),
    };

    return PunjabiSearchResponse(
      status: PunjabiSearchStatus.complete,
      query: query,
      corpus: corpus,
      results: await results,
    );
  }

  Future<List<GurbaniSearchResult>> _searchAmbiguous(
    GurbaniCorpusSummary corpus,
    PunjabiSearchQuery query,
    int limit,
  ) async {
    final words = await _searchWords(corpus, query, limit);
    if (words.length >= limit) {
      return words;
    }
    final initials = await _searchInitials(corpus, query, limit);
    final seen = words
        .map((GurbaniSearchResult result) => result.stableId)
        .toSet();
    return [
      ...words,
      ...initials.where(
        (GurbaniSearchResult result) => seen.add(result.stableId),
      ),
    ].take(limit).toList(growable: false);
  }

  Future<List<GurbaniSearchResult>> _searchInitials(
    GurbaniCorpusSummary corpus,
    PunjabiSearchQuery query,
    int limit,
  ) async {
    if (query.initialKey.isEmpty) {
      return const [];
    }
    final rows = await _database.read(
      (QueryExecutor executor) => executor.runSelect(
        '''
        SELECT stable_id, gurmukhi, source_name, writer_name, raag_name, ang,
               display_order
        FROM gurbani_lines
        WHERE corpus_id = ?
          AND initial_key >= ?
          AND initial_key < ?
        ORDER BY
          CASE WHEN initial_key = ? THEN 0 ELSE 1 END,
          LENGTH(initial_key) ASC,
          display_order ASC
        LIMIT ?
      ''',
        [
          corpus.id,
          query.initialKey,
          _prefixUpperBound(query.initialKey),
          query.initialKey,
          limit,
        ],
      ),
    );
    return rows
        .map(
          (Map<String, Object?> row) =>
              _resultFromRow(row, SearchResultMatch.initial),
        )
        .toList(growable: false);
  }

  Future<List<GurbaniSearchResult>> _searchWords(
    GurbaniCorpusSummary corpus,
    PunjabiSearchQuery query,
    int limit,
  ) async {
    if (query.wordTokens.isEmpty) {
      return const [];
    }

    final firstToken = query.wordTokens.first;
    final conditions = StringBuffer();
    final arguments = <Object?>[
      corpus.id,
      firstToken,
      _prefixUpperBound(firstToken),
      corpus.id,
    ];

    for (final token in query.wordTokens.skip(1)) {
      conditions.write('''
        AND EXISTS (
          SELECT 1
          FROM gurmukhi_token_postings remaining_token
          WHERE remaining_token.corpus_id = l.corpus_id
            AND remaining_token.line_stable_id = l.stable_id
            AND remaining_token.normalized_token >= ?
            AND remaining_token.normalized_token < ?
        )
      ''');
      arguments
        ..add(token)
        ..add(_prefixUpperBound(token));
    }

    final normalizedPhrase = query.wordTokens.join(' ');
    arguments
      ..add(normalizedPhrase)
      ..add(normalizedPhrase)
      ..add(_prefixUpperBound(normalizedPhrase))
      ..add(limit);

    final rows = await _database.read(
      (QueryExecutor executor) => executor.runSelect('''
        WITH first_matches AS (
          SELECT line_stable_id
          FROM gurmukhi_token_postings
          WHERE corpus_id = ?
            AND normalized_token >= ?
            AND normalized_token < ?
          GROUP BY line_stable_id
        )
        SELECT l.stable_id, l.gurmukhi, l.source_name, l.writer_name,
               l.raag_name, l.ang, l.display_order
        FROM first_matches
        INNER JOIN gurbani_lines l
          ON l.corpus_id = ?
          AND l.stable_id = first_matches.line_stable_id
        WHERE 1 = 1
          $conditions
        ORDER BY
          CASE
            WHEN l.normalized_gurmukhi = ? THEN 0
            WHEN l.normalized_gurmukhi >= ?
              AND l.normalized_gurmukhi < ? THEN 1
            ELSE 2
          END,
          l.display_order ASC
        LIMIT ?
      ''', arguments),
    );
    return rows
        .map(
          (Map<String, Object?> row) =>
              _resultFromRow(row, SearchResultMatch.word),
        )
        .toList(growable: false);
  }

  static Future<void> _runBatch(
    QueryExecutor executor,
    String statement,
    List<List<Object?>> rows,
  ) async {
    if (rows.isEmpty) {
      return;
    }
    await executor.runBatched(
      BatchedStatements(
        [statement],
        rows
            .map(
              (List<Object?> arguments) =>
                  ArgumentsForBatchedStatement(0, arguments),
            )
            .toList(growable: false),
      ),
    );
    rows.clear();
  }

  static GurbaniCorpusSummary _corpusFromRow(Map<String, Object?> row) {
    return GurbaniCorpusSummary(
      id: row['id']! as String,
      displayName: row['display_name']! as String,
      version: row['version']! as String,
      lineCount: row['line_count']! as int,
      attribution: row['attribution']! as String,
      importedAtUtc: DateTime.parse(row['imported_at_utc']! as String).toUtc(),
    );
  }

  static GurbaniSearchResult _resultFromRow(
    Map<String, Object?> row,
    SearchResultMatch match,
  ) {
    return GurbaniSearchResult(
      stableId: row['stable_id']! as String,
      gurmukhi: row['gurmukhi']! as String,
      sourceName: row['source_name']! as String,
      writerName: row['writer_name'] as String?,
      raagName: row['raag_name'] as String?,
      ang: row['ang'] as int?,
      displayOrder: row['display_order']! as int,
      match: match,
    );
  }

  static void _validateManifest(GurbaniCorpusManifest manifest) {
    if (manifest.id.trim().isEmpty ||
        manifest.displayName.trim().isEmpty ||
        manifest.version.trim().isEmpty ||
        manifest.languageTag.trim().isEmpty ||
        manifest.attribution.trim().isEmpty) {
      throw const CorpusImportException('Corpus metadata must not be empty.');
    }
    if (!_isHttpUrl(manifest.sourceUrl) || !_isHttpUrl(manifest.licenseUrl)) {
      throw const CorpusImportException(
        'Corpus source and licence must use an absolute HTTP(S) URL.',
      );
    }
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(manifest.contentSha256)) {
      throw const CorpusImportException(
        'Corpus contentSha256 must be a 64-character SHA-256 hex digest.',
      );
    }
    if (manifest.expectedLineCount < 1) {
      throw const CorpusImportException(
        'Corpus must contain at least one line.',
      );
    }
  }

  static void _validateLine(GurbaniLineDraft line) {
    if (line.stableId.trim().isEmpty ||
        line.gurmukhi.trim().isEmpty ||
        line.sourceName.trim().isEmpty) {
      throw const CorpusImportException(
        'Every line requires an id, Gurmukhi text, and source name.',
      );
    }
    if (line.displayOrder < 0) {
      throw CorpusImportException(
        'Line "${line.stableId}" has a negative display order.',
      );
    }
    if (line.ang != null && line.ang! < 1) {
      throw CorpusImportException(
        'Line "${line.stableId}" has an invalid Ang number.',
      );
    }
  }

  static bool _isHttpUrl(Uri uri) =>
      uri.isAbsolute && (uri.scheme == 'https' || uri.scheme == 'http');

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _prefixUpperBound(String prefix) => '$prefix\uffff';

  static const _insertLineSql = '''
    INSERT INTO gurbani_lines (
      corpus_id, stable_id, display_order, gurmukhi, normalized_gurmukhi,
      initial_key, source_name, writer_name, raag_name, ang
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const _insertTokenSql = '''
    INSERT INTO gurmukhi_token_postings (
      corpus_id, line_stable_id, token_position, normalized_token
    ) VALUES (?, ?, ?, ?)
  ''';
}

class CorpusImportException implements Exception {
  const CorpusImportException(this.message);

  final String message;

  @override
  String toString() => 'Corpus import failed: $message';
}

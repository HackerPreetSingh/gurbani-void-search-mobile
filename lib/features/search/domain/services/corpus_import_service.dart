import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../models/gurbani_corpus.dart';
import '../repositories/punjabi_search_repository.dart';

class CorpusImportService {
  CorpusImportService(this._repository);

  final PunjabiSearchRepository _repository;

  Future<CorpusImportReport> importFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final manifestData = data['manifest'] as Map<String, dynamic>;
    final manifest = GurbaniCorpusManifest(
      id: manifestData['id'] as String,
      displayName: manifestData['displayName'] as String,
      version: manifestData['version'] as String,
      languageTag: manifestData['languageTag'] as String,
      sourceUrl: Uri.parse(manifestData['sourceUrl'] as String),
      licenseUrl: Uri.parse(manifestData['licenseUrl'] as String),
      attribution: manifestData['attribution'] as String,
      contentSha256: manifestData['contentSha256'] as String,
      expectedLineCount: manifestData['expectedLineCount'] as int,
    );

    final linesData = data['lines'] as List<dynamic>;
    final lines = linesData.map((e) {
      final line = e as Map<String, dynamic>;
      return GurbaniLineDraft(
        stableId: line['stableId'] as String,
        displayOrder: line['displayOrder'] as int,
        gurmukhi: line['gurmukhi'] as String,
        sourceName: line['sourceName'] as String,
        writerName: line['writerName'] as String?,
        raagName: line['raagName'] as String?,
        ang: line['ang'] as int?,
      );
    });

    return _repository.replaceCorpus(
      manifest: manifest,
      lines: lines,
    );
  }

  Future<CorpusImportReport> importFromBaniDbSnapshot(String sqlitePath) async {
    final db = sqlite.sqlite3.open(sqlitePath);

    try {
      // Standard production schema (BaniDB API style)
      final rows = db.select('''
        SELECT 
          v.ID as stableId,
          v.GurmukhiUni as gurmukhi,
          v.LineNo as displayOrder,
          src.SourceUnicode as sourceName,
          w.WriterUnicode as writerName,
          r.RaagUnicode as raagName,
          v.PageNo as ang
        FROM Verse v
        LEFT JOIN Source src ON v.SourceID = src.SourceID
        LEFT JOIN Writer w ON v.WriterID = w.WriterID
        LEFT JOIN Raag r ON v.RaagID = r.RaagID
      ''');

      final manifest = GurbaniCorpusManifest(
        id: 'banidb-full',
        displayName: 'BaniDB Full Corpus',
        version: '1.0.0',
        languageTag: 'pa',
        sourceUrl: Uri.parse('https://api.banidb.com'),
        licenseUrl: Uri.parse('https://www.banidb.com/tos/'),
        attribution: 'BaniDB Contributors',
        contentSha256: '00000000',
        expectedLineCount: rows.length,
      );

      final lines = rows.map((row) {
        return GurbaniLineDraft(
          stableId: (row['stableId'] as int).toString(),
          displayOrder: row['displayOrder'] as int? ?? 0,
          gurmukhi: row['gurmukhi'] as String? ?? '',
          sourceName: row['sourceName'] as String? ?? 'Unknown',
          writerName: row['writerName'] as String?,
          raagName: row['raagName'] as String?,
          ang: row['ang'] as int?,
        );
      });

      return await _repository.replaceCorpus(
        manifest: manifest,
        lines: lines,
      );
    } finally {
      db.close();
    }
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';

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
}

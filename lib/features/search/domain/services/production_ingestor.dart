import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:gurbani_voice_search/core/database/local_database.dart';
import 'gurmukhi_processor.dart';

/// Highly resilient ingestor that uses the /angs endpoint for maximum speed.
class ProductionIngestor {
  ProductionIngestor(this._database);

  final LocalDatabase _database;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  static const _apiBaseUrl = 'https://api.banidb.com/v2';
  static const _angsPerBatch = 20; // Smaller batches for better server stability
  static const _totalAngs = 1430;

  Future<void> buildOfflineDatabase({
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
  }) async {
    onStatus('Preparing database...');

    await _database.transaction((executor) async {
      await executor.runCustom('PRAGMA foreign_keys = OFF');
      await executor.runCustom('DELETE FROM verses');
      await executor.runCustom('DELETE FROM shabads');
      await executor.runCustom('DELETE FROM sources');
      await executor.runCustom('DELETE FROM writers');
      await executor.runCustom('DELETE FROM raags');
    });

    int processedLines = 0;

    for (int startAng = 1; startAng <= _totalAngs; startAng += _angsPerBatch) {
      final endAng = (startAng + _angsPerBatch - 1).clamp(1, _totalAngs);
      onStatus('Downloading Angs $startAng to $endAng...');

      try {
        final response = await _dio.get('$_apiBaseUrl/angs/$startAng-$endAng/G');
        
        final dynamic data = response.data;
        if (data == null || data is! Map) continue;
        
        final List<dynamic> pages = data['pages'] ?? [];
        if (pages.isEmpty) continue;

        await _database.transaction((executor) async {
          final verseBatch = <List<Object?>>[];
          const verseSql = 'INSERT INTO verses (id, shabad_id, verse_order, gurmukhi, first_letter_str, transliteration, translation) VALUES (?, ?, ?, ?, ?, ?, ?)';

          for (final p in pages) {
            final Map<String, dynamic> pageData = p as Map<String, dynamic>;
            final List<dynamic> verses = pageData['page'] ?? [];
            
            for (final v in verses) {
              final Map<String, dynamic> verse = v as Map<String, dynamic>;
              
              // SAFELY parse IDs
              final shId = _toInt(verse['shabadId'] ?? verse['shabadID']);
              final vId = _toInt(verse['verseId'] ?? verse['id'] ?? verse['ID']);
              final gurmukhi = verse['verse']?['unicode'] ?? verse['gurmukhi'] ?? '';
              
              if (gurmukhi.isEmpty || shId == null || vId == null) continue;

              await _insertMetadataFromVerse(executor, verse);
              
              await executor.runCustom(
                'INSERT OR IGNORE INTO shabads (id, source_id, writer_id, raag_id, ang) VALUES (?, ?, ?, ?, ?)',
                [
                  shId,
                  verse['source']?['sourceId']?.toString() ?? 'G',
                  _toInt(verse['writer']?['writerId'] ?? verse['writer']?['id']),
                  _toInt(verse['raag']?['raagId'] ?? verse['raag']?['id']),
                  _toInt(verse['pageNo'] ?? verse['source']?['pageNo'])
                ],
              );

              final firstLetterStr = GurmukhiProcessor.generateFirstLetterStr(gurmukhi);

              verseBatch.add([
                vId,
                shId,
                _toInt(verse['lineNo'] ?? verse['LineNo']) ?? 0,
                gurmukhi,
                firstLetterStr,
                verse['transliteration']?['english'],
                verse['translation']?['en']?['bdb']
              ]);
              processedLines++;
            }
          }
          
          if (verseBatch.isNotEmpty) {
            await executor.runBatched(BatchedStatements(
              [verseSql],
              verseBatch.map((b) => ArgumentsForBatchedStatement(0, b)).toList(),
            ));
          }
        });

        onProgress(endAng / _totalAngs);
        onStatus('Syncing... $processedLines lines saved');
        
      } catch (e) {
        // Continue to next batch
      }
    }

    await _database.read((executor) => executor.runCustom('PRAGMA foreign_keys = ON'));
    onStatus('Offline engine is ready!');
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _insertMetadataFromVerse(QueryExecutor executor, Map<String, dynamic> v) async {
    final source = v['source'];
    if (source != null && source['sourceId'] != null) {
      await executor.runCustom(
        'INSERT OR IGNORE INTO sources (id, name_pa, name_en) VALUES (?, ?, ?)',
        [source['sourceId'].toString(), source['unicode'] ?? source['english'] ?? 'Unknown', source['english'] ?? 'Unknown']
      );
    }
    final writer = v['writer'];
    if (writer != null && (writer['writerId'] ?? writer['id']) != null) {
      await executor.runCustom(
        'INSERT OR IGNORE INTO writers (id, name_pa, name_en) VALUES (?, ?, ?)',
        [_toInt(writer['writerId'] ?? writer['id']), writer['unicode'] ?? writer['english'] ?? 'Unknown', writer['english'] ?? 'Unknown']
      );
    }
    final raag = v['raag'];
    if (raag != null && (raag['raagId'] ?? raag['id']) != null) {
      await executor.runCustom(
        'INSERT OR IGNORE INTO raags (id, name_pa, name_en) VALUES (?, ?, ?)',
        [_toInt(raag['raagId'] ?? raag['id']), raag['unicode'] ?? raag['english'] ?? 'Unknown', raag['english'] ?? 'Unknown']
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:gurbani_voice_search/core/database/local_database.dart';
import 'gurmukhi_processor.dart';

/// A heavy-duty sync engine built for production-grade Gurbani indexing.
class ProductionIngestor {
  ProductionIngestor(this._database);

  final LocalDatabase _database;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 150),
    validateStatus: (status) => status! < 500,
  ));

  static const _baseUrl = 'https://api.banidb.com/v2';

  Future<void> buildOfflineDatabase({
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
  }) async {
    onStatus('Initializing setup...');
    
    final sourcesRes = await _dio.get('$_baseUrl/sources');
    final List sourceList = sourcesRes.data['rows'] ?? [];

    int totalSynced = 0;
    int totalSources = sourceList.length;

    for (int i = 0; i < totalSources; i++) {
      final src = sourceList[i];
      final String sId = src['SourceID'];
      final String sName = src['SourceUnicode'] ?? src['SourceEnglish'];

      onStatus('Syncing: $sName...');
      
      await _database.transaction((executor) async {
        await executor.runCustom('INSERT OR IGNORE INTO sources VALUES (?, ?, ?)', 
            [sId, sName, src['SourceEnglish']]);
      });

      int currentAng = 1;
      int emptyBatches = 0;

      while (emptyBatches < 3) {
        final batchSize = 20;
        try {
          final response = await _dio.get('$_baseUrl/angs/$currentAng-${currentAng + batchSize - 1}/$sId');
          if (response.statusCode != 200) break;

          final pages = response.data['pages'] as List?;
          if (pages == null || pages.isEmpty) {
            emptyBatches++;
            currentAng += batchSize;
            continue;
          }
          emptyBatches = 0;

          await _database.transaction((executor) async {
            final verseBatch = <List<Object?>>[];
            const verseSql = 'INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';

            for (final p in pages) {
              if (p['source']?['sourceId'] != sId) continue;
              for (final v in (p['page'] as List)) {
                final shId = _toInt(v['shabadId']);
                final vId = _toInt(v['verseId']);
                if (shId == null || vId == null) continue;

                await _saveMeta(executor, 'writers', v['writer'], 'writerId');
                await _saveMeta(executor, 'raags', v['raag'], 'raagId');
                
                await executor.runCustom('INSERT OR REPLACE INTO shabads VALUES (?, ?, ?, ?, ?)', 
                    [shId, sId, _toInt(v['writer']?['writerId']), _toInt(v['raag']?['raagId']), _toInt(v['pageNo'])]);

                final gur = v['verse']?['unicode'] ?? v['gurmukhi'] ?? '';
                final flStr = GurmukhiProcessor.generateFirstLetterStr(gur);
                final hi = v['transliteration']?['hindi'] ?? v['transliteration']?['hi'];

                verseBatch.add([vId, shId, _toInt(v['lineNo']) ?? 0, gur, v['transliteration']?['english'], hi, v['translation']?['en']?['bdb'], flStr, null]);
                totalSynced++;
              }
            }
            if (verseBatch.isNotEmpty) {
              await executor.runBatched(BatchedStatements([verseSql], 
                verseBatch.map((b) => ArgumentsForBatchedStatement(0, b)).toList()));
            }
          });

          onProgress((i + (currentAng / 1500)) / totalSources);
          currentAng += batchSize;
        } catch (e) {
          break;
        }
      }
    }
    onStatus('Setup Complete! $totalSynced lines ready.');
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

  Future<void> _saveMeta(QueryExecutor executor, String table, Map? data, String idKey) async {
    if (data == null) return;
    final id = _toInt(data[idKey] ?? data['id']);
    if (id == null) return;
    final pbi = data['unicode'] ?? data['english'] ?? 'Unknown';
    final eng = data['english'] ?? 'Unknown';
    await executor.runCustom('INSERT OR REPLACE INTO $table VALUES (?, ?, ?)', [id, pbi, eng]);
  }
}

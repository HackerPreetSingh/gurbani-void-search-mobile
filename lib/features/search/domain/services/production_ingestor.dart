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
            const verseSql = 'INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';

            for (final pageData in pages) {
              final pSource = pageData['source'];
              final pageSourceId = (pSource is Map ? (pSource['sourceId'] ?? pSource['id']) : (pageData['sourceId'] ?? pageData['id']))?.toString();
              
              if (pageSourceId != null && pageSourceId.toUpperCase() != sId.toUpperCase()) continue;
              
              final List verses = pageData['page'] ?? pageData['verses'] ?? [];
              for (final v in verses) {
                final shId = _toInt(v['shabadId']);
                final vId = _toInt(v['verseId']);
                if (shId == null || vId == null) continue;

                await _saveMeta(executor, 'writers', v['writer'], 'writerId');
                await _saveMeta(executor, 'raags', v['raag'], 'raagId');
                
                await executor.runCustom('INSERT OR REPLACE INTO shabads VALUES (?, ?, ?, ?, ?)', 
                    [shId, sId, _toInt(v['writer']?['writerId']), _toInt(v['raag']?['raagId']), _toInt(v['pageNo'])]);

                final gur = _val(v['verse']?['unicode'] ?? v['gurmukhi'] ?? v['verse'] ?? '');
                final hi = _val(v['transliteration']?['hindi'] ?? v['transliteration']?['hi'] ?? v['transliteration']?['hi_text']);
                final en = _val(v['transliteration']?['english'] ?? v['transliteration']?['en'] ?? v['transliteration']?['en_text']);
                final transEn = _val(v['translation']?['en']?['bdb'] ?? v['translation']?['en']?['combined'] ?? v['translation']?['en']?['text'] ?? v['translation']?['en']);
                final transPa = _val(v['translation']?['pu']?['ss'] ?? v['translation']?['pu']?['ft'] ?? v['translation']?['pu']?['text'] ?? v['translation']?['pu']);
                
                final wId = _toInt(v['writer']?['writerId'] ?? v['writerId'] ?? v['writer_id']);
                final rId = _toInt(v['raag']?['raagId'] ?? v['raagId'] ?? v['raag_id']);
                final ang = _toInt(v['pageNo'] ?? v['ang'] ?? v['page_no']);

                verseBatch.add([
                  vId, 
                  shId, 
                  _toInt(v['lineNo']) ?? _toInt(v['verseNo']) ?? 0, 
                  gur, 
                  en, 
                  hi, 
                  transEn, 
                  transPa,
                  GurmukhiProcessor.generateFirstLetterStr(gur), 
                  null, // main_letters
                  null, // visraams
                  sId, 
                  rId, 
                  wId, 
                  ang
                ]);
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
          currentAng += 20;
          continue;
        }
      }
    }
    onStatus('Setup Complete! $totalSynced lines ready.');
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

  String _val(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      final value = v['unicode'] ?? v['english'] ?? v['text'] ?? v['text_hi'] ?? v['text_en'];
      if (value != null) return value.toString();
      if (v.values.isNotEmpty) return v.values.first.toString();
    }
    return v.toString();
  }

  Future<void> _saveMeta(QueryExecutor executor, String table, Map? data, String idKey) async {
    if (data == null) return;
    final id = _toInt(data[idKey] ?? data['id'] ?? data['${table.substring(0, table.length - 1)}_id']);
    if (id == null) return;
    final pbi = _val(data['unicode'] ?? data['english'] ?? data['gurmukhi'] ?? data['name']);
    final eng = _val(data['english'] ?? data['unicode'] ?? data['gurmukhi'] ?? data['name']);
    await executor.runCustom('INSERT OR REPLACE INTO $table VALUES (?, ?, ?)', [id, pbi, eng]);
  }
}

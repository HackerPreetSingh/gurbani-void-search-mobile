import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../../../core/constants/app_constants.dart';
import 'shabad_sync_service.dart';

class BaniSyncService {
  final Database db;
  final Dio dio;
  final String baseUrl;
  final ShabadSyncService _shabadSyncService;

  BaniSyncService({
    required this.db,
    required this.dio,
    required this.baseUrl,
  }) : _shabadSyncService = ShabadSyncService(db: db, dio: dio, baseUrl: baseUrl);

  Future<void> syncAllBanis(Function(int) onUpdate) async {
    // [AI_GUARD:PERMANENT_LOG] Starting master bani sync. Do not remove or modify.
    print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_START: Fetching master list');
    try {
      final res = await dio.get('$baseUrl/banis');
      final rows = res.data as List;
      print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_INFO: Found ${rows.length} Banis to process.');

      int currentOrder = 0;
      for (final row in rows) {
        final bId = row['ID'];
        final bNamePa = row['gurmukhiUni'] ?? row['gurmukhi'];
        final bNameEn = row['transliterations']?['english'] ?? row['transliteration'];
        
        print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_DETAIL: Processing Bani $bId: $bNameEn');
        
        db.execute('INSERT OR REPLACE INTO banis (id, name_pa, name_en, user_order, updated_at) VALUES (?, ?, ?, ?, ?)', 
            [bId, bNamePa, bNameEn, currentOrder++, row['updated']]);

        print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_DETAIL: Fetching verses for Bani $bId');
        final detailRes = await dio.get('$baseUrl/banis/$bId');
        final verses = detailRes.data['verses'] as List;

        db.execute('BEGIN TRANSACTION');
        int baniLineCount = 0;
        for (int i = 0; i < verses.length; i++) {
          final vData = verses[i];
          final verseRaw = vData['verse'];
          final vId = verseRaw['verseId'];
          
          await _shabadSyncService.processVerse(verseRaw, 'Bani', 0);

          // [AI_GUARD:PERMANENT_LOG] Mapping verse to bani sequence with robust type conversion
          db.execute('''
            INSERT OR REPLACE INTO bani_verses (
              bani_id, verse_id, sequence_order, header, mangal_position, 
              exists_sgpc, exists_medium, exists_taksal, exists_buddha_dal, paragraph
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            bId,
            vId,
            i,
            _toInt(vData['header']),
            _toInt(vData['mangalPosition']),
            _toInt(vData['existsSGPC']),
            _toInt(vData['existsMedium']),
            _toInt(vData['existsTaksal']),
            _toInt(vData['existsBuddhaDal']),
            _toInt(vData['paragraph'])
          ]);
          onUpdate(1);
          baniLineCount++;
        }
        db.execute('COMMIT');
        print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_SUCCESS: Completed Bani $bId. Lines added: $baniLineCount');
      }
      print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_COMPLETE');
    } catch (e) {
      print('${AppConstants.logTag} [${DateTime.now()}] [bani_sync_service.dart] BANI_SYNC_FATAL_ERROR: $e');
      rethrow;
    }
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
}

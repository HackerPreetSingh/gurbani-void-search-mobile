import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:gurbani_voice_search/core/constants/app_constants.dart';
import 'package:gurbani_voice_search/features/search/domain/services/shabad_sync_service.dart';

void main() async {
  // [AI_GUARD:PERMANENT_LOG] Entry point for Shabad Sync Utility
  final methodStart = DateTime.now();
  final dbPath = 'assets/database/${AppConstants.shabadDbFile}';
  print('${AppConstants.logTag} [$methodStart] [sync_shabads.dart] START: Shabad Sync Engine');

  final dir = Directory('assets/database');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File(dbPath);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(dbPath);
  
  // Setup Schema
  db.execute('CREATE TABLE sources (id TEXT PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE writers (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE raags (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE shabads (id INTEGER PRIMARY KEY, source_id TEXT, writer_id INTEGER, raag_id INTEGER, ang INTEGER)');
  db.execute('CREATE TABLE verses (id INTEGER PRIMARY KEY, shabad_id INTEGER, verse_order INTEGER, gurmukhi TEXT, transliteration TEXT, transliteration_hi TEXT, translation TEXT, translation_pa TEXT, first_letter_str TEXT, initials_en TEXT, initials_pa TEXT, main_letters TEXT, visraams TEXT, source_id TEXT, raag_id INTEGER, writer_id INTEGER, ang INTEGER)');
  
  db.execute('CREATE INDEX idx_verses_sid ON verses (shabad_id)');
  db.execute('CREATE INDEX idx_shabads_src ON shabads (source_id)');
  db.execute('CREATE INDEX idx_verses_initials_en ON verses (initials_en)');
  db.execute('CREATE INDEX idx_verses_initials_pa ON verses (initials_pa)');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 120),
    validateStatus: (status) => status! < 500, 
  ));

  const baseUrl = AppConstants.banidbBaseUrl;
  final syncService = ShabadSyncService(db: db, dio: dio, baseUrl: baseUrl, dbPath: dbPath);

  print('🔍 Fetching master source list...');
  final sourceListRes = await dio.get('$baseUrl/sources');
  final sourceList = sourceListRes.data['rows'] as List;

  int totalSynced = 0;
  for (final src in sourceList) {
    final sId = (src['SourceID'] ?? src['id']) as String;
    final sName = (src['SourceUnicode'] ?? src['SourceEnglish']) as String;
    db.execute('INSERT OR IGNORE INTO sources VALUES (?, ?, ?)', [sId, sName, src['SourceEnglish']]);

    if (sId == 'A') {
      print('\n📥 SYNCING: $sName [$sId] via Specialized Header Index...');
      await _syncSourceALegacy(db, dio, baseUrl, sId, (count) => totalSynced += count, dbPath);
      continue;
    }

    print('\n📥 SYNCING: $sName [$sId]');
    await syncService.syncStandardSource(sId, sName, totalSynced, (count) => totalSynced += count);
    print('\n✨ Source $sId complete. Global total: $totalSynced');
  }
  
  db.close();
  print('\n\n🏁 SHABAD SYNC COMPLETE! Total: $totalSynced');
}

Future<void> _syncSourceALegacy(Database db, Dio dio, String baseUrl, String sId, Function(int) onSynced, String dbPath) async {
  final shabadSync = ShabadSyncService(db: db, dio: dio, baseUrl: baseUrl, dbPath: dbPath);
  try {
    final headersRes = await dio.get('$baseUrl/amritkeertan');
    final headers = headersRes.data['headers'] as List;
    
    for (final header in headers) {
      final headerId = header['HeaderID'];
      final headerText = header['GurmukhiUni'] ?? header['Gurmukhi'];
      int headerLineCount = 0;
      
      final indexRes = await dio.get('$baseUrl/amritkeertan/index/$headerId');
      final shabads = indexRes.data['index'] as List;
      final allShabadIds = shabads.map((s) => s['ShabadID']).where((id) => id != null).toList();
      
      const shabadBatchSize = 40;
      for (int i = 0; i < allShabadIds.length; i += shabadBatchSize) {
        final chunkIds = allShabadIds.skip(i).take(shabadBatchSize).join(',');
        
        final res = await _fetchWithRetry(dio, '$baseUrl/shabads/$chunkIds');
        if (res == null) continue;
        
        final List shabadList = res['shabads'] ?? [];
        db.execute('BEGIN TRANSACTION');
        for (var shabadData in shabadList) {
          final shId = _toInt(shabadData['shabadInfo']?['shabadId']);
          final List verses = shabadData['verses'] ?? [];
          for (final v in verses) {
            await shabadSync.processVerse(v, sId, shId ?? 0, info: shabadData['shabadInfo']);
            onSynced(1);
            headerLineCount++;
          }
        }
        db.execute('COMMIT');
      }
      print('  ✅ Completed Header $headerId ($headerText). Added $headerLineCount lines.');
    }
  } catch (e) {
    print('  ❌ FAIL: Source A failed: $e');
  }
}

Future<Map<String, dynamic>?> _fetchWithRetry(Dio dio, String url) async {
  for (int i = 0; i < 3; i++) {
    try {
      final res = await dio.get(url);
      if (res.statusCode == 200) return res.data;
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 1));
  }
  return null;
}

int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

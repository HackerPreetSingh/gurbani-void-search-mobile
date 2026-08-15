import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:gurbani_voice_search/core/constants/app_constants.dart';
import 'package:gurbani_voice_search/features/search/domain/services/bani_sync_service.dart';

void main() async {
  // [AI_GUARD:PERMANENT_LOG] Entry point for Bani Sync Utility
  final methodStart = DateTime.now();
  final dbPath = 'assets/database/${AppConstants.nitnemDbFile}';
  print('${AppConstants.logTag} [$methodStart] [sync_banis.dart] START: Nitnem/Bani Sync Utility');

  final dir = Directory('assets/database');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File(dbPath);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(dbPath);
  
  // Setup Schema for Nitnem DB
  db.execute('CREATE TABLE sources (id TEXT PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE writers (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE raags (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE shabads (id INTEGER PRIMARY KEY, source_id TEXT, writer_id INTEGER, raag_id INTEGER, ang INTEGER)');
  db.execute('CREATE TABLE verses (id INTEGER PRIMARY KEY, shabad_id INTEGER, verse_order INTEGER, gurmukhi TEXT, transliteration TEXT, transliteration_hi TEXT, translation TEXT, translation_pa TEXT, first_letter_str TEXT, initials_en TEXT, initials_pa TEXT, main_letters TEXT, visraams TEXT, source_id TEXT, raag_id INTEGER, writer_id INTEGER, ang INTEGER)');
  db.execute('CREATE TABLE banis (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL, user_order INTEGER, updated_at TEXT)');
  db.execute('CREATE TABLE bani_verses (id INTEGER PRIMARY KEY AUTOINCREMENT, bani_id INTEGER NOT NULL, verse_id INTEGER NOT NULL, sequence_order INTEGER NOT NULL, header INTEGER, mangal_position INTEGER, exists_sgpc INTEGER, exists_medium INTEGER, exists_taksal INTEGER, exists_buddha_dal INTEGER, paragraph INTEGER)');
  
  db.execute('CREATE INDEX idx_verses_sid ON verses (shabad_id)');
  db.execute('CREATE INDEX idx_shabads_src ON shabads (source_id)');
  db.execute('CREATE INDEX idx_verses_initials_en ON verses (initials_en)');
  db.execute('CREATE INDEX idx_bani_verses_bani ON bani_verses (bani_id)');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 120),
    validateStatus: (status) => status! < 500,
  ));

  const baseUrl = AppConstants.banidbBaseUrl;
  final syncService = BaniSyncService(db: db, dio: dio, baseUrl: baseUrl);

  int syncedCount = 0;
  try {
    await syncService.syncAllBanis((count) {
      syncedCount += count;
    });
    print('\n✨ BANI SYNC COMPLETE! Total database mapping lines: $syncedCount');
  } catch (e) {
    print('\n❌ FAIL FAST: Bani sync aborted: $e');
  } finally {
    db.close();
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:gurbani_voice_search/core/constants/app_constants.dart';
import 'package:gurbani_voice_search/features/search/domain/services/bani_sync_service.dart';

void main() async {
  // [AI_GUARD:PERMANENT_LOG] Entry point for Bani Sync Utility
  final methodStart = DateTime.now();
  final dbPath = 'assets/database/${AppConstants.dbFileName}';
  print('${AppConstants.logTag} [$methodStart] [sync_banis.dart] START: Nitnem/Bani Sync Utility');

  if (!File(dbPath).existsSync()) {
    print('❌ Database not found at $dbPath. Please run sync_shabads.dart first to create the base schema.');
    return;
  }

  final db = sqlite3.open(dbPath);
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

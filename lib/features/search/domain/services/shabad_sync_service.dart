import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:characters/characters.dart';
import '../../../../core/constants/app_constants.dart';
import 'gurmukhi_processor.dart';

class ShabadSyncService {
  final Database db;
  final Dio dio;
  final String baseUrl;
  final String dbPath;

  ShabadSyncService({
    required this.db,
    required this.dio,
    required this.baseUrl,
    required this.dbPath,
  });

  Future<void> syncStandardSource(String sId, String sName, int totalSynced, Function(int) onUpdate) async {
    // [AI_GUARD:PERMANENT_LOG] Tracking source sync start
    print('${AppConstants.logTag} [${DateTime.now()}] [shabad_sync_service.dart] SYNC_SOURCE_START: $sName [$sId]');
    
    // Use precise book lengths to avoid thousands of wasted 404 requests
    const sourceMaxAngs = {'G': 1430, 'D': 1428, 'B': 40, 'S': 1, 'N': 100, 'R': 50};
    final int maxAng = sourceMaxAngs[sId] ?? 5000;
    
    int currentAng = 1;
    int consecutiveEmpty = 0;
    
    // For primary sources like SGGS, we must ensure we check EVERY page.
    // Gaps in API data should not cause the sync to abort prematurely.
    int maxEmptyBatches = (sId == 'G') ? 1430 : 25; 
    
    // SGGS is large, so we use a balanced parallelism to avoid network choking.
    final int parallelism = (sId == 'G') ? 20 : 40;

    while (currentAng <= maxAng && (sId == 'G' || consecutiveEmpty < maxEmptyBatches)) {
      try {
        // [AI_GUARD:PERMANENT_LOG] Tracking batch requests
        print('${AppConstants.logTag} [${DateTime.now()}] [shabad_sync_service.dart] SYNC_BATCH_REQUEST: $sId Ang $currentAng to ${currentAng + parallelism - 1}');
        final angsToFetch = <int>[];
        for (int i = 0; i < parallelism && (currentAng + i <= maxAng); i++) {
          angsToFetch.add(currentAng + i);
        }

        final futures = angsToFetch.map((ang) => _fetchAngWithRetry('$baseUrl/angs/$ang/$sId'));
        final responses = await Future.wait(futures);

        db.execute('BEGIN TRANSACTION');
        int batchCount = 0;
        bool foundAnyData = false;

        for (int idx = 0; idx < responses.length; idx++) {
          final response = responses[idx];
          if (response == null) continue;
          
          final List verses = response['page'] ?? response['verses'] ?? [];
          if (verses.isEmpty) continue;

          foundAnyData = true;
          for (final v in verses) {
            final shId = _toInt(v['shabadId'] ?? v['ShabadID']);
            if (shId == null) continue;
            await processVerse(v, sId, shId);
            batchCount++;
            onUpdate(1);
          }
        }
        db.execute('COMMIT');

        if (foundAnyData) {
          consecutiveEmpty = 0;
          // [AI_GUARD:PERMANENT_LOG] Successful batch processing
          print('${AppConstants.logTag} [${DateTime.now()}] [shabad_sync_service.dart] SYNC_BATCH_SUCCESS: $sId Ang $currentAng. Lines added: $batchCount. Global Total: $totalSynced');
        } else {
          consecutiveEmpty++;
          print('${AppConstants.logTag} [${DateTime.now()}] [shabad_sync_service.dart] SYNC_BATCH_EMPTY: No data found in this batch of $sId. Progress: $currentAng/$maxAng');
        }
      } catch (e) {
        print('${AppConstants.logTag} [shabad_sync_service.dart] BATCH_FATAL_ERROR: $e. Skipping range $currentAng to ${currentAng + parallelism}');
        // Ensure transaction is closed if it was open
        try { db.execute('ROLLBACK'); } catch (_) {}
      }
      currentAng += parallelism;
    }
    // [AI_GUARD:PERMANENT_LOG] Source sync complete
    print('${AppConstants.logTag} [${DateTime.now()}] [shabad_sync_service.dart] SYNC_SOURCE_COMPLETE: $sId. Total Lines in DB: $totalSynced');
  }

  Future<void> processVerse(Map v, String sId, int shId, {Map? info}) async {
    // [AI_GUARD:PERMANENT_LOG] Processing individual verse mapping. Do not remove.
    final vId = _toInt(v['verseId'] ?? v['id'] ?? v['ID'] ?? v['VerseID']);
    if (vId == null) {
       print('${AppConstants.logTag} [${DateTime.now()}] [shabad_sync_service.dart] WARN: Verse mapping skipped, null vId');
       return;
    }

    _saveMeta('writers', v['writer'] ?? info?['writer'], 'writerId');
    _saveMeta('raags', v['raag'] ?? info?['raag'], 'raagId');

    final ang = _toInt(v['pageNo'] ?? v['ang'] ?? v['PageNo'] ?? info?['pageNo'] ?? info?['ang']);
    
    // [AI_GUARD:PERMANENT_LOG] Ensuring shabad record exists. 
    // If shId is 0 or virtual (>999999), we still maintain a link for referential integrity.
    db.execute('INSERT OR REPLACE INTO shabads (id, source_id, writer_id, raag_id, ang) VALUES (?, ?, ?, ?, ?)', [
      shId,
      sId,
      _toInt(v['writer']?['writerId'] ?? info?['writer']?['writerId']),
      _toInt(v['raag']?['raagId'] ?? info?['raag']?['raagId']),
      ang
    ]);

    final gur = _val(v['verse']?['unicode'] ?? v['gurmukhi'] ?? v['GurmukhiUni'] ?? v['Gurmukhi'] ?? '');
    final hi = _val(v['transliteration']?['hindi'] ?? v['transliteration']?['hi'] ?? v['Transliterations']?['hi']);
    final en = _val(v['transliteration']?['english'] ?? v['transliteration']?['en'] ?? v['Transliterations']?['en']);
    final transEn = _val(v['translation']?['en']?['bdb'] ?? v['translation']?['en']?['text'] ?? v['Translations']?['en']?['bdb']);
    final transPa = _val(v['translation']?['pu']?['ss'] ?? v['translation']?['pu']?['text'] ?? v['Translations']?['pu']?['ss']);

    final visData = v['visraam'] ?? v['Visraam'] ?? {};
    final vis = jsonEncode(visData is Map ? (visData['igurbani'] ?? visData['sttm2'] ?? visData['sttm'] ?? []) : []);

    final rId = _toInt(v['raag']?['raagId'] ?? v['RaagID'] ?? info?['raag']?['raagId']);
    final wId = _toInt(v['writer']?['writerId'] ?? v['WriterID'] ?? info?['writer']?['writerId']);

    final flStr = GurmukhiProcessor.generateFirstLetterStr(gur);
    final enInitials = _genInitEn(gur);
    final paInitials = _genInitPa(gur);

    // [AI_GUARD:PERMANENT_LOG] Deep logging for verse mapping to ensure no data is lost
    if (vId % 500 == 0) {
      print('${AppConstants.logTag} [shabad_sync_service.dart] VERSE_MAPPED: vId=$vId, sId=$shId, initials=$enInitials');
    }

    db.execute('INSERT OR REPLACE INTO verses (id, shabad_id, verse_order, gurmukhi, transliteration, transliteration_hi, translation, translation_pa, first_letter_str, initials_en, initials_pa, main_letters, visraams, source_id, raag_id, writer_id, ang) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [
      vId,
      shId,
      _toInt(v['lineNo']) ?? _toInt(v['verseNo']) ?? 0,
      gur,
      en,
      hi,
      transEn,
      transPa,
      flStr,
      enInitials,
      paInitials,
      null, // main_letters
      vis,
      sId,
      rId,
      wId,
      ang
    ]);
  }

  void _saveMeta(String table, Map? data, String idKey) {
    if (data == null) return;
    final id = _toInt(data[idKey] ?? data['id'] ?? data['ID']);
    if (id == null) return;
    final punjabi = _val(data['unicode'] ?? data['gurmukhi'] ?? data['name']);
    final english = _val(data['english'] ?? data['name']);
    db.execute('INSERT OR REPLACE INTO $table VALUES (?, ?, ?)', [id, punjabi, english]);
  }

  String _genInitEn(String unicode) {
    if (unicode.isEmpty) return '';
    final res = StringBuffer();
    
    // [AI_GUARD:PERMANENT_LOG] Exhaustive Phonetic Mapping for User-Friendly Search.
    // This map ensures that Gurmukhi vowels and complex characters are collapsed 
    // into standard QWERTY keys, enabling "Lazy Typing" to work correctly.
    const phoneticMap = {
      // Vowels / Standalone
      0x0A05: 'a', 0x0A06: 'a', 0x0A07: 'i', 0x0A08: 'i', 0x0A09: 'u', 0x0A0A: 'u',
      0x0A0F: 'e', 0x0A10: 'e', 0x0A13: 'o', 0x0A14: 'o', 0x0A72: 'e', 0x0A73: 'a',
      
      // Consonants (Collapsed pairs)
      0x0A15: 'k', 0x0A16: 'k', // ਕ, ਖ -> k
      0x0A17: 'g', 0x0A18: 'g', // ਗ, ਘ -> g
      0x0A1A: 'c', 0x0A1B: 'c', // ਚ, ਛ -> c
      0x0A1C: 'j', 0x0A1D: 'j', // ਜ, ਝ -> j
      0x0A1F: 't', 0x0A20: 't', 0x0A21: 'd', 0x0A22: 'd', // ਟ, ਠ, ਡ, ਢ -> t/d
      0x0A24: 't', 0x0A25: 't', 0x0A26: 'd', 0x0A27: 'd', // ਤ, ਥ, ਦ, ਧ -> t/d
      0x0A2A: 'p', 0x0A2B: 'p', 0x0A2C: 'b', 0x0A2D: 'b', // ਪ, ਫ, ਬ, ਭ -> p/b
      
      // Semivowels / Others
      0x0A38: 's', 0x0A39: 'h', 0x0A30: 'r', 0x0A32: 'l', 0x0A35: 'v',
      0x0A28: 'n', 0x0A2E: 'm', 0x0A2F: 'y', 0x0A23: 'n',
      0x0A36: 's', 0x0A5C: 'r', 0x0A5E: 'z', 0x0A71: 's', 
    };

    for (final word in unicode.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final char = word.characters.first;
      final charCode = char.runes.first;
      
      if (phoneticMap.containsKey(charCode)) {
        res.write(phoneticMap[charCode]);
      } else {
        // [AI_GUARD:PERMANENT_LOG] Final Fallback: If not in map, just take the first letter lowercase.
        // Strips any remaining Gurmukhi punctuation to ensure clean Roman initials.
        final roman = char.toLowerCase();
        if (RegExp(r'[a-z0-9]').hasMatch(roman)) {
          res.write(roman);
        }
      }
    }
    return res.toString();
  }

  String _genInitPa(String unicode) {
    if (unicode.isEmpty) return '';
    final res = StringBuffer();
    for (final word in unicode.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      res.write(word.characters.first);
    }
    return res.toString();
  }

  Future<Map<String, dynamic>?> _fetchAngWithRetry(String url) async {
    for (int i = 0; i < 3; i++) {
      try {
        final res = await dio.get(url);
        if (res.statusCode == 200) return res.data is Map ? res.data : null;
        if (res.statusCode == 404) return null;
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: 500));
    }
    return null;
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
  String _val(dynamic v) => (v is Map) ? (v['unicode'] ?? v['text'] ?? v.values.first.toString()) : (v?.toString() ?? '');
}

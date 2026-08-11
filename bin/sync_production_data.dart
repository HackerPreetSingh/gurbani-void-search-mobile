import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:characters/characters.dart';
import 'package:gurbani_voice_search/core/constants/app_constants.dart';

void main() async {
  final dbPath = 'assets/database/${AppConstants.dbFileName}';
  print('🚀 Starting Robust Gurbani Sync Engine (Enhanced Speed & Stability)...');

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
  
  print('🔍 Fetching master source list...');
  final sourceListRes = await dio.get('$baseUrl/sources');
  if (sourceListRes.statusCode != 200 || sourceListRes.data == null) {
    print('❌ FAILED to fetch sources. API might be down.');
    exit(1);
  }
  final sourceList = sourceListRes.data['rows'] as List;
  print('✅ Found ${sourceList.length} sources to sync.');

  int totalSynced = 0;
  for (final src in sourceList) {
    final sId = (src['SourceID'] ?? src['id']) as String;
    final sName = (src['SourceUnicode'] ?? src['SourceEnglish']) as String;

    print('\n-----------------------------------------------------------');
    print('📥 STARTING SYNC: $sName [$sId]');
    print('-----------------------------------------------------------');
    
    db.execute('INSERT OR IGNORE INTO sources VALUES (?, ?, ?)', [sId, sName, src['SourceEnglish']]);

    // Source A: Amrit Keertan
    if (sId == 'A') {
      await _syncSourceA(db, dio, baseUrl, sId, (count) => totalSynced += count);
      continue;
    }

    // Source R: Rehatname
    if (sId == 'R') {
      await _syncSourceR(db, dio, baseUrl, sId, (count) => totalSynced += count);
      continue;
    }

    // Source N: Bhai Nand Lal Ji
    // This source is sparse and usually contains specific shabad IDs.
    // We attempt a wide range or specialized shabad fetch.
    if (sId == 'N') {
      await _syncSourceN(db, dio, baseUrl, sId, (count) => totalSynced += count);
      continue;
    }

    // Default: Ang-based Sync
    print('🔍 Using Standard Ang-Batch navigation logic...');
    int currentAng = 1;
    int maxAng = (sId == 'G') ? 1430 : (sId == 'D' ? 2000 : 5000); 
    int consecutiveEmpty = 0;
    int sourceStartCount = totalSynced;
    const parallelism = 40; // Increased from 15 to 40 for higher throughput

    while (currentAng <= maxAng && consecutiveEmpty < 15) {
      try {
        final angsToFetch = <int>[];
        for (int i = 0; i < parallelism && (currentAng + i <= maxAng); i++) {
          angsToFetch.add(currentAng + i);
        }

        final futures = angsToFetch.map((ang) => _fetchAngWithRetry(dio, '$baseUrl/angs/$ang/$sId'));
        final responses = await Future.wait(futures);

        db.execute('BEGIN TRANSACTION');
        int batchCount = 0;
        bool foundAnyData = false;

        for (var response in responses) {
          if (response == null) continue;
          
          final List verses = response['page'] ?? response['verses'] ?? [];
          if (verses.isEmpty) continue;
          
          foundAnyData = true;
          for (final v in verses) {
            final shId = _toInt(v['shabadId'] ?? v['ShabadID']);
            if (shId == null) continue;
            await _processVerse(db, v, sId, shId, v);
            totalSynced++;
            batchCount++;
          }
        }
        db.execute('COMMIT');

        if (foundAnyData) {
          consecutiveEmpty = 0;
          stdout.write('\r  ✅ Syncing $sId... Progress: Ang $currentAng. Lines: $totalSynced (+ $batchCount)');
        } else {
          consecutiveEmpty++;
        }

        currentAng += parallelism;
      } catch (e) {
        try { db.execute('ROLLBACK'); } catch (_) {}
        print('\n  ❌ ERROR at Ang $currentAng for $sId: $e');
        currentAng += 1;
      }
    }
    print('\n✨ Source $sId sync complete. Total lines: ${totalSynced - sourceStartCount}');
  }
  
  db.close();
  print('\n\n🏁 MASTER SYNC COMPLETE! Total database lines: $totalSynced');
}

Future<void> _syncSourceA(Database db, Dio dio, String baseUrl, String sId, Function(int) onSynced) async {
  print('🔍 Source A: Using Header-Index batch logic...');
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
      final chunkFutures = <Future<Map<String, dynamic>?>>[];
      for (int i = 0; i < allShabadIds.length; i += shabadBatchSize) {
        final chunkIds = allShabadIds.skip(i).take(shabadBatchSize).join(',');
        chunkFutures.add(_fetchWithRetry(dio, '$baseUrl/shabads/$chunkIds'));
      }

      // Fetch all chunks in parallel (groups of 5)
      for (int i = 0; i < chunkFutures.length; i += 5) {
        final currentGroup = chunkFutures.skip(i).take(5);
        final results = await Future.wait(currentGroup);
        
        db.execute('BEGIN TRANSACTION');
        for (var res in results) {
          if (res == null) continue;
          final List shabadList = res['shabads'] ?? [];
          for (var shabadData in shabadList) {
            final shId = _toInt(shabadData['shabadInfo']?['shabadId']);
            final List verses = shabadData['verses'] ?? [];
            for (final v in verses) {
              await _processVerse(db, v, sId, shId ?? 0, shabadData['shabadInfo']);
              onSynced(1);
              headerLineCount++;
            }
          }
        }
        db.execute('COMMIT');
        stdout.write('\r  ✅ Header $headerId: Syncing... Progress: $headerLineCount lines.');
      }
      print('\n  ✅ Completed Header $headerId ($headerText). Added $headerLineCount lines.');
    }
  } catch (e) {
    print('  ❌ FAIL: Source A failed: $e');
  }
}

Future<void> _syncSourceR(Database db, Dio dio, String baseUrl, String sId, Function(int) onSynced) async {
  print('🔍 Source R: Using Maryada-Chapter logic...');
  try {
    final rehatsRes = await dio.get('$baseUrl/rehats');
    final maryadas = rehatsRes.data['maryadas'] as List;
    
    for (final m in maryadas) {
      final rId = m['rehatID'];
      final rName = m['rehatName'];
      print('  📜 Maryada $rId: $rName');
      
      final res = await dio.get('$baseUrl/rehats/$rId');
      final chapters = res.data['chapters'] as List;
      
      for (final ch in chapters) {
        final chId = ch['chapterID'];
        final chRes = await _fetchWithRetry(dio, '$baseUrl/rehats/$rId/chapters/$chId');
        if (chRes == null) continue;
        
        final chapterList = chRes['chapters'] as List?;
        if (chapterList == null) continue;
        
        db.execute('BEGIN TRANSACTION');
        for (var chapterData in chapterList) {
          final content = chapterData['chapterContent'] ?? '';
          if (content.isEmpty) continue;
          final vId = (9000000 + DateTime.now().microsecondsSinceEpoch % 1000000); 
          db.execute('INSERT OR REPLACE INTO verses (id, shabad_id, gurmukhi, source_id, ang) VALUES (?, ?, ?, ?, ?)', 
            [vId, rId, content, sId, chId]);
          onSynced(1);
        }
        db.execute('COMMIT');
      }
    }
  } catch (e) {
    print('  ❌ FAIL: Source R failed: $e');
  }
}

Future<void> _syncSourceN(Database db, Dio dio, String baseUrl, String sId, Function(int) onSynced) async {
  print('🔍 Source N: Using Parallel Shabad-Range sync (30000-31000)...');
  int sourceCount = 0;
  const rangeStart = 30000;
  const rangeEnd = 31000;
  const batchSize = 40;
  const rangeParallelism = 10;

  for (int i = rangeStart; i < rangeEnd; i += (batchSize * rangeParallelism)) {
    final futures = <Future<Map<String, dynamic>?>>[];
    for (int j = 0; j < rangeParallelism; j++) {
      final start = i + (j * batchSize);
      if (start >= rangeEnd) break;
      final ids = List.generate(batchSize, (index) => start + index).join(',');
      futures.add(_fetchWithRetry(dio, '$baseUrl/shabads/$ids'));
    }

    final results = await Future.wait(futures);

    db.execute('BEGIN TRANSACTION');
    for (var res in results) {
      if (res == null || res['shabads'] == null) continue;
      final List shabadList = res['shabads'];
      for (var shData in shabadList) {
        final info = shData['shabadInfo'];
        if (info == null) continue;
        final actualSId = info['source']?['sourceId'] ?? info['sourceId'];
        if (actualSId != 'N') continue; 

        final shId = _toInt(info['shabadId']);
        final List verses = shData['verses'] ?? [];
        for (final v in verses) {
          await _processVerse(db, v, sId, shId ?? 0, info);
          onSynced(1);
          sourceCount++;
        }
      }
    }
    db.execute('COMMIT');
    stdout.write('\r  ✅ Syncing N... Current Range Start: $i. Total lines: $sourceCount');
  }
  print('\n✨ Source N complete. Added $sourceCount lines.');
}

Future<Map<String, dynamic>?> _fetchAngWithRetry(Dio dio, String url) async {
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

Future<Map<String, dynamic>?> _fetchWithRetry(Dio dio, String url) async {
  for (int i = 0; i < 3; i++) {
    try {
      final res = await dio.get(url);
      if (res.statusCode == 200) return res.data;
    } catch (_) {}
    await Future.delayed(Duration(seconds: 1));
  }
  return null;
}

Future<void> _processVerse(Database db, Map v, String sId, int shId, Map? info) async {
  final vId = _toInt(v['verseId'] ?? v['id'] ?? v['ID'] ?? v['VerseID']);
  if (vId == null) return;

  _saveMeta(db, 'writers', v['writer'] ?? info?['writer'], 'writerId');
  _saveMeta(db, 'raags', v['raag'] ?? info?['raag'], 'raagId');
  
  final ang = _toInt(v['pageNo'] ?? v['ang'] ?? v['PageNo'] ?? info?['pageNo'] ?? info?['ang']);
  db.execute('INSERT OR REPLACE INTO shabads VALUES (?, ?, ?, ?, ?)', 
      [shId, sId, _toInt(v['writer']?['writerId'] ?? info?['writer']?['writerId']), _toInt(v['raag']?['raagId'] ?? info?['raag']?['raagId']), ang]);

  final gur = _val(v['verse']?['unicode'] ?? v['gurmukhi'] ?? v['GurmukhiUni'] ?? v['Gurmukhi'] ?? '');
  final hi = _val(v['transliteration']?['hindi'] ?? v['transliteration']?['hi'] ?? v['Transliterations']?['hi']);
  final en = _val(v['transliteration']?['english'] ?? v['transliteration']?['en'] ?? v['Transliterations']?['en']);
  final transEn = _val(v['translation']?['en']?['bdb'] ?? v['translation']?['en']?['text'] ?? v['Translations']?['en']?['bdb']);
  final transPa = _val(v['translation']?['pu']?['ss'] ?? v['translation']?['pu']?['text'] ?? v['Translations']?['pu']?['ss']);
  
  final visData = v['visraam'] ?? v['Visraam'] ?? {};
  final vis = jsonEncode(visData is Map ? (visData['igurbani'] ?? visData['sttm2'] ?? visData['sttm'] ?? []) : []);
  
  final rId = _toInt(v['raag']?['raagId'] ?? v['RaagID'] ?? info?['raag']?['raagId']);
  final wId = _toInt(v['writer']?['writerId'] ?? v['WriterID'] ?? info?['writer']?['writerId']);

  final flStr = _genFlStr(gur);
  final enInitials = _genInitEn(gur);
  final paInitials = _genInitPa(gur);

  db.execute('INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', 
    [vId, shId, _toInt(v['lineNo']) ?? _toInt(v['LineNo']) ?? 0, gur, en, hi, transEn, transPa, flStr, enInitials, paInitials, null, vis, sId, rId, wId, ang]);
}

String _genInitEn(String unicode) {
  if (unicode.isEmpty) return '';
  final res = StringBuffer();
  
  // Mapping for User-Friendly English Initials (Strategy 2 / Omni Fallback)
  // Maps all aspirated and soft/hard variants to a single common keyboard character.
  const phoneticMap = {
    0x0A15: 'k', 0x0A16: 'k', // ਕ, ਖ -> k
    0x0A17: 'g', 0x0A18: 'g', // ਗ, ਘ -> g
    0x0A1A: 'c', 0x0A1B: 'c', // ਚ, ਛ -> c
    0x0A1C: 'j', 0x0A1D: 'j', // ਜ, ਝ -> j
    0x0A1F: 't', 0x0A20: 't', 0x0A21: 'd', 0x0A22: 'd', // ਟ, ਠ, ਡ, ਢ -> t/d
    0x0A24: 't', 0x0A25: 't', 0x0A26: 'd', 0x0A27: 'd', // ਤ, ਥ, ਦ, ਧ -> t/d
    0x0A2A: 'p', 0x0A2B: 'p', 0x0A2C: 'b', 0x0A2D: 'b', // ਪ, ਫ, ਬ, ਭ -> p/b
    0x0A38: 's', 0x0A39: 'h', 0x0A30: 'r', 0x0A32: 'l', 0x0A35: 'v',
    0x0A28: 'n', 0x0A2E: 'm', 0x0A2F: 'y', 0x0A23: 'n',
  };

  for (final word in unicode.trim().split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final firstChar = word.characters.first;
    final charCode = firstChar.runes.first;
    
    if (phoneticMap.containsKey(charCode)) {
      res.write(phoneticMap[charCode]);
    } else {
      final ascii = _map[charCode];
      if (ascii != null) res.write(ascii[0].toLowerCase());
    }
  }
  return res.toString();
}

String _genInitPa(String unicode) {
  if (unicode.isEmpty) return '';
  final res = StringBuffer();
  for (final word in unicode.trim().split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final char = word.characters.first;
    if (_map.containsKey(char.runes.first)) res.writeCharCode(char.runes.first);
  }
  return res.toString();
}

const _map = {
    0x0A05: 'A', 0x0A06: 'Aw', 0x0A07: 'ie', 0x0A08: 'eI', 0x0A09: 'au', 0x0A0A: 'aU',
    0x0A0F: 'ey', 0x0A10: 'AY', 0x0A13: 'E', 0x0A14: 'AO', 0x0A15: 'k', 0x0A16: 'K',
    0x0A17: 'g', 0x0A18: 'G', 0x0A19: '|', 0x0A1A: 'c', 0x0A1B: 'C', 0x0A1C: 'j',
    0x0A1D: 'J', 0x0A1E: r'\\', 0x0A1F: 't', 0x0A20: 'T', 0x0A21: 'f', 0x0A22: 'F',
    0x0A23: 'x', 0x0A24: 'q', 0x0A25: 'Q', 0x0A26: 'd', 0x0A27: 'D', 0x0A28: 'n',
    0x0A2A: 'p', 0x0A2B: 'P', 0x0A2C: 'b', 0x0A2D: 'B', 0x0A2E: 'm', 0x0A2F: 'X',
    0x0A30: 'r', 0x0A32: 'l', 0x0A35: 'v', 0x0A38: 's', 0x0A39: 'h', 0x0A5B: 'z',
    0x0A5C: 'V', 0x0A72: 'e', 0x0A73: 'a', 0x0A74: '1', 0x0A71: 'S',
};

String _genFlStr(String unicode) {
  final codes = unicode.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) {
    final firstChar = w.characters.first;
    final ascii = _map[firstChar.runes.first];
    if (ascii == null) return null;
    final code = ascii.codeUnitAt(0);
    return code < 100 ? '0$code' : '$code';
  }).whereType<String>();
  return codes.isEmpty ? '' : ',${codes.join(',')}';
}

int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

String _val(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) return v['unicode'] ?? v['text'] ?? (v.values.isNotEmpty ? v.values.first.toString() : '');
  return v.toString();
}

void _saveMeta(Database db, String table, Map? data, String idKey) {
  if (data == null) return;
  final id = _toInt(data[idKey] ?? data['id'] ?? data['ID']);
  if (id == null) return;
  final punjabi = _val(data['unicode'] ?? data['gurmukhi'] ?? data['name']);
  final english = _val(data['english'] ?? data['name']);
  db.execute('INSERT OR REPLACE INTO $table VALUES (?, ?, ?)', [id, punjabi, english]);
}

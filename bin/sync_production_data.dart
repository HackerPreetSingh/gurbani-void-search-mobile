import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:characters/characters.dart';

void main() async {
  final dbPath = 'assets/database/gurbani_offline.sqlite';
  print('🚀 Starting Final Comprehensive Sync (All Sources)...');

  final dir = Directory('assets/database');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File(dbPath);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(dbPath);
  db.execute('CREATE TABLE sources (id TEXT PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE writers (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE raags (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE shabads (id INTEGER PRIMARY KEY, source_id TEXT, writer_id INTEGER, raag_id INTEGER, ang INTEGER)');
  db.execute('CREATE TABLE verses (id INTEGER PRIMARY KEY, shabad_id INTEGER, verse_order INTEGER, gurmukhi TEXT, transliteration TEXT, transliteration_hi TEXT, translation TEXT, first_letter_str TEXT, main_letters TEXT)');
  db.execute('CREATE INDEX idx_verses_fl ON verses (first_letter_str)');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 300),
    validateStatus: (status) => status! < 500, 
  ));

  const baseUrl = 'https://api.banidb.com/v2';
  
  // FIXED: Explicitly including all 7 production sources
  final sourceIds = ['G', 'D', 'A', 'B', 'N', 'R', 'S'];

  int totalSynced = 0;
  for (final sId in sourceIds) {
    print('\n📥 Syncing source: $sId');
    int currentAng = 1;
    int emptyResponseCount = 0;

    while (emptyResponseCount < 3) {
      try {
        final response = await dio.get('$baseUrl/angs/$currentAng-${currentAng + 19}/$sId');
        if (response.statusCode != 200) break;

        final pages = response.data['pages'] as List?;
        if (pages == null || pages.isEmpty) {
          emptyResponseCount++;
          currentAng += 20;
          continue;
        }
        emptyResponseCount = 0;

        db.execute('BEGIN TRANSACTION');
        bool foundValidSource = false;
        for (final pageData in pages) {
          final sInfo = pageData['source'];
          if (sInfo == null || sInfo['sourceId']?.toString().toUpperCase() != sId) continue;
          foundValidSource = true;
          
          db.execute('INSERT OR REPLACE INTO sources VALUES (?, ?, ?)', 
            [sId, sInfo['unicode'] ?? sInfo['english'] ?? sId, sInfo['english'] ?? sId]);

          for (final v in (pageData['page'] as List)) {
            final shId = _toInt(v['shabadId']);
            final vId = _toInt(v['verseId']);
            if (shId == null || vId == null) continue;

            _saveMeta(db, 'writers', v['writer'], 'writerId');
            _saveMeta(db, 'raags', v['raag'], 'raagId');
            
            db.execute('INSERT OR REPLACE INTO shabads VALUES (?, ?, ?, ?, ?)', 
                [shId, sId, _toInt(v['writer']?['writerId']), _toInt(v['raag']?['raagId']), _toInt(v['pageNo'])]);

            final gur = v['verse']?['unicode'] ?? v['gurmukhi'] ?? '';
            final hi = v['transliteration']?['hindi'] ?? v['transliteration']?['hi'];
            final fl = _genFlStr(gur);
            
            db.execute('INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', 
              [vId, shId, _toInt(v['lineNo']) ?? 0, gur, v['transliteration']?['english'], hi, v['translation']?['en']?['bdb'], fl, null]);
            totalSynced++;
          }
        }
        db.execute('COMMIT');
        stdout.write('\r✅ Current lines synced: $totalSynced...');
        if (!foundValidSource) break;
        currentAng += 20;
      } catch (e) {
        try { db.execute('ROLLBACK'); } catch (_) {}
        break;
      }
    }
  }
  db.dispose();
  print('\n🏁 Master Sync Complete! Total Lines: $totalSynced');
}

int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

void _saveMeta(Database db, String table, Map? data, String idKey) {
  if (data == null) return;
  final id = _toInt(data[idKey] ?? data['id']);
  if (id == null) return;
  final punjabi = data['unicode'] ?? data['english'] ?? data['gurmukhi'] ?? 'Unknown';
  final english = data['english'] ?? data['unicode'] ?? data['gurmukhi'] ?? 'Unknown';
  db.execute('INSERT OR REPLACE INTO $table VALUES (?, ?, ?)', [id, punjabi, english]);
}

String _genFlStr(String unicode) {
  const map = {
    0x0A05: 'A', 0x0A06: 'Aw', 0x0A07: 'ie', 0x0A08: 'eI', 0x0A09: 'au', 0x0A0A: 'aU',
    0x0A0F: 'ey', 0x0A10: 'AY', 0x0A13: 'E', 0x0A14: 'AO', 0x0A15: 'k', 0x0A16: 'K',
    0x0A17: 'g', 0x0A18: 'G', 0x0A19: '|', 0x0A1A: 'c', 0x0A1B: 'C', 0x0A1C: 'j',
    0x0A1D: 'J', 0x0A1E: r'\\', 0x0A1F: 't', 0x0A20: 'T', 0x0A21: 'f', 0x0A22: 'F',
    0x0A23: 'x', 0x0A24: 'q', 0x0A25: 'Q', 0x0A26: 'd', 0x0A27: 'D', 0x0A28: 'n',
    0x0A2A: 'p', 0x0A2B: 'P', 0x0A2C: 'b', 0x0A2D: 'B', 0x0A2E: 'm', 0x0A2F: 'X',
    0x0A30: 'r', 0x0A32: 'l', 0x0A35: 'v', 0x0A38: 's', 0x0A39: 'h', 0x0A5B: 'z',
    0x0A5C: 'V', 0x0A72: 'e', 0x0A73: 'a', 0x0A74: '1',
  };
  final codes = unicode.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) {
    final firstChar = w.characters.first;
    final ascii = map[firstChar.runes.first];
    if (ascii == null) return null;
    final code = ascii.codeUnitAt(0);
    return code < 100 ? '0$code' : '$code';
  }).whereType<String>();
  return codes.isEmpty ? '' : ',${codes.join(',')}';
}

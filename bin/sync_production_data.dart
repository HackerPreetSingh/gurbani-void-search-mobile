import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:characters/characters.dart';

void main() async {
  final dbPath = 'assets/database/gurbani_offline.sqlite';
  print('🚀 Starting High-Performance Multi-Source Sync...');

  final dir = Directory('assets/database');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File(dbPath);
  if (file.existsSync()) file.deleteSync();

  final db = sqlite3.open(dbPath);
  db.execute('CREATE TABLE sources (id TEXT PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE writers (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE raags (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
  db.execute('CREATE TABLE shabads (id INTEGER PRIMARY KEY, source_id TEXT, writer_id INTEGER, raag_id INTEGER, ang INTEGER)');
  db.execute('CREATE TABLE verses (id INTEGER PRIMARY KEY, shabad_id INTEGER, verse_order INTEGER, gurmukhi TEXT, transliteration TEXT, transliteration_hi TEXT, translation TEXT, translation_pa TEXT, first_letter_str TEXT, main_letters TEXT, visraams TEXT, source_id TEXT, raag_id INTEGER, writer_id INTEGER, ang INTEGER)');
  
  db.execute('CREATE INDEX idx_verses_fl ON verses (first_letter_str)');
  db.execute('CREATE INDEX idx_verses_sid ON verses (shabad_id)');
  db.execute('CREATE INDEX idx_shabads_src ON shabads (source_id)');
  db.execute('CREATE INDEX idx_verses_covering ON verses (first_letter_str, source_id, id)');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 300),
    validateStatus: (status) => status! < 500, 
  ));

  const baseUrl = 'https://api.banidb.com/v2';
  final sourceList = (await dio.get('$baseUrl/sources')).data['rows'] as List;

  int totalSynced = 0;
  for (final src in sourceList) {
    final sId = src['SourceID'] as String;
    final sName = (src['SourceUnicode'] ?? src['SourceEnglish']) as String;

    print('\n📥 SYNCING: $sName [$sId]');
    db.execute('INSERT OR IGNORE INTO sources VALUES (?, ?, ?)', [sId, sName, src['SourceEnglish']]);

    int currentAng = 1;
    while (true) {
      try {
        final response = await dio.get('$baseUrl/angs/$currentAng-${currentAng + 19}/$sId');
        if (response.statusCode != 200) break;

        final pages = response.data['pages'] as List?;
        if (pages == null || pages.isEmpty) break;

        db.execute('BEGIN TRANSACTION');
        for (final pageData in pages) {
          final pSource = pageData['source'];
          final pageSourceId = (pSource is Map ? (pSource['sourceId'] ?? pSource['id']) : (pageData['sourceId'] ?? pageData['id']))?.toString();
          
          if (pageSourceId != null && pageSourceId.toUpperCase() != sId.toUpperCase()) continue;
          
          final List verses = pageData['page'] ?? pageData['verses'] ?? [];
          for (final v in verses) {
            final shId = _toInt(v['shabadId']);
            final vId = _toInt(v['verseId']);
            if (shId == null || vId == null) continue;

            _saveMeta(db, 'writers', v['writer'], 'writerId');
            _saveMeta(db, 'raags', v['raag'], 'raagId');
            
            db.execute('INSERT OR REPLACE INTO shabads VALUES (?, ?, ?, ?, ?)', 
                [shId, sId, _toInt(v['writer']?['writerId']), _toInt(v['raag']?['raagId']), _toInt(v['pageNo'])]);

            final gur = _val(v['verse']?['unicode'] ?? v['gurmukhi'] ?? '');
            final hi = _val(v['transliteration']?['hindi'] ?? v['transliteration']?['hi']);
            final en = _val(v['transliteration']?['english'] ?? v['transliteration']?['en']);
            final transEn = _val(v['translation']?['en']?['bdb'] ?? v['translation']?['en']?['combined'] ?? v['translation']?['en']);
            final transPa = _val(v['translation']?['pu']?['ss'] ?? v['translation']?['pu']?['ft'] ?? v['translation']?['pu']);
            
            final vis = v['visraam'] != null ? jsonEncode(v['visraam']['sttm2'] ?? v['visraam']['sttm'] ?? []) : null;
            final rId = _toInt(v['raag']?['raagId'] ?? v['raagId']);
            final wId = _toInt(v['writer']?['writerId'] ?? v['writerId']);
            final ang = _toInt(v['pageNo'] ?? v['ang']);

            db.execute('INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', 
              [vId, shId, _toInt(v['lineNo']) ?? 0, gur, en, hi, transEn, transPa, _genFlStr(gur), null, vis, sId, rId, wId, ang]);
            totalSynced++;
          }
        }
        db.execute('COMMIT');
        if (totalSynced > 0) {
          stdout.write('\r✅ Processed: $totalSynced lines...');
        }
        currentAng += 20;
      } catch (e) {
        try { db.execute('ROLLBACK'); } catch (_) {}
        print('\n❌ Error syncing $sId at Ang $currentAng: $e');
        break;
      }
    }
  }
  db.dispose();
  print('\n🏁 Master Sync Complete! Total Lines indexed: $totalSynced');
}

int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

String _val(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) return (v['unicode'] ?? v['english'] ?? v['text'] ?? v.values.firstOrNull ?? '').toString();
  return v.toString();
}

void _saveMeta(Database db, String table, Map? data, String idKey) {
  if (data == null) return;
  final id = _toInt(data[idKey] ?? data['id']);
  if (id == null) return;
  final punjabi = _val(data['unicode'] ?? data['english'] ?? data['gurmukhi']);
  final english = _val(data['english'] ?? data['unicode'] ?? data['gurmukhi']);
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

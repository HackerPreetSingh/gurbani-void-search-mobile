import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:characters/characters.dart';

/// SMART HYBRID SYNC ENGINE v8
/// Uses page-based ranges for major books and parallel ID fetching for others.
/// Designed to NEVER hang.
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
  db.execute('''
    CREATE TABLE verses (
      id INTEGER PRIMARY KEY,
      shabad_id INTEGER,
      verse_order INTEGER,
      gurmukhi TEXT,
      transliteration TEXT,
      transliteration_hi TEXT,
      translation TEXT,
      first_letter_str TEXT,
      main_letters TEXT
    )
  ''');
  db.execute('CREATE INDEX idx_verses_fl ON verses (first_letter_str)');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    validateStatus: (status) => status! < 500,
  ));

  const baseUrl = 'https://api.banidb.com/v2';
  
  // Strategy:
  // 1. G and D are huge, use /angs range (Fastest)
  // 2. A, B, N, R, S are smaller, use /shabads range (Robust)
  
  final angSources = [
    {'id': 'G', 'name': 'Sri Guru Granth Sahib Ji', 'max': 1430},
    {'id': 'D', 'name': 'Sri Dasam Granth Sahib', 'max': 2820},
  ];

  final shabadSources = ['A', 'B', 'N', 'R', 'S'];

  int totalSynced = 0;

  // --- PART 1: PAGE-BASED SYNC (G & D) ---
  for (final s in angSources) {
    final sId = s['id'] as String;
    final sName = s['name'] as String;
    final max = s['max'] as int;

    print('\n📥 SYNCING PAGE-BASED SOURCE: $sName [$sId]');
    db.execute('INSERT OR IGNORE INTO sources VALUES (?, ?, ?)', [sId, sName, sName]);

    for (int start = 1; start <= max; start += 20) {
      final end = (start + 19).clamp(1, max);
      try {
        final response = await dio.get('$baseUrl/angs/$start-$end/$sId');
        if (response.statusCode != 200) break;
        final List pages = response.data['pages'] ?? [];
        if (pages.isEmpty) break;

        db.execute('BEGIN TRANSACTION');
        for (final p in pages) {
          if (p['source']?['sourceId'] != sId) continue;
          for (final v in (p['page'] as List)) {
            _saveAll(db, v, sId, totalSynced);
            totalSynced++;
          }
        }
        db.execute('COMMIT');
        stdout.write('\r✅ Processed: $totalSynced lines...');
      } catch (_) {}
    }
  }

  // --- PART 2: ID-BASED SYNC (A, B, N, R, S) ---
  print('\n\n📥 SYNCING OTHER SOURCES (ID-SCAN MODE)...');
  // We scan ID ranges that are likely to contain these sources
  // A is 40000+, B is 40001+, N is 30000+, S is 41000+
  // We'll scan ID ranges in parallel to avoid hanging
  
  final idRanges = [
    [30000, 35000], // Catch N
    [40000, 50000], // Catch A, B, S
    [60000, 75000], // Catch R and others
  ];

  for (final range in idRanges) {
    print('\n🔍 Scanning IDs ${range[0]} to ${range[1]}...');
    for (int startId = range[0]; startId <= range[1]; startId += 100) {
      final futures = <Future<Response>>[];
      for (int i = 0; i < 100; i += 20) {
        final batchStart = startId + i;
        final ids = List.generate(20, (j) => batchStart + j).join(',');
        futures.add(dio.get('$baseUrl/shabads/$ids'));
      }

      try {
        final results = await Future.wait(futures);
        db.execute('BEGIN TRANSACTION');
        for (final res in results) {
          final List shabads = res.data['shabads'] ?? [];
          for (final sData in shabads) {
            final info = sData['shabadInfo'];
            final List verses = sData['verses'] ?? [];
            if (info == null || verses.isEmpty) continue;

            final sId = info['source']?['sourceId']?.toString() ?? 'Unknown';
            // Only process if it's one of our target sources
            if (!shabadSources.contains(sId)) continue;

            db.execute('INSERT OR IGNORE INTO sources VALUES (?, ?, ?)', 
              [sId, info['source']?['unicode'] ?? sId, info['source']?['english'] ?? sId]);

            for (final v in verses) {
              _saveAll(db, v, sId, totalSynced, info: info);
              totalSynced++;
            }
          }
        }
        db.execute('COMMIT');
        stdout.write('\r✅ Processed: $totalSynced lines (Up to ID $startId)...');
      } catch (_) {}
    }
  }

  db.dispose();
  print('\n🏁 MASTER SYNC COMPLETE! Total Lines: $totalSynced');
}

void _saveAll(Database db, Map v, String sId, int lineId, {Map? info}) {
  final shId = _toInt(v['shabadId'] ?? info?['shabadId']);
  final vId = _toInt(v['verseId'] ?? v['id']);
  if (shId == null || vId == null) return;

  _saveMeta(db, 'writers', v['writer'] ?? info?['writer'], 'writerId');
  _saveMeta(db, 'raags', v['raag'] ?? info?['raag'], 'raagId');

  db.execute('INSERT OR REPLACE INTO shabads VALUES (?, ?, ?, ?, ?)', 
      [shId, sId, _toInt(v['writer']?['writerId'] ?? info?['writer']?['writerId']), 
       _toInt(v['raag']?['raagId'] ?? info?['raag']?['raagId']), 
       _toInt(v['pageNo'] ?? info?['pageNo'])]);

  final gur = v['verse']?['unicode'] ?? v['gurmukhi'] ?? '';
  final hi = v['transliteration']?['hindi'] ?? v['transliteration']?['hi'];
  db.execute('INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', 
    [vId, shId, _toInt(v['lineNo']) ?? 0, gur, v['transliteration']?['english'], hi, v['translation']?['en']?['bdb'], _genFlStr(gur), null]);
}

int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

void _saveMeta(Database db, String table, Map? data, String idKey) {
  if (data == null) return;
  final id = _toInt(data[idKey] ?? data['id']);
  if (id == null) return;
  db.execute('INSERT OR REPLACE INTO $table VALUES (?, ?, ?)', 
      [id, data['unicode'] ?? data['english'] ?? 'Unknown', data['english'] ?? 'Unknown']);
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

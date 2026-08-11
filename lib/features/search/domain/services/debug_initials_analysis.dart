import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'gurmukhi_processor.dart';

void main() {
  final dbPath = 'assets/database/gurbani_offline.sqlite';
  if (!File(dbPath).existsSync()) {
    print('❌ Database not found at $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);
  print('✅ Analyzing Local Database: $dbPath\n');

  final queries = [
    {'label': 'mkmgh', 'raw': 'mkmgh'},
    {'label': 'csgepjc', 'raw': 'csgepjc'},
    {'label': 'hkhdr', 'raw': 'hkhdr'},
  ];

  print('| Query | Processor Result | Local Matches | Potential Source of Error |');
  print('| :--- | :--- | :--- | :--- |');

  for (final q in queries) {
    final raw = q['raw']!;
    final processed = GurmukhiProcessor.queryToFirstLetterStr(raw);
    
    final results = db.select(
      'SELECT COUNT(*) as c FROM verses WHERE first_letter_str LIKE ?', 
      ['$processed%']
    );
    
    final count = results.first['c'];
    
    String error = 'Unknown';
    if (count == 0) {
      // Check if Source B even exists
      if (raw == 'csgepjc') {
        final bCount = db.select('SELECT COUNT(*) as c FROM verses WHERE source_id = "B"').first['c'];
        error = bCount == 0 ? 'Source B missing from DB' : 'Initials mismatch (Logic)';
      } else if (raw.contains('gh')) {
        error = 'gh mapping mismatch in Processor';
      } else {
        error = 'Data missing or logic too strict';
      }
    } else {
      error = 'None (Matches found)';
    }

    print('| $raw | $processed | $count | $error |');
  }

  print('\n--- Detailed Mapping Check for "gh" ---');
  final ghProcessed = GurmukhiProcessor.queryToFirstLetterStr('gh');
  final singleGProcessed = GurmukhiProcessor.queryToFirstLetterStr('g');
  print('  Input "gh" maps to: $ghProcessed');
  print('  Input "g"  maps to: $singleGProcessed');
  
  db.close();
}

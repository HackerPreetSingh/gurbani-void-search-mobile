import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:gurbani_voice_search/core/constants/app_constants.dart';
import 'gurmukhi_processor.dart';

void main() {
  final dbPath = 'assets/database/${AppConstants.dbFileName}';
  
  if (!File(dbPath).existsSync()) {
    print('❌ Database not found at $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);
  print('✅ Analyzing Local Database: $dbPath\n');

  final analysisTargets = [
    {
      'query': 'mkmgh',
      'line': 'ਮੇਰਾ ਕਿਆ ਮੁਖੁ ਘਿਨਿਆ ਹੋਇ',
      'source': 'G',
    },
    {
      'query': 'csgepjc',
      'line': 'ਚਰਨ ਸਰਨਿ ਗੁਰ ਏਕ ਪੈਂਡਾ ਜਾਇ ਚਲ',
      'source': 'B',
    },
    {
      'query': 'hkhdr',
      'line': 'ਹਮਰੀ ਕਰੋ ਹਾਥ ਦੈ ਰੱਛਾ',
      'source': 'D',
    },
  ];

  print('| Query | Found in DB? | Stored FL Code | Processor FL Code | Conclusion |');
  print('| :--- | :--- | :--- | :--- | :--- |');

  for (final target in analysisTargets) {
    final query = target['query'] as String;
    final line = target['line'] as String;
    
    final dbRows = db.select('SELECT first_letter_str, gurmukhi, visraams FROM verses WHERE gurmukhi LIKE ?', ['%$line%']);
    final processorCode = GurmukhiProcessor.queryToFirstLetterStr(query);
    
    if (dbRows.isEmpty) {
      print('| $query | ❌ NO | - | $processorCode | Line missing from DB |');
    } else {
      final row = dbRows.first;
      final storedCode = row['first_letter_str'] as String;
      final match = storedCode.startsWith(processorCode);
      final conclusion = match ? 'Should work' : 'Logic Mismatch';
      print('| $query | ✅ YES | $storedCode | $processorCode | $conclusion |');
      
      if (row['visraams'] != null) {
        print('  [Visraams]: ${row['visraams']}');
      }
    }
  }

  print('\n--- Aspirated Consonant Check ---');
  final mappingPairs = {'gh': 'ਘ', 'kh': 'ਖ', 'ch': 'ਚ', 'jh': 'ਝ', 'th': 'ਥ', 'dh': 'ਧ', 'ph': 'ਫ', 'bh': 'ਭ'};
  mappingPairs.forEach((roman, gurmukhi) {
     final p = GurmukhiProcessor.queryToFirstLetterStr(roman);
     print('  Roman "$roman" -> Code: $p');
  });

  db.close();
}

import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'gurmukhi_processor.dart';

void main() {
  final dbPath = '/Users/hempreetsingh/Library/Containers/com.example.gurbaniVoiceSearch/Data/Documents/gurbani_offline.sqlite';
  
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
    
    // 1. Check if line exists at all
    final dbRows = db.select('SELECT first_letter_str, gurmukhi FROM verses WHERE gurmukhi LIKE ?', ['%$line%']);
    
    // 2. See what processor generates for the user's Roman query
    final processorCode = GurmukhiProcessor.queryToFirstLetterStr(query);
    
    if (dbRows.isEmpty) {
      print('| $query | ❌ NO | - | $processorCode | Line missing from DB (Sync Error) |');
    } else {
      final storedCode = dbRows.first['first_letter_str'] as String;
      final match = storedCode.startsWith(processorCode);
      final conclusion = match ? 'Should work' : 'Logic Mismatch';
      print('| $query | ✅ YES | $storedCode | $processorCode | $conclusion |');
      
      if (!match) {
         print('\n  DEBUG [$query]: Stored "$storedCode" vs Processor "$processorCode"');
      }
    }
  }

  print('\n--- Checking Source Counts ---');
  final sources = ['G', 'B', 'D', 'A', 'S'];
  for (final s in sources) {
    final count = db.select('SELECT COUNT(*) as c FROM verses WHERE source_id = ?', [s]).first['c'];
    print('  Source [$s]: $count lines');
  }

  db.dispose();
}

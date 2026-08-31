import 'package:sqlite3/sqlite3.dart';

void main() {
  const dbPath = '/Users/hempreetsingh/flutter-projects/gurbani_voice_search/assets/database/shabads_offline.sqlite';
  final db = sqlite3.open(dbPath);
  
  void testId(int id) {
    final sourceRow = db.select('SELECT source_id FROM shabads WHERE id = ?', [id]);
    if (sourceRow.isEmpty) {
       print('ID not found');
       return;
    }
    final sourceId = sourceRow.first['source_id'];
    print('Shabad ID: $id Source: $sourceId');

    final prev = db.select(
      'SELECT id FROM shabads WHERE source_id = ? AND id < ? ORDER BY id DESC LIMIT 1',
      [sourceId, id]
    );
    if (prev.isNotEmpty) {
      print('  Previous: ${prev.first['id']}');
    } else {
      print('  Previous: NONE');
    }

    final next = db.select(
      'SELECT id FROM shabads WHERE source_id = ? AND id > ? ORDER BY id ASC LIMIT 1',
      [sourceId, id]
    );
    if (next.isNotEmpty) {
      print('  Next: ${next.first['id']}');
    } else {
      print('  Next: NONE');
    }
    print('');
  }

  testId(1);
  testId(500);
  testId(1000);

  db.close();
}

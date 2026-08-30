import 'package:drift/drift.dart';

class ProductionSchema {
  static Future<void> create(QueryExecutor executor) async {
    await executor.runCustom('CREATE TABLE IF NOT EXISTS sources (id TEXT PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS writers (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS raags (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS shabads (id INTEGER PRIMARY KEY NOT NULL, source_id TEXT NOT NULL, writer_id INTEGER, raag_id INTEGER, ang INTEGER, FOREIGN KEY (source_id) REFERENCES sources (id), FOREIGN KEY (writer_id) REFERENCES writers (id), FOREIGN KEY (raag_id) REFERENCES raags (id))');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS verses (id INTEGER PRIMARY KEY NOT NULL, shabad_id INTEGER NOT NULL, verse_order INTEGER NOT NULL, gurmukhi TEXT NOT NULL, transliteration TEXT, transliteration_hi TEXT, translation TEXT, translation_pa TEXT, first_letter_str TEXT NOT NULL, initials_en TEXT, initials_pa TEXT, main_letters TEXT, visraams TEXT, source_id TEXT, raag_id INTEGER, writer_id INTEGER, ang INTEGER, FOREIGN KEY (shabad_id) REFERENCES shabads (id) ON DELETE CASCADE)');
    
    // --- NITNEM / BANI EXTENSIONS ---
    await executor.runCustom('CREATE TABLE IF NOT EXISTS banis (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL, user_order INTEGER, updated_at TEXT)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS bani_verses (id INTEGER PRIMARY KEY AUTOINCREMENT, bani_id INTEGER NOT NULL, verse_id INTEGER NOT NULL, sequence_order INTEGER NOT NULL, header INTEGER, mangal_position INTEGER, exists_sgpc INTEGER, exists_medium INTEGER, exists_taksal INTEGER, exists_buddha_dal INTEGER, paragraph INTEGER, FOREIGN KEY (bani_id) REFERENCES banis (id) ON DELETE CASCADE, FOREIGN KEY (verse_id) REFERENCES verses (id) ON DELETE CASCADE)');

    await _createIndexes(executor);
  }

  static Future<void> _createIndexes(QueryExecutor executor) async {
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_first_letter ON verses (first_letter_str)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_bani_verses_bani ON bani_verses (bani_id)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_shabads_source ON shabads (source_id)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_shabads_writer ON shabads (writer_id)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_shabads_raag ON shabads (raag_id)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_shabad ON verses (shabad_id)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_initials_en ON verses (initials_en)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_initials_pa ON verses (initials_pa)');
  }

  static Future<void> ensureColumns(QueryExecutor executor) async {
    await _ensureColumnExists(executor, 'verses', 'initials_pa', 'TEXT');
    await _ensureColumnExists(executor, 'verses', 'main_letters', 'TEXT');
    await _ensureColumnExists(executor, 'banis', 'user_order', 'INTEGER');
  }

  static Future<void> _ensureColumnExists(QueryExecutor executor, String table, String column, String type) async {
    try {
      final columns = await executor.runSelect('PRAGMA table_info($table)', []);
      final hasColumn = columns.any((c) => c['name'] == column);
      if (!hasColumn) {
        await executor.runCustom('ALTER TABLE $table ADD COLUMN $column $type');
      }
    } catch (_) {}
  }
}

import 'package:drift/drift.dart';

class TrackerSchema {
  static Future<void> create(QueryExecutor executor) async {
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS trackers (
        id TEXT PRIMARY KEY NOT NULL,
        template_type TEXT NOT NULL,
        title TEXT NOT NULL,
        total_goal INTEGER,
        daily_target INTEGER,
        start_date TEXT NOT NULL,
        deadline_date TEXT,
        unit_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS tracker_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_id TEXT NOT NULL,
        log_date TEXT NOT NULL,
        count INTEGER NOT NULL,
        input_mode TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (tracker_id) REFERENCES trackers (id) ON DELETE CASCADE
      )
    ''');
    
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_logs_tracker ON tracker_logs (tracker_id)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_logs_date ON tracker_logs (log_date)');

    // --- PRAKARAN EXTENSIONS ---
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS prakarans (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS prakaran_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prakaran_id TEXT NOT NULL,
        shabad_id TEXT NOT NULL,
        title_gurmukhi TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (prakaran_id) REFERENCES prakarans (id) ON DELETE CASCADE
      )
    ''');

    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_prakaran_items_folder ON prakaran_items (prakaran_id)');
  }
}

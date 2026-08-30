import 'package:drift/drift.dart';

class MetadataSchema {
  static Future<void> create(QueryExecutor executor) async {
    await executor.runCustom('CREATE TABLE IF NOT EXISTS app_metadata (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL, updated_at_utc TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS search_history (shabad_id INTEGER PRIMARY KEY NOT NULL, query TEXT, gurmukhi TEXT NOT NULL, source_name TEXT NOT NULL, raag_name TEXT, writer_name TEXT, ang INTEGER, viewed_at_utc TEXT NOT NULL)');
  }
}

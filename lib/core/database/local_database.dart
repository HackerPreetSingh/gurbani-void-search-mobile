import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  LocalDatabase({DatabaseConnection? connection})
      : _connection = connection,
        _connectionUser = _LocalDatabaseConnectionUser();

  static const schemaVersion = 10;
  static const dbName = 'gurbani_production_v10';

  DatabaseConnection? _connection;
  final _LocalDatabaseConnectionUser _connectionUser;
  Future<DatabaseStatus>? _initialization;

  Future<DatabaseStatus> initialize() async {
    if (_initialization != null) return _initialization!;
    return _initialization = _initialize();
  }

  Future<void> hardReset() async {
    _initialization = null;
    await _connection?.close();
    _connection = null;
    if (!kIsWeb) {
      final docsDir = await getApplicationSupportDirectory();
      final file = File(p.join(docsDir.path, '$dbName.sqlite'));
      if (await file.exists()) await file.delete();
    }
  }

  void close() {
    _connection?.close();
    _connection = null;
    _initialization = null;
  }

  Future<T> read<T>(Future<T> Function(QueryExecutor executor) action) async {
    await initialize();
    return action(_connection!);
  }

  Future<T> transaction<T>(
    Future<T> Function(QueryExecutor executor) action,
  ) async {
    await initialize();
    final trans = _connection!.beginTransaction();
    await trans.ensureOpen(_connectionUser);
    try {
      final result = await action(trans);
      await trans.send();
      return result;
    } catch (e) {
      await trans.rollback();
      rethrow;
    }
  }

  Future<void> _copyAssetDatabaseIfNeeded() async {
    if (kIsWeb) return;
    try {
      final docsDir = await getApplicationSupportDirectory();
      final dbPath = p.join(docsDir.path, '$dbName.sqlite');
      final file = File(dbPath);

      if (!await file.exists() || (await file.length()) < 1 * 1024 * 1024) {
        final data = await rootBundle.load('assets/database/gurbani_offline.sqlite');
        await Directory(docsDir.path).create(recursive: true);
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
    } catch (e) {
      dev.log('Asset copy failed: $e');
    }
  }

  Future<DatabaseStatus> _initialize() async {
    if (!kIsWeb && _connection == null) {
      await _copyAssetDatabaseIfNeeded();
    }

    _connection ??= driftDatabase(
      name: dbName,
      native: const DriftNativeOptions(shareAcrossIsolates: true),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );

    await _connection!.ensureOpen(_connectionUser);
    return DatabaseStatus(schemaVersion: schemaVersion, initializedAtUtc: DateTime.now().toUtc());
  }
}

class _LocalDatabaseConnectionUser extends QueryExecutorUser {
  @override
  int get schemaVersion => LocalDatabase.schemaVersion;
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    await executor.runCustom('PRAGMA foreign_keys = ON');
    
    if ((details.versionBefore ?? 0) < schemaVersion) {
      await executor.runCustom('BEGIN IMMEDIATE');
      try {
        await executor.runCustom('CREATE TABLE IF NOT EXISTS app_metadata (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL, updated_at_utc TEXT NOT NULL)');
        await _createProductionSchema(executor);
        
        await executor.runCustom('DROP TABLE IF EXISTS search_history');
        await executor.runCustom('''
          CREATE TABLE search_history (
            shabad_id INTEGER PRIMARY KEY NOT NULL,
            query TEXT,
            gurmukhi TEXT NOT NULL,
            source_name TEXT NOT NULL,
            raag_name TEXT,
            writer_name TEXT,
            ang INTEGER,
            viewed_at_utc TEXT NOT NULL
          )
        ''');
        
        await executor.runCustom('COMMIT');
      } catch (_) {
        await executor.runCustom('ROLLBACK');
      }
    }
  }

  Future<void> _createProductionSchema(QueryExecutor executor) async {
    await executor.runCustom('CREATE TABLE IF NOT EXISTS sources (id TEXT PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS writers (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS raags (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS shabads (id INTEGER PRIMARY KEY NOT NULL, source_id TEXT NOT NULL, writer_id INTEGER, raag_id INTEGER, ang INTEGER, FOREIGN KEY (source_id) REFERENCES sources (id), FOREIGN KEY (writer_id) REFERENCES writers (id), FOREIGN KEY (raag_id) REFERENCES raags (id))');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS verses (id INTEGER PRIMARY KEY NOT NULL, shabad_id INTEGER NOT NULL, verse_order INTEGER NOT NULL, gurmukhi TEXT NOT NULL, transliteration TEXT, transliteration_hi TEXT, translation TEXT, first_letter_str TEXT NOT NULL, main_letters TEXT, FOREIGN KEY (shabad_id) REFERENCES shabads (id) ON DELETE CASCADE)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_first_letter ON verses (first_letter_str)');
  }
}

class DatabaseStatus {
  const DatabaseStatus({required this.schemaVersion, required this.initializedAtUtc});
  final int schemaVersion;
  final DateTime initializedAtUtc;
}

class DatabaseIntegrityException implements Exception {
  const DatabaseIntegrityException();
}

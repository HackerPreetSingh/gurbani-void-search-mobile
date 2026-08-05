import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  LocalDatabase() : _connectionUser = _LocalDatabaseConnectionUser();

  static const schemaVersion = 6;
  static const dbName = 'gurbani_offline_v6';

  DatabaseConnection? _connection;
  final _LocalDatabaseConnectionUser _connectionUser;
  Future<DatabaseStatus>? _initialization;

  Future<DatabaseStatus> initialize() async {
    if (_initialization != null) return _initialization!;
    return _initialization = _initialize();
  }

  Future<void> close() async => await _connection?.close();

  Future<T> read<T>(Future<T> Function(QueryExecutor executor) action) async {
    await initialize();
    return action(_connection!);
  }

  Future<T> transaction<T>(Future<T> Function(QueryExecutor executor) action) async {
    await initialize();
    final trans = _connection!.beginTransaction();
    await trans.ensureOpen(_connectionUser);
    try {
      final res = await action(trans);
      await trans.send();
      return res;
    } catch (e) {
      await trans.rollback();
      rethrow;
    }
  }

  Future<DatabaseStatus> _initialize() async {
    final docsDir = await getApplicationSupportDirectory();
    final dbPath = p.join(docsDir.path, '$dbName.sqlite');
    final file = File(dbPath);

    // 1. Mandatory Asset Copy
    if (!await file.exists() || (await file.length()) < 1 * 1024 * 1024) {
      try {
        final data = await rootBundle.load('assets/database/gurbani_offline.sqlite');
        await Directory(docsDir.path).create(recursive: true);
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      } catch (e) {
        dev.log('Asset copy failed: $e');
      }
    }

    // 2. Consistent Wiring
    _connection = driftDatabase(
      name: dbName,
      native: DriftNativeOptions(
        databaseDirectory: () async => Directory(docsDir.path),
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
      await _createProductionSchema(executor);
    }
  }

  Future<void> _createProductionSchema(QueryExecutor executor) async {
    await executor.runCustom('CREATE TABLE IF NOT EXISTS sources (id TEXT PRIMARY KEY, name_pa TEXT, name_en TEXT)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS writers (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS raags (id INTEGER PRIMARY KEY, name_pa TEXT, name_en TEXT)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS shabads (id INTEGER PRIMARY KEY, source_id TEXT, writer_id INTEGER, raag_id INTEGER, ang INTEGER)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS verses (id INTEGER PRIMARY KEY, shabad_id INTEGER, verse_order INTEGER, gurmukhi TEXT, transliteration TEXT, transliteration_hi TEXT, translation TEXT, first_letter_str TEXT, main_letters TEXT)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_fl ON verses (first_letter_str)');
  }
}

class DatabaseStatus {
  const DatabaseStatus({required this.schemaVersion, required this.initializedAtUtc});
  final int schemaVersion;
  final DateTime initializedAtUtc;
}

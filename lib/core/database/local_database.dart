import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class LocalDatabase {
  LocalDatabase({DatabaseConnection? connection})
      : _connection = connection,
        _connectionUser = _LocalDatabaseConnectionUser();

  static String? _cachedDocsPath;

  DatabaseConnection? _connection;
  final _LocalDatabaseConnectionUser _connectionUser;
  Future<DatabaseStatus>? _initialization;

  Future<DatabaseStatus> initialize() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT: initialize() called');
    if (_initialization != null) {
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT: Returning existing initialization Future');
      return _initialization!;
    }
    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT: Creating new initialization Future');
    return _initialization = _initialize();
  }

  Future<void> hardReset() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RESET: hardReset() requested. Purging all state.');
    _initialization = null;
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RESET: Closing existing connection...');
    await _connection?.close();
    _connection = null;
    if (!kIsWeb) {
      final path = await getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        print('${AppConstants.logTag} [${DateTime.now()}] DB_RESET: Deleting file at $path');
        await file.delete();
      } else {
        print('${AppConstants.logTag} [${DateTime.now()}] DB_RESET: No file found at $path to delete');
      }
    }
  }

  void close() {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_CLOSE: Closing connection and clearing Future');
    _connection?.close();
    _connection = null;
    _initialization = null;
  }

  Future<T> read<T>(Future<T> Function(QueryExecutor executor) action) async {
    await initialize();
    if (_connection == null) throw const DatabaseNotFoundException();
    return action(_connection!);
  }

  Future<T> transaction<T>(
    Future<T> Function(QueryExecutor executor) action,
  ) async {
    await initialize();
    if (_connection == null) throw const DatabaseNotFoundException();
    final trans = _connection!.beginTransaction();
    try {
      final result = await action(trans);
      await trans.send();
      return result;
    } catch (e) {
      await trans.rollback();
      rethrow;
    }
  }

  Future<String> getDatabasePath() async {
    if (kIsWeb) return AppConstants.dbFileName;
    if (_cachedDocsPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _cachedDocsPath = directory.path;
    }
    return p.join(_cachedDocsPath!, AppConstants.dbFileName);
  }

  Future<bool> databaseFileExists() async {
    if (kIsWeb) return true;
    final path = await getDatabasePath();
    return File(path).existsSync();
  }

  Future<void> reload() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RELOAD: Starting database reload sequence...');
    close();
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RELOAD: Re-initializing...');
    await initialize();
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RELOAD: Reload sequence complete');
  }

  Future<DatabaseStatus> _initialize() async {
    final start = DateTime.now();
    print('${AppConstants.logTag} [$start] DB_INIT_INTERNAL: Entering _initialize()');
    
    if (!kIsWeb) {
      await getDatabasePath();
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Database path resolved to $_cachedDocsPath');
      
      final path = p.join(_cachedDocsPath!, AppConstants.dbFileName);
      final exists = File(path).existsSync();
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: File exists check = $exists');
    } else {
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Web platform detected, using drift indexedDB');
    }

    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Creating Drift connection...');
    _connection ??= driftDatabase(
      name: 'gurbani_offline',
      native: DriftNativeOptions(
        databaseDirectory: () async {
          if (kIsWeb) throw UnsupportedError('Native directory not used on web');
          print('${AppConstants.logTag} [${DateTime.now()}] DB_CALLBACK: Drift requesting databaseDirectory: $_cachedDocsPath');
          return Directory(_cachedDocsPath!);
        },
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );

    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Ensuring connection is open with user context...');
    try {
      await _connection!.ensureOpen(_connectionUser);
      final end = DateTime.now();
      print('${AppConstants.logTag} [$end] DB_INIT_INTERNAL: Connection opened successfully. Duration: ${end.difference(start).inMilliseconds}ms');
    } catch (e) {
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: FATAL - Connection failed to open: $e');
      rethrow;
    }
    
    return DatabaseStatus(initializedAtUtc: DateTime.now().toUtc());
  }

  Future<bool> isDatabaseEmpty() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_QUERY: Checking if database is empty...');
    try {
      final result = await read((executor) => executor.runSelect('SELECT 1 FROM verses LIMIT 1', []));
      final isEmpty = result.isEmpty;
      print('${AppConstants.logTag} [${DateTime.now()}] DB_QUERY: Database empty check result = $isEmpty');
      return isEmpty;
    } catch (e) {
      print('${AppConstants.logTag} [${DateTime.now()}] DB_QUERY: Error during empty check (returning true): $e');
      return true;
    }
  }

  static void prefetchDocsPath() {
    if (kIsWeb) return;
    print('${AppConstants.logTag} Prefetching documents path...');
    getApplicationDocumentsDirectory().then((dir) {
      _cachedDocsPath = dir.path;
      print('${AppConstants.logTag} Documents path cached: $_cachedDocsPath');
    }).catchError((e) {
      print('${AppConstants.logTag} Failed to prefetch path: $e');
    });
  }
}

class _LocalDatabaseConnectionUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    await executor.runCustom('PRAGMA foreign_keys = ON');
    
    if (details.wasCreated) {
      await executor.runCustom('CREATE TABLE IF NOT EXISTS app_metadata (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL, updated_at_utc TEXT NOT NULL)');
      await _createProductionSchema(executor);
      await executor.runCustom('CREATE TABLE IF NOT EXISTS search_history (shabad_id INTEGER PRIMARY KEY NOT NULL, query TEXT, gurmukhi TEXT NOT NULL, source_name TEXT NOT NULL, raag_name TEXT, writer_name TEXT, ang INTEGER, viewed_at_utc TEXT NOT NULL)');
      await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_shabads_source ON shabads (source_id)');
      await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_shabads_writer ON shabads (writer_id)');
      await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_shabads_raag ON raags (id)');
      await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_shabad ON verses (shabad_id)');
      await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_initials_en ON verses (initials_en)');
      await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_initials_pa ON verses (initials_pa)');
    }
  }

  Future<void> _createProductionSchema(QueryExecutor executor) async {
    await executor.runCustom('CREATE TABLE IF NOT EXISTS sources (id TEXT PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS writers (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS raags (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS shabads (id INTEGER PRIMARY KEY NOT NULL, source_id TEXT NOT NULL, writer_id INTEGER, raag_id INTEGER, ang INTEGER, FOREIGN KEY (source_id) REFERENCES sources (id), FOREIGN KEY (writer_id) REFERENCES writers (id), FOREIGN KEY (raag_id) REFERENCES raags (id))');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS verses (id INTEGER PRIMARY KEY NOT NULL, shabad_id INTEGER NOT NULL, verse_order INTEGER NOT NULL, gurmukhi TEXT NOT NULL, transliteration TEXT, transliteration_hi TEXT, translation TEXT, translation_pa TEXT, first_letter_str TEXT NOT NULL, initials_en TEXT, initials_pa TEXT, main_letters TEXT, visraams TEXT, source_id TEXT, raag_id INTEGER, writer_id INTEGER, ang INTEGER, FOREIGN KEY (shabad_id) REFERENCES shabads (id) ON DELETE CASCADE)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_first_letter ON verses (first_letter_str)');
  }
}

class DatabaseStatus {
  const DatabaseStatus({required this.initializedAtUtc, this.isAvailable = true});
  final DateTime initializedAtUtc;
  final bool isAvailable;
}

class DatabaseIntegrityException implements Exception {
  const DatabaseIntegrityException();
}

class DatabaseNotFoundException implements Exception {
  const DatabaseNotFoundException();
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class LocalDatabase {
  LocalDatabase({required this.dbName, this._connection})
      : _connectionUser = _LocalDatabaseConnectionUser();

  final String dbName;
  static final Map<String, String?> _cachedPaths = {};

  DatabaseConnection? _connection;
  final _LocalDatabaseConnectionUser _connectionUser;
  Future<DatabaseStatus>? _initialization;

  Future<DatabaseStatus> initialize() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT: initialize($dbName) called');
    if (_initialization != null) {
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT: Returning existing initialization Future for $dbName');
      return _initialization!;
    }
    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT: Creating new initialization Future for $dbName');
    return _initialization = _initialize();
  }

  Future<void> hardReset() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RESET: hardReset($dbName) requested. Purging all state.');
    _initialization = null;
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RESET: Closing existing connection for $dbName...');
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
    print('${AppConstants.logTag} [${DateTime.now()}] DB_CLOSE: Closing connection for $dbName');
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
    if (kIsWeb) return dbName;
    if (_cachedPaths[dbName] == null) {
      final directory = await getApplicationDocumentsDirectory();
      _cachedPaths[dbName] = directory.path;
    }
    return p.join(_cachedPaths[dbName]!, dbName);
  }

  Future<bool> databaseFileExists() async {
    if (kIsWeb) return true;
    final path = await getDatabasePath();
    return File(path).existsSync();
  }

  Future<void> reload() async {
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RELOAD: Starting database reload sequence for $dbName...');
    close();
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RELOAD: Re-initializing $dbName...');
    await initialize();
    print('${AppConstants.logTag} [${DateTime.now()}] DB_RELOAD: Reload sequence complete for $dbName');
  }

  Future<DatabaseStatus> _initialize() async {
    final start = DateTime.now();
    print('${AppConstants.logTag} [$start] DB_INIT_INTERNAL: Entering _initialize() for $dbName');
    
    if (!kIsWeb) {
      await getDatabasePath();
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Database path resolved to ${_cachedPaths[dbName]}');
      
      final path = p.join(_cachedPaths[dbName]!, dbName);
      final exists = File(path).existsSync();
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: File exists check = $exists');
    } else {
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Web platform detected, using drift indexedDB');
    }

    print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: Creating Drift connection for $dbName...');
    _connection ??= driftDatabase(
      name: dbName.replaceAll('.sqlite', ''),
      native: DriftNativeOptions(
        databaseDirectory: () async {
          if (kIsWeb) throw UnsupportedError('Native directory not used on web');
          print('${AppConstants.logTag} [${DateTime.now()}] DB_CALLBACK: Drift requesting databaseDirectory for $dbName: ${_cachedPaths[dbName]}');
          return Directory(_cachedPaths[dbName]!);
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
      print('${AppConstants.logTag} [${DateTime.now()}] DB_INIT_INTERNAL: FATAL - Connection failed to open for $dbName: $e');
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
      // Logic for prefetching paths if needed
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
    
    // Create auxiliary tables if they don't exist (app metadata, history, banis)
    await executor.runCustom('CREATE TABLE IF NOT EXISTS app_metadata (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL, updated_at_utc TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS search_history (shabad_id INTEGER PRIMARY KEY NOT NULL, query TEXT, gurmukhi TEXT NOT NULL, source_name TEXT NOT NULL, raag_name TEXT, writer_name TEXT, ang INTEGER, viewed_at_utc TEXT NOT NULL)');
    
    // Ensure core production schema (sources, writers, raags, shabads, verses)
    await _createProductionSchema(executor);
    
    // --- TRACKER EXTENSIONS ---
    await _createTrackerSchema(executor);
    
    // Safety Check: Downloaded databases might be missing newer columns like initials_pa
    await _ensureColumnExists(executor, 'verses', 'initials_pa', 'TEXT');
    await _ensureColumnExists(executor, 'verses', 'main_letters', 'TEXT');
    await _ensureColumnExists(executor, 'banis', 'user_order', 'INTEGER');

    // Create indexes safely
    await _createIndexSafe(executor, 'idx_shabads_source', 'shabads', 'source_id');
    await _createIndexSafe(executor, 'idx_shabads_writer', 'shabads', 'writer_id');
    await _createIndexSafe(executor, 'idx_shabads_raag', 'raags', 'id');
    await _createIndexSafe(executor, 'idx_verses_shabad', 'verses', 'shabad_id');
    await _createIndexSafe(executor, 'idx_verses_first_letter', 'verses', 'first_letter_str');
    await _createIndexSafe(executor, 'idx_verses_initials_en', 'verses', 'initials_en');
    await _createIndexSafe(executor, 'idx_verses_initials_pa', 'verses', 'initials_pa');
    await _createIndexSafe(executor, 'idx_bani_verses_bani', 'bani_verses', 'bani_id');
  }

  Future<void> _ensureColumnExists(QueryExecutor executor, String table, String column, String type) async {
    try {
      final columns = await executor.runSelect('PRAGMA table_info($table)', []);
      final hasColumn = columns.any((c) => c['name'] == column);
      if (!hasColumn) {
        await executor.runCustom('ALTER TABLE $table ADD COLUMN $column $type');
      }
    } catch (_) {}
  }

  Future<void> _createIndexSafe(QueryExecutor executor, String indexName, String table, String column) async {
    try {
      // Check if column exists in table
      final columns = await executor.runSelect('PRAGMA table_info($table)', []);
      final hasColumn = columns.any((c) => c['name'] == column);
      if (hasColumn) {
        await executor.runCustom('CREATE INDEX IF NOT EXISTS $indexName ON $table ($column)');
      }
    } catch (_) {}
  }

  Future<void> _createProductionSchema(QueryExecutor executor) async {
    await executor.runCustom('CREATE TABLE IF NOT EXISTS sources (id TEXT PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS writers (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS raags (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL)');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS shabads (id INTEGER PRIMARY KEY NOT NULL, source_id TEXT NOT NULL, writer_id INTEGER, raag_id INTEGER, ang INTEGER, FOREIGN KEY (source_id) REFERENCES sources (id), FOREIGN KEY (writer_id) REFERENCES writers (id), FOREIGN KEY (raag_id) REFERENCES raags (id))');
    await executor.runCustom('CREATE TABLE IF NOT EXISTS verses (id INTEGER PRIMARY KEY NOT NULL, shabad_id INTEGER NOT NULL, verse_order INTEGER NOT NULL, gurmukhi TEXT NOT NULL, transliteration TEXT, transliteration_hi TEXT, translation TEXT, translation_pa TEXT, first_letter_str TEXT NOT NULL, initials_en TEXT, initials_pa TEXT, main_letters TEXT, visraams TEXT, source_id TEXT, raag_id INTEGER, writer_id INTEGER, ang INTEGER, FOREIGN KEY (shabad_id) REFERENCES shabads (id) ON DELETE CASCADE)');
    
    // --- NITNEM / BANI EXTENSIONS ---
    // Stores the master list of Banis (Japji Sahib, Jaap Sahib, etc)
    await executor.runCustom('CREATE TABLE IF NOT EXISTS banis (id INTEGER PRIMARY KEY NOT NULL, name_pa TEXT NOT NULL, name_en TEXT NOT NULL, user_order INTEGER, updated_at TEXT)');
    
    // Junction table to map verses to Banis in a specific liturgical order.
    // Includes flags for different Maryada lengths (exists_sgpc, etc).
    await executor.runCustom('CREATE TABLE IF NOT EXISTS bani_verses (id INTEGER PRIMARY KEY AUTOINCREMENT, bani_id INTEGER NOT NULL, verse_id INTEGER NOT NULL, sequence_order INTEGER NOT NULL, header INTEGER, mangal_position INTEGER, exists_sgpc INTEGER, exists_medium INTEGER, exists_taksal INTEGER, exists_buddha_dal INTEGER, paragraph INTEGER, FOREIGN KEY (bani_id) REFERENCES banis (id) ON DELETE CASCADE, FOREIGN KEY (verse_id) REFERENCES verses (id) ON DELETE CASCADE)');

    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_verses_first_letter ON verses (first_letter_str)');
    await executor.runCustom('CREATE INDEX IF NOT EXISTS idx_bani_verses_bani ON bani_verses (bani_id)');
  }

  Future<void> _createTrackerSchema(QueryExecutor executor) async {
    // trackers: template_type, title, total_goal, daily_target, start_date, deadline_date, unit_name
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

    // tracker_logs: tracker_id, log_date, count, input_mode, created_at
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

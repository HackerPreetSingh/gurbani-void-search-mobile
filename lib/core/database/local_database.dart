import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import 'schema/metadata_schema.dart';
import 'schema/production_schema.dart';
import 'schema/tracker_schema.dart';

class LocalDatabase {
  LocalDatabase({required this.dbName, this._connection})
      : _connectionUser = _LocalDatabaseConnectionUser();
// ... (rest of the class)

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
    
    // Create auxiliary tables if they don't exist
    await MetadataSchema.create(executor);
    
    // Ensure core production schema
    await ProductionSchema.create(executor);
    
    // Create tracker schema
    await TrackerSchema.create(executor);
    
    // Column integrity checks
    await ProductionSchema.ensureColumns(executor);
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

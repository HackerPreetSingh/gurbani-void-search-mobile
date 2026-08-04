import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class LocalDatabase {
  LocalDatabase({DatabaseConnection? connection})
      : _connection = connection ?? _openConnection(),
        _connectionUser = _LocalDatabaseConnectionUser();

  static const schemaVersion = 4;

  final DatabaseConnection _connection;
  final _LocalDatabaseConnectionUser _connectionUser;
  Future<DatabaseStatus>? _initialization;

  Future<DatabaseStatus> initialize() async {
    final ongoingInitialization = _initialization;
    if (ongoingInitialization != null) {
      return ongoingInitialization;
    }

    final initialization = _initialize();
    _initialization = initialization;

    try {
      return await initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> close() => _connection.close();

  Future<T> read<T>(Future<T> Function(QueryExecutor executor) action) async {
    await initialize();
    return action(_connection);
  }

  Future<T> transaction<T>(
    Future<T> Function(QueryExecutor executor) action,
  ) async {
    await initialize();
    final transaction = _connection.beginTransaction();
    await transaction.ensureOpen(_connectionUser);

    try {
      final result = await action(transaction);
      await transaction.send();
      return result;
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }

  static DatabaseConnection _openConnection() {
    return driftDatabase(
      name: 'gurbani_search',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  Future<DatabaseStatus> _initialize() async {
    await _connection.ensureOpen(_connectionUser);

    final integrityCheck = await _connection.runSelect(
      'PRAGMA integrity_check',
      const [],
    );
    if (integrityCheck.single.values.single != 'ok') {
      throw const DatabaseIntegrityException();
    }

    final initializedAtUtc = await _readInitializedAtUtc();
    return DatabaseStatus(
      schemaVersion: schemaVersion,
      initializedAtUtc: initializedAtUtc,
    );
  }

  Future<DateTime> _readInitializedAtUtc() async {
    final result = await _connection.runSelect(
      'SELECT value FROM app_metadata WHERE key = ?',
      const ['initialized_at_utc'],
    );
    if (result.isEmpty) {
      return DateTime.now().toUtc();
    }
    final value = result.single['value']! as String;
    return DateTime.parse(value).toUtc();
  }
}

class _LocalDatabaseConnectionUser extends QueryExecutorUser {
  @override
  int get schemaVersion => LocalDatabase.schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    await executor.ensureOpen(this);
    await executor.runCustom('PRAGMA foreign_keys = ON');

    final previousVersion = details.versionBefore ?? 0;

    if (previousVersion < schemaVersion) {
      await executor.runCustom('BEGIN IMMEDIATE');
      try {
        if (previousVersion < 1) {
          await executor.runCustom('''
            CREATE TABLE app_metadata (
              key TEXT PRIMARY KEY NOT NULL,
              value TEXT NOT NULL,
              updated_at_utc TEXT NOT NULL
            )
          ''');

          final initializedAtUtc = DateTime.now().toUtc().toIso8601String();
          await executor.runCustom(
            '''
              INSERT INTO app_metadata (key, value, updated_at_utc)
              VALUES ('initialized_at_utc', ?, ?)
            ''',
            [initializedAtUtc, initializedAtUtc],
          );
        }

        // Cleanup any previous temporary schemas
        if (previousVersion < 4) {
          await executor.runCustom('DROP TABLE IF EXISTS verses_fts');
          await executor.runCustom('DROP TABLE IF EXISTS verses');
          await executor.runCustom('DROP TABLE IF EXISTS shabads');
          await executor.runCustom('DROP TABLE IF EXISTS gurbani_corpora');
          await executor.runCustom('DROP TABLE IF EXISTS gurmukhi_token_postings');
          await executor.runCustom('DROP TABLE IF EXISTS gurbani_lines');
          
          await _createProductionSchema(executor);
        }

        await executor.runCustom('COMMIT');
      } catch (_) {
        await executor.runCustom('ROLLBACK');
        rethrow;
      }
    }
  }

  Future<void> _createProductionSchema(QueryExecutor executor) async {
    // 1. Metadata Tables
    await executor.runCustom('''
      CREATE TABLE sources (
        id TEXT PRIMARY KEY NOT NULL,
        name_pa TEXT NOT NULL,
        name_en TEXT NOT NULL
      )
    ''');

    await executor.runCustom('''
      CREATE TABLE writers (
        id INTEGER PRIMARY KEY NOT NULL,
        name_pa TEXT NOT NULL,
        name_en TEXT NOT NULL
      )
    ''');

    await executor.runCustom('''
      CREATE TABLE raags (
        id INTEGER PRIMARY KEY NOT NULL,
        name_pa TEXT NOT NULL,
        name_en TEXT NOT NULL
      )
    ''');

    // 2. Main Tables
    await executor.runCustom('''
      CREATE TABLE shabads (
        id INTEGER PRIMARY KEY NOT NULL,
        source_id TEXT NOT NULL,
        writer_id INTEGER,
        raag_id INTEGER,
        ang INTEGER,
        FOREIGN KEY (source_id) REFERENCES sources (id),
        FOREIGN KEY (writer_id) REFERENCES writers (id),
        FOREIGN KEY (raag_id) REFERENCES raags (id)
      )
    ''');

    await executor.runCustom('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY NOT NULL,
        shabad_id INTEGER NOT NULL,
        verse_order INTEGER NOT NULL,
        gurmukhi TEXT NOT NULL,
        transliteration TEXT,
        translation TEXT,
        first_letter_str TEXT NOT NULL,
        main_letters TEXT,
        FOREIGN KEY (shabad_id) REFERENCES shabads (id) ON DELETE CASCADE
      )
    ''');

    // 3. Optimized Search Indexes
    await executor.runCustom('''
      CREATE INDEX idx_verses_first_letter 
      ON verses (first_letter_str)
    ''');
    
    await executor.runCustom('''
      CREATE INDEX idx_verses_shabad 
      ON verses (shabad_id, verse_order)
    ''');
  }
}

class DatabaseStatus {
  const DatabaseStatus({
    required this.schemaVersion,
    required this.initializedAtUtc,
  });

  final int schemaVersion;
  final DateTime initializedAtUtc;
}

class DatabaseIntegrityException implements Exception {
  const DatabaseIntegrityException();
  @override
  String toString() => 'The local database integrity check failed.';
}

class UnsupportedDatabaseSchemaException implements Exception {
  const UnsupportedDatabaseSchemaException({
    required this.databaseVersion,
    required this.supportedVersion,
  });

  final int databaseVersion;
  final int supportedVersion;

  @override
  String toString() {
    return 'Unsupported database schema \$databaseVersion; '
        'this app supports up to \$supportedVersion.';
  }
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class LocalDatabase {
  LocalDatabase({DatabaseConnection? connection})
    : _connection = connection ?? _openConnection(),
      _connectionUser = _LocalDatabaseConnectionUser();

  static const schemaVersion = 2;

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

  /// Runs a read or single-statement operation after the database is verified.
  Future<T> read<T>(Future<T> Function(QueryExecutor executor) action) async {
    await initialize();
    return action(_connection);
  }

  /// Runs [action] atomically and rolls it back if [action] throws.
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
    if (previousVersion > schemaVersion) {
      throw UnsupportedDatabaseSchemaException(
        databaseVersion: previousVersion,
        supportedVersion: schemaVersion,
      );
    }

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

        if (previousVersion < 2) {
          await _createSearchSchema(executor);
        }

        await executor.runCustom('COMMIT');
      } catch (_) {
        await executor.runCustom('ROLLBACK');
        rethrow;
      }
    }
  }

  Future<void> _createSearchSchema(QueryExecutor executor) async {
    await executor.runCustom('''
      CREATE TABLE gurbani_corpora (
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        version TEXT NOT NULL,
        language_tag TEXT NOT NULL,
        source_url TEXT NOT NULL,
        license_url TEXT NOT NULL,
        attribution TEXT NOT NULL,
        content_sha256 TEXT NOT NULL,
        imported_at_utc TEXT NOT NULL,
        line_count INTEGER NOT NULL CHECK (line_count >= 0),
        index_version INTEGER NOT NULL CHECK (index_version > 0),
        is_active INTEGER NOT NULL CHECK (is_active IN (0, 1))
      )
    ''');
    await executor.runCustom('''
      CREATE UNIQUE INDEX gurbani_corpora_single_active
      ON gurbani_corpora (is_active)
      WHERE is_active = 1
    ''');
    await executor.runCustom('''
      CREATE TABLE gurbani_lines (
        corpus_id TEXT NOT NULL,
        stable_id TEXT NOT NULL,
        display_order INTEGER NOT NULL CHECK (display_order >= 0),
        gurmukhi TEXT NOT NULL,
        normalized_gurmukhi TEXT NOT NULL,
        initial_key TEXT NOT NULL,
        source_name TEXT NOT NULL,
        writer_name TEXT,
        raag_name TEXT,
        ang INTEGER,
        PRIMARY KEY (corpus_id, stable_id),
        FOREIGN KEY (corpus_id) REFERENCES gurbani_corpora (id)
          ON DELETE CASCADE
      )
    ''');
    await executor.runCustom('''
      CREATE INDEX gurbani_lines_initial_lookup
      ON gurbani_lines (corpus_id, initial_key, display_order)
    ''');
    await executor.runCustom('''
      CREATE TABLE gurmukhi_token_postings (
        corpus_id TEXT NOT NULL,
        line_stable_id TEXT NOT NULL,
        token_position INTEGER NOT NULL CHECK (token_position >= 0),
        normalized_token TEXT NOT NULL,
        PRIMARY KEY (corpus_id, line_stable_id, token_position),
        FOREIGN KEY (corpus_id, line_stable_id)
          REFERENCES gurbani_lines (corpus_id, stable_id)
          ON DELETE CASCADE
      )
    ''');
    await executor.runCustom('''
      CREATE INDEX gurmukhi_token_postings_prefix_lookup
      ON gurmukhi_token_postings (
        corpus_id,
        normalized_token,
        line_stable_id
      )
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

class UnsupportedDatabaseSchemaException implements Exception {
  const UnsupportedDatabaseSchemaException({
    required this.databaseVersion,
    required this.supportedVersion,
  });

  final int databaseVersion;
  final int supportedVersion;

  @override
  String toString() {
    return 'Unsupported database schema $databaseVersion; '
        'this app supports up to $supportedVersion.';
  }
}

class DatabaseIntegrityException implements Exception {
  const DatabaseIntegrityException();

  @override
  String toString() => 'The local database integrity check failed.';
}

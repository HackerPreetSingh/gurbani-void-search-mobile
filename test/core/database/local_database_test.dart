import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gurbani_voice_search/core/database/local_database.dart';

void main() {
  group('LocalDatabase', () {
    late LocalDatabase database;

    setUp(() {
      database = LocalDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
    });

    tearDown(() => database.close());

    test('creates and verifies the versioned application database', () async {
      final status = await database.initialize();

      expect(status.schemaVersion, LocalDatabase.schemaVersion);
      expect(status.initializedAtUtc.isUtc, isTrue);
    });

    test('initialization is idempotent', () async {
      final firstStatus = await database.initialize();
      final secondStatus = await database.initialize();

      expect(secondStatus.schemaVersion, firstStatus.schemaVersion);
      expect(secondStatus.initializedAtUtc, firstStatus.initializedAtUtc);
    });
  });
}

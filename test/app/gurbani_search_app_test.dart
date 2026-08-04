import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gurbani_voice_search/app/gurbani_search_app.dart';
import 'package:gurbani_voice_search/core/database/local_database.dart';
import 'package:gurbani_voice_search/core/di/core_providers.dart';

void main() {
  testWidgets('starts with a verified local database foundation', (
    WidgetTester tester,
  ) async {
    final database = LocalDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localDatabaseProvider.overrideWithValue(database)],
        child: const GurbaniSearchApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gurbani Search'), findsWidgets);
    expect(find.text('Local SQLite storage verified'), findsOneWidget);
    expect(find.text('No Gurbani corpus is installed'), findsOneWidget);
  });
}

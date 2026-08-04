import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../database/local_database.dart';

final localDatabaseProvider = Provider<LocalDatabase>((Ref ref) {
  final database = LocalDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final databaseStatusProvider = FutureProvider<DatabaseStatus>((Ref ref) {
  return ref.watch(localDatabaseProvider).initialize();
});

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

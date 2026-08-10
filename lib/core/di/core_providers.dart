import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../database/local_database.dart';
import '../constants/app_constants.dart';

final dioProvider = Provider<Dio>((Ref ref) {
  return Dio();
});

final localDatabaseProvider = Provider<LocalDatabase>((Ref ref) {
  final database = LocalDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final databaseStatusProvider = FutureProvider<DatabaseStatus>((Ref ref) async {
  final start = DateTime.now();
  print('${AppConstants.logTag} [$start] START: databaseStatusProvider check');
  final db = ref.watch(localDatabaseProvider);
  
  if (kIsWeb) {
    print('${AppConstants.logTag} [${DateTime.now()}] WEB detected, initializing indexedDB directly');
    return await db.initialize();
  }

  // ABSOLUTE FAST PATH: Pure file-existence check only.
  final fileStart = DateTime.now();
  final exists = await db.databaseFileExists();
  final fileEnd = DateTime.now();
  print('${AppConstants.logTag} [$fileEnd] FILE_CHECK: exists=$exists, took: ${fileEnd.difference(fileStart).inMilliseconds}ms');

  if (!exists) {
    print('${AppConstants.logTag} [${DateTime.now()}] DB MISSING: Returning status with isAvailable=false');
    return DatabaseStatus(initializedAtUtc: DateTime.now().toUtc(), isAvailable: false);
  }
  
  final end = DateTime.now();
  print('${AppConstants.logTag} [$end] END: databaseStatusProvider check READY. Total check duration: ${end.difference(start).inMilliseconds}ms');
  return DatabaseStatus(initializedAtUtc: DateTime.now().toUtc(), isAvailable: true);
});

final databaseExistsProvider = FutureProvider<bool>((Ref ref) {
  return ref.watch(localDatabaseProvider).databaseFileExists();
});

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final router = createAppRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

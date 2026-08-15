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

final shabadDatabaseProvider = Provider<LocalDatabase>((Ref ref) {
  final database = LocalDatabase(dbName: AppConstants.shabadDbFile);
  ref.onDispose(() => database.close());
  return database;
});

final nitnemDatabaseProvider = Provider<LocalDatabase>((Ref ref) {
  final database = LocalDatabase(dbName: AppConstants.nitnemDbFile);
  ref.onDispose(() => database.close());
  return database;
});

final localDatabaseProvider = shabadDatabaseProvider;

final databaseStatusProvider = FutureProvider<DatabaseStatus>((Ref ref) async {
  final start = DateTime.now();
  print('${AppConstants.logTag} [$start] START: databaseStatusProvider check (Multi-DB)');
  
  final shabadDb = ref.watch(shabadDatabaseProvider);
  final nitnemDb = ref.watch(nitnemDatabaseProvider);
  
  if (kIsWeb) {
    await shabadDb.initialize();
    await nitnemDb.initialize();
    return DatabaseStatus(initializedAtUtc: DateTime.now().toUtc(), isAvailable: true);
  }

  // Check if BOTH essential databases exist
  final shabadExists = await shabadDb.databaseFileExists();
  final nitnemExists = await nitnemDb.databaseFileExists();

  if (!shabadExists || !nitnemExists) {
    print('${AppConstants.logTag} [${DateTime.now()}] DB MISSING: shabad=$shabadExists, nitnem=$nitnemExists');
    return DatabaseStatus(initializedAtUtc: DateTime.now().toUtc(), isAvailable: false);
  }
  
  // Actually initialize them if files exist
  await shabadDb.initialize();
  await nitnemDb.initialize();

  final end = DateTime.now();
  print('${AppConstants.logTag} [$end] END: databaseStatusProvider READY.');
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

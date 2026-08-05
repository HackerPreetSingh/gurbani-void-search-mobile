import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gurbani_voice_search/core/di/core_providers.dart';
import '../../data/sqlite_punjabi_search_repository.dart';
import '../repositories/punjabi_search_repository.dart';
import '../services/production_ingestor.dart';

final punjabiSearchRepositoryProvider = Provider<PunjabiSearchRepository>((Ref ref) {
  final database = ref.watch(localDatabaseProvider);
  return SqlitePunjabiSearchRepository(database);
});

final activeCorpusProvider = FutureProvider((Ref ref) {
  return ref.watch(punjabiSearchRepositoryProvider).activeCorpus();
});

final productionIngestorProvider = Provider((Ref ref) {
  final database = ref.watch(localDatabaseProvider);
  return ProductionIngestor(database);
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gurbani_voice_search/core/di/core_providers.dart';
import '../../data/local_search_data_source.dart';
import '../../data/metadata_data_source.dart';
import '../../data/remote_search_data_source.dart';
import '../../data/search_result_mapper.dart';
import '../../data/sqlite_punjabi_search_repository.dart';
import '../repositories/punjabi_search_repository.dart';
import '../services/production_ingestor.dart';
import '../services/vishram_service.dart';

final localSearchDataSourceProvider = Provider<LocalSearchDataSource>((ref) {
  final shabadDb = ref.watch(shabadDatabaseProvider);
  final nitnemDb = ref.watch(nitnemDatabaseProvider);
  return LocalSearchDataSource(shabadDb, nitnemDb);
});

final remoteSearchDataSourceProvider = Provider<RemoteSearchDataSource>((ref) {
  return RemoteSearchDataSource(Dio());
});

final metadataDataSourceProvider = Provider<MetadataDataSource>((ref) {
  final database = ref.watch(localDatabaseProvider);
  return MetadataDataSource(database);
});

final searchResultMapperProvider = Provider<SearchResultMapper>((ref) {
  final metadataDataSource = ref.watch(metadataDataSourceProvider);
  return SearchResultMapper(metadataDataSource);
});

final punjabiSearchRepositoryProvider = Provider<PunjabiSearchRepository>((ref) {
  return SqlitePunjabiSearchRepository(
    ref.watch(localSearchDataSourceProvider),
    ref.watch(remoteSearchDataSourceProvider),
    ref.watch(metadataDataSourceProvider),
    ref.watch(searchResultMapperProvider),
  );
});

final vishramServiceProvider = Provider<VishramService>((ref) {
  return VishramService();
});

final activeCorpusProvider = FutureProvider((Ref ref) {
  return ref.watch(punjabiSearchRepositoryProvider).activeCorpus();
});

final productionIngestorProvider = Provider((Ref ref) {
  final database = ref.watch(localDatabaseProvider);
  return ProductionIngestor(database);
});

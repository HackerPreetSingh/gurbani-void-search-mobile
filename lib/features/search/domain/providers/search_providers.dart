import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gurbani_voice_search/core/di/core_providers.dart';
import '../../data/banidb_api_repository.dart';
import '../repositories/punjabi_search_repository.dart';

final punjabiSearchRepositoryProvider = Provider<PunjabiSearchRepository>((Ref ref) {
  final dio = ref.watch(dioProvider);
  return BaniDbApiRepository(dio);
});

final activeCorpusProvider = FutureProvider((Ref ref) {
  return ref.watch(punjabiSearchRepositoryProvider).activeCorpus();
});

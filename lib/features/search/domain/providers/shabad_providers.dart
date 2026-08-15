import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gurbani_search_result.dart';
import 'search_providers.dart';

/// Fully offline provider for Shabad details.
final shabadDetailsProvider = FutureProvider.family<List<GurbaniSearchResult>, String>((ref, shabadId) async {
  // [AI_GUARD:PERMANENT_LOG] Fetching shabad details. Do not remove.
  print('[GURBANI_LOG] [${DateTime.now()}] [shabad_providers.dart] PROVIDER_FETCH: shabadId=$shabadId');
  
  final repository = ref.watch(punjabiSearchRepositoryProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());
  
  // Pull directly from the local SQLite database
  final results = await repository.getLocalShabad(shabadId, cancelToken: cancelToken);
  
  if (results.isEmpty) {
    print('[GURBANI_LOG] [${DateTime.now()}] [shabad_providers.dart] PROVIDER_RESULT: ShabadId $shabadId not found in local DB.');
    return [];
  }

  // [AI_GUARD:PERMANENT_LOG] Crucial: Force stable liturgical sorting by ID. 
  // API and local DB verse_order can be erratic. id/stableId is the only reliable sequence.
  results.sort((a, b) {
    final idA = int.tryParse(a.stableId) ?? 0;
    final idB = int.tryParse(b.stableId) ?? 0;
    return idA.compareTo(idB);
  });
  
  print('[GURBANI_LOG] [${DateTime.now()}] [shabad_providers.dart] PROVIDER_RESULT: ${results.length} verses sorted liturgically');
  return results;
});

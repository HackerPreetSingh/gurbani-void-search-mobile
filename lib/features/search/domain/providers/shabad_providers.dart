import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gurbani_search_result.dart';
import 'search_providers.dart';

/// Fully offline provider for Shabad details.
final shabadDetailsProvider = FutureProvider.family<List<GurbaniSearchResult>, String>((ref, shabadId) async {
  final repository = ref.watch(punjabiSearchRepositoryProvider);
  
  // Pull directly from the local SQLite database
  return await repository.getLocalShabad(shabadId);
});

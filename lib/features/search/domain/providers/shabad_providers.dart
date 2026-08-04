import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gurbani_voice_search/core/di/core_providers.dart';
import '../models/gurbani_search_result.dart';

final shabadDetailsProvider = FutureProvider.family<List<GurbaniSearchResult>, String>((ref, shabadId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('https://api.banidb.com/v2/shabads/$shabadId');
  
  final Map<String, dynamic> data = response.data as Map<String, dynamic>;
  final Map<String, dynamic>? shabadInfo = data['shabadInfo'] as Map<String, dynamic>?;
  final List<dynamic> versesRaw = data['verses'] ?? [];

  // Extract metadata from the Shabad-level info
  final String? shabadRaag = (shabadInfo?['raag'] as Map?)?['english']?.toString();
  final String? shabadWriter = (shabadInfo?['writer'] as Map?)?['english']?.toString();
  final String? shabadSource = (shabadInfo?['source'] as Map?)?['english']?.toString();
  final int? shabadAng = shabadInfo?['pageNo'] as int?;

  return versesRaw.map((v) {
    final Map<String, dynamic> verse = v as Map<String, dynamic>;
    final Map<String, dynamic>? verseObj = verse['verse'] as Map<String, dynamic>?;
    final Map<String, dynamic>? translit = verse['transliteration'] as Map<String, dynamic>?;
    final Map<String, dynamic>? translation = verse['translation'] as Map<String, dynamic>?;
    final Map<String, dynamic>? translationEn = translation?['en'] as Map<String, dynamic>?;

    return GurbaniSearchResult(
      stableId: (verse['verseId'] ?? verse['id'] ?? '0').toString(),
      shabadId: shabadId,
      gurmukhi: verseObj?['unicode'] ?? verse['gurmukhi'] ?? '',
      sourceName: shabadSource ?? 'Unknown',
      writerName: shabadWriter,
      raagName: shabadRaag,
      ang: shabadAng,
      displayOrder: verse['lineNo'] ?? 0,
      match: SearchResultMatch.word,
      transliteration: translit?['english'] ?? translit?['en'],
      translation: translationEn?['bdb'] ?? translationEn?['combined'],
    );
  }).toList();
});

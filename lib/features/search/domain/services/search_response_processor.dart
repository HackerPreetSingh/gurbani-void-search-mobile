import '../models/gurbani_search_result.dart';

class SearchResponseProcessor {
  static List<GurbaniSearchResult> filterAndPrioritize(List<GurbaniSearchResult> results) {
    final Set<String> primarySourceGurmukhi = {};
    for (final res in results) {
      final sIdInt = int.tryParse(res.shabadId ?? '0') ?? 0;
      final isPrimary = res.sourceName != 'Nitnem / Banis' && 
                      !res.sourceName.toLowerCase().contains('unknown') &&
                      sIdInt > 0 && sIdInt < 999999;
      
      if (isPrimary) {
        primarySourceGurmukhi.add(res.gurmukhi.trim());
      }
    }

    return results.where((res) {
      final sIdInt = int.tryParse(res.shabadId ?? '0') ?? 0;
      final isVirtual = res.sourceName == 'Nitnem / Banis' || 
                       res.sourceName.toLowerCase().contains('unknown') ||
                       sIdInt >= 999999 || sIdInt == 0;
                       
      if (isVirtual) {
         return !primarySourceGurmukhi.contains(res.gurmukhi.trim());
      }
      return true;
    }).toList();
  }
}

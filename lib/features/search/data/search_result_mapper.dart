import 'dart:convert';
import '../domain/models/gurbani_search_result.dart';
import 'metadata_data_source.dart';

class SearchResultMapper {
  SearchResultMapper(this._metadataDataSource);
  final MetadataDataSource _metadataDataSource;

  GurbaniSearchResult mapRow(Map<String, dynamic> r) {
    return GurbaniSearchResult(
      stableId: r['id'].toString(),
      shabadId: r['shabad_id'].toString(),
      gurmukhi: (r['gurmukhi'] as String?) ?? '',
      sourceName: _metadataDataSource.getSourceName(r['source_id'] as String),
      writerName: r['writer_id'] != null ? _metadataDataSource.getWriterName(r['writer_id'] as int) : null,
      raagName: r['raag_id'] != null ? _metadataDataSource.getRaagName(r['raag_id'] as int) : null,
      ang: r['ang'] as int?,
      displayOrder: (r['verse_order'] as int?) ?? 0,
      match: SearchResultMatch.initial,
      transliteration: r['transliteration'] as String?,
      transliterationHi: r['transliteration_hi'] as String?,
      translation: r['translation'] as String?,
      translationPa: r['translation_pa'] as String?,
      visraams: r['visraams'] as String?,
    );
  }

  GurbaniSearchResult mapApi(Map v, {Map<String, dynamic>? shabadInfo}) {
    final String? raag = _val(shabadInfo?['raag']?['english'] ?? v['raag']?['english'] ?? shabadInfo?['raag'] ?? v['raag']);
    final String? writer = _val(shabadInfo?['writer']?['english'] ?? v['writer']?['english'] ?? shabadInfo?['writer'] ?? v['writer']);
    final String? source = _val(shabadInfo?['source']?['english'] ?? v['source']?['english'] ?? shabadInfo?['source'] ?? v['source'] ?? 'Unknown');
    final int? ang = _toInt(shabadInfo?['pageNo'] ?? v['pageNo'] ?? v['source']?['pageNo'] ?? v['ang']);

    return GurbaniSearchResult(
      stableId: (v['verseId'] ?? v['id'] ?? 0).toString(),
      shabadId: (v['shabadId'] ?? 0).toString(),
      gurmukhi: _val(v['verse']?['unicode'] ?? v['gurmukhi'] ?? v['verse'] ?? '') ?? '',
      sourceName: source ?? 'Unknown',
      writerName: writer,
      raagName: raag,
      ang: ang,
      displayOrder: _toInt(v['lineNo'] ?? v['verseNo'] ?? 0) ?? 0,
      match: SearchResultMatch.initial,
      transliteration: _val(v['transliteration']?['english'] ?? v['transliteration']?['en']),
      transliterationHi: _val(v['transliteration']?['hindi'] ?? v['transliteration']?['hi']),
      translation: _val(v['translation']?['en']?['bdb'] ?? v['translation']?['en']?['combined'] ?? v['translation']?['en']),
      translationPa: _val(v['translation']?['pu']?['ss'] ?? v['translation']?['pu']?['ft'] ?? v['translation']?['pu']),
      visraams: v['visraam'] != null ? jsonEncode(v['visraam']['sttm2'] ?? v['visraam']['sttm'] ?? v['visraam'] ?? []) : null,
    );
  }

  String? _val(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) return (v['unicode'] ?? v['english'] ?? v['text'] ?? (v.isNotEmpty ? v.values.first : '')).toString();
    return v.toString();
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

  GurbaniSearchResult mapHistoryRow(Map<String, dynamic> r) {
    return GurbaniSearchResult(
      stableId: 'hist_${r['shabad_id']}',
      shabadId: r['shabad_id'].toString(),
      gurmukhi: (r['gurmukhi'] as String?) ?? '',
      sourceName: (r['source_name'] as String?) ?? 'Unknown',
      writerName: r['writer_name'] as String?,
      raagName: r['raag_name'] as String?,
      ang: r['ang'] as int?,
      displayOrder: 0,
      match: SearchResultMatch.initial,
    );
  }
}

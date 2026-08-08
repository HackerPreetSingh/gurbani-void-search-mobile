import 'package:flutter/foundation.dart';
import '../../../core/database/local_database.dart';

class MetadataDataSource {
  MetadataDataSource(this._database);
  final LocalDatabase _database;

  Map<String, String>? _sources;
  Map<int, String>? _writers;
  Map<int, String>? _raags;

  Future<void> ensureMetadataCached() async {
    if (_sources != null && _writers != null && _raags != null) return;

    try {
      final sourcesRows = await _database.read((executor) => executor.runSelect('SELECT id, name_en FROM sources', []));
      _sources = {for (final r in sourcesRows) r['id'] as String: r['name_en'] as String};

      final writersRows = await _database.read((executor) => executor.runSelect('SELECT id, name_en FROM writers', []));
      _writers = {for (final r in writersRows) r['id'] as int: r['name_en'] as String};

      final raagsRows = await _database.read((executor) => executor.runSelect('SELECT id, name_en FROM raags', []));
      _raags = {for (final r in raagsRows) r['id'] as int: r['name_en'] as String};
    } catch (e) {
      if (kDebugMode) print('Failed to cache metadata: $e');
      _sources ??= {};
      _writers ??= {};
      _raags ??= {};
    }
  }

  String getSourceName(String id) => _sources?[id] ?? 'Unknown';
  String? getWriterName(int id) => _writers?[id];
  String? getRaagName(int id) => _raags?[id];
}

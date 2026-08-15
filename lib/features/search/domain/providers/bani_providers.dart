import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/bani.dart';
import '../../data/search_result_mapper.dart';
import 'search_providers.dart';

final banisListProvider = AsyncNotifierProvider<BanisNotifier, List<Bani>>(() {
  return BanisNotifier();
});

class BanisNotifier extends AsyncNotifier<List<Bani>> {
  @override
  Future<List<Bani>> build() async {
    print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_FETCH: BanisNotifier');
    final db = ref.watch(localDatabaseProvider);
    final rows = await db.read((executor) => executor.runSelect('SELECT * FROM banis ORDER BY user_order ASC, id ASC', []));
    print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_RESULT: Found ${rows.length} banis in database');
    return rows.map((r) => Bani.fromMap(r)).toList();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentList = state.value;
    if (currentList == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final updatedList = List<Bani>.from(currentList);
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);

    // [AI_GUARD:PERMANENT_LOG] Optimistically update UI
    state = AsyncData(updatedList);

    // Save to DB
    final db = ref.read(localDatabaseProvider);
    try {
      await db.transaction((executor) async {
        for (int i = 0; i < updatedList.length; i++) {
          await executor.runCustom(
            'UPDATE banis SET user_order = ? WHERE id = ?',
            [i, updatedList[i].id],
          );
        }
      });
      print('${AppConstants.logTag} [${DateTime.now()}] BANI_REORDER_SUCCESS: New order saved to DB');
    } catch (e) {
      print('${AppConstants.logTag} [${DateTime.now()}] BANI_REORDER_ERROR: $e');
      // [AI_GUARD:PERMANENT_LOG] Rollback UI on error
      ref.invalidateSelf();
    }
  }
}

final baniDetailsProvider = FutureProvider.family<List<BaniVerse>, int>((ref, baniId) async {
  print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_FETCH: baniDetailsProvider(id: $baniId)');
  final db = ref.watch(localDatabaseProvider);
  
  // We need to join bani_verses with verses to get the content
  final rows = await db.read((executor) => executor.runSelect('''
    SELECT bv.*, v.*
    FROM bani_verses bv
    JOIN verses v ON bv.verse_id = v.id
    WHERE bv.bani_id = ?
    ORDER BY bv.sequence_order ASC
  ''', [baniId]));

  print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_RESULT: Fetched ${rows.length} verses for bani $baniId');
  final mapper = SearchResultMapper(ref.read(metadataDataSourceProvider));
  
  final results = rows.map((r) {
    // [AI_GUARD:PERMANENT_LOG] Use robust conversion to prevent type cast errors (String vs int)
    int? toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    bool toBool(dynamic v) => (int.tryParse(v?.toString() ?? '0') ?? 0) == 1;

    return BaniVerse(
      sequenceOrder: toInt(r['sequence_order']) ?? 0,
      header: toInt(r['header']) ?? 0,
      mangalPosition: toInt(r['mangal_position']),
      existsSGPC: toBool(r['exists_sgpc']),
      existsTaksal: toBool(r['exists_taksal']),
      verse: mapper.mapRow(r),
    );
  }).toList();

  // [AI_GUARD:PERMANENT_LOG] Force stable sorting by sequence_order to ensure liturgical accuracy.
  results.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
  
  return results;
});

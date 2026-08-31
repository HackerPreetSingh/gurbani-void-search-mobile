import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/bani.dart';
import 'search_providers.dart';

final banisListProvider = AsyncNotifierProvider<BanisNotifier, List<Bani>>(() {
  return BanisNotifier();
});

class BanisNotifier extends AsyncNotifier<List<Bani>> {
  @override
  Future<List<Bani>> build() async {
    print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_FETCH: BanisNotifier (Web: $kIsWeb)');
    
    if (kIsWeb) {
      final remote = ref.watch(remoteSearchDataSourceProvider);
      final List rows = await remote.getBanis();
      
      final defaultOrder = AppConstants.defaultBaniOrder;
      
      // Sort using the same custom liturgical logic as sync
      rows.sort((a, b) {
        final idA = a['ID'] as int;
        final idB = b['ID'] as int;
        final indexA = defaultOrder.indexOf(idA);
        final indexB = defaultOrder.indexOf(idB);
        
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return idA.compareTo(idB);
      });

      return rows.asMap().entries.map((entry) {
        final i = entry.key;
        final r = entry.value;
        return Bani(
          id: r['ID'],
          namePa: r['gurmukhiUni'] ?? r['gurmukhi'],
          nameEn: r['transliterations']?['english'] ?? r['transliteration'],
          userOrder: i,
          updatedAt: r['updated'],
        );
      }).toList();
    }

    final db = ref.watch(nitnemDatabaseProvider);
    final rows = await db.read((executor) => executor.runSelect('SELECT * FROM banis ORDER BY user_order ASC, id ASC', []));
    print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_RESULT: Found ${rows.length} banis in Nitnem database');
    
    final dbBanis = rows.map((r) => Bani.fromMap(r)).toList();
    
    // Inject SGGS if not present
    if (!dbBanis.any((b) => b.id == AppConstants.sggsVirtualId)) {
      dbBanis.add(Bani(
        id: AppConstants.sggsVirtualId,
        namePa: 'ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ',
        nameEn: 'Sri Guru Granth Sahib Ji',
        userOrder: -1, // Will be handled by sorting
      ));
    }

    final defaultOrder = AppConstants.defaultBaniOrder;
    dbBanis.sort((a, b) {
      final indexA = defaultOrder.indexOf(a.id);
      final indexB = defaultOrder.indexOf(b.id);
      
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.id.compareTo(b.id);
    });

    return dbBanis;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (kIsWeb) {
      // Reordering is only supported on native platforms for now
      return;
    }
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

    // Save to Nitnem DB
    final db = ref.read(nitnemDatabaseProvider);
    try {
      await db.transaction((executor) async {
        for (int i = 0; i < updatedList.length; i++) {
          await executor.runCustom(
            'UPDATE banis SET user_order = ? WHERE id = ?',
            [i, updatedList[i].id],
          );
        }
      });
      print('${AppConstants.logTag} [${DateTime.now()}] BANI_REORDER_SUCCESS: New order saved to Nitnem DB');
    } catch (e) {
      print('${AppConstants.logTag} [${DateTime.now()}] BANI_REORDER_ERROR: $e');
      // [AI_GUARD:PERMANENT_LOG] Rollback UI on error
      ref.invalidateSelf();
    }
  }
}

final baniDetailsProvider = FutureProvider.family<List<BaniVerse>, int>((ref, baniId) async {
  print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_FETCH: baniDetailsProvider(id: $baniId, Web: $kIsWeb)');
  final mapper = ref.read(searchResultMapperProvider);

  if (kIsWeb) {
    final remote = ref.watch(remoteSearchDataSourceProvider);
    final data = await remote.getBaniDetails(baniId);
    if (data == null) return [];
    
    final Map<String, dynamic>? baniInfo = data['baniInfo'] as Map<String, dynamic>?;
    final List verses = data['verses'] ?? [];
    
    return verses.asMap().entries.map((entry) {
      final i = entry.key;
      final v = entry.value;
      final verseData = v['verse'] ?? v;
      return BaniVerse(
        sequenceOrder: i,
        header: int.tryParse(v['header']?.toString() ?? '0') ?? 0,
        mangalPosition: int.tryParse(v['mangalPosition']?.toString() ?? ''),
        existsSGPC: (int.tryParse(v['existsSGPC']?.toString() ?? '0') ?? 0) == 1,
        existsTaksal: (int.tryParse(v['existsTaksal']?.toString() ?? '0') ?? 0) == 1,
        paragraph: int.tryParse(v['paragraph']?.toString() ?? ''),
        verse: mapper.mapApi(verseData, shabadInfo: baniInfo),
      );
    }).toList();
  }

  final db = ref.watch(nitnemDatabaseProvider);
  
  // We need to join bani_verses with verses to get the content from the Nitnem DB
  final rows = await db.read((executor) => executor.runSelect('''
    SELECT bv.*, v.*
    FROM bani_verses bv
    JOIN verses v ON bv.verse_id = v.id
    WHERE bv.bani_id = ?
    ORDER BY bv.sequence_order ASC
  ''', [baniId]));

  print('${AppConstants.logTag} [${DateTime.now()}] PROVIDER_RESULT: Fetched ${rows.length} verses for bani $baniId');
  
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
      paragraph: toInt(r['paragraph']),
      verse: mapper.mapRow(r),
    );
  }).toList();

  // [AI_GUARD:PERMANENT_LOG] Force stable sorting by sequence_order to ensure liturgical accuracy.
  results.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
  
  return results;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/di/core_providers.dart';
import '../domain/models/prakaran_models.dart';

class PrakaranRepository {
  final LocalDatabase _database;

  PrakaranRepository(this._database);

  Future<List<Prakaran>> getPrakarans() async {
    final rows = await _database.read((executor) => executor.runSelect('SELECT * FROM prakarans ORDER BY created_at DESC', []));
    return rows.map((r) => Prakaran.fromMap(r)).toList();
  }

  Future<void> createPrakaran(String name) async {
    final prakaran = Prakaran.create(name);
    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT INTO prakarans (id, name, created_at) VALUES (?, ?, ?)',
        [prakaran.id, prakaran.name, prakaran.createdAt.toIso8601String()],
      );
    });
  }

  Future<void> deletePrakaran(String id) async {
    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM prakarans WHERE id = ?', [id]);
    });
  }

  Future<void> addShabadToPrakaran({
    required String prakaranId,
    required String shabadId,
    required String titleGurmukhi,
  }) async {
    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT INTO prakaran_items (prakaran_id, shabad_id, title_gurmukhi, created_at) VALUES (?, ?, ?, ?)',
        [prakaranId, shabadId, titleGurmukhi, DateTime.now().toIso8601String()],
      );
    });
  }

  Future<List<PrakaranItem>> getItemsForPrakaran(String prakaranId) async {
    final rows = await _database.read((executor) => executor.runSelect(
      'SELECT * FROM prakaran_items WHERE prakaran_id = ? ORDER BY created_at ASC',
      [prakaranId],
    ));
    return rows.map((r) => PrakaranItem.fromMap(r)).toList();
  }

  Future<void> removeItemFromPrakaran(int itemId) async {
    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM prakaran_items WHERE id = ?', [itemId]);
    });
  }
}

final prakaranRepositoryProvider = Provider<PrakaranRepository>((ref) {
  final database = ref.watch(userTrackerDatabaseProvider);
  return PrakaranRepository(database);
});

final prakaransProvider = FutureProvider<List<Prakaran>>((ref) async {
  return ref.watch(prakaranRepositoryProvider).getPrakarans();
});

final prakaranItemsProvider = FutureProvider.family<List<PrakaranItem>, String>((ref, prakaranId) async {
  return ref.watch(prakaranRepositoryProvider).getItemsForPrakaran(prakaranId);
});

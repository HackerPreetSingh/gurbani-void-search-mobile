import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/prakaran_models.dart';
import '../data/prakaran_repository.dart';

class PrakaranDetailsScreen extends ConsumerWidget {
  final Prakaran prakaran;
  const PrakaranDetailsScreen({super.key, required this.prakaran});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(prakaranItemsProvider(prakaran.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(prakaran.name),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('This Prakaran is empty.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.titleGurmukhi, style: const TextStyle(fontSize: 18)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => _removeItem(ref, item.id!),
                ),
                onTap: () {
                  String path = '/shabad/${item.shabadId}';
                  if (item.verseId != null) {
                    path += '?verseId=${item.verseId}';
                  }
                  context.push(path);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _removeItem(WidgetRef ref, int itemId) async {
    await ref.read(prakaranRepositoryProvider).removeItemFromPrakaran(itemId);
    ref.invalidate(prakaranItemsProvider(prakaran.id));
  }
}

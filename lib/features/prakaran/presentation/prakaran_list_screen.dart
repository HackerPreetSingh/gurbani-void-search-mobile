import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prakaran_repository.dart';
import 'prakaran_details_screen.dart';

class PrakaranListScreen extends ConsumerWidget {
  const PrakaranListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prakaransAsync = ref.watch(prakaransProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prakarans'),
      ),
      body: prakaransAsync.when(
        data: (prakarans) {
          if (prakarans.isEmpty) {
            return const Center(
              child: Text('No Prakarans created yet.\nAdd a Shabad to a new Prakaran to get started.'),
            );
          }
          return ListView.builder(
            itemCount: prakarans.length,
            itemBuilder: (context, index) {
              final prakaran = prakarans[index];
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.teal),
                title: Text(prakaran.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, ref, prakaran.id),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrakaranDetailsScreen(prakaran: prakaran),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prakaran?'),
        content: const Text('This will permanently remove this folder and all references to shabads inside it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Clear items from cache before deleting the folder
              ref.invalidate(prakaranItemsProvider(id));
              await ref.read(prakaranRepositoryProvider).deletePrakaran(id);
              ref.invalidate(prakaransProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

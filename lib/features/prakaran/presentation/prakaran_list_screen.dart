import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/display_settings_notifier.dart';
import '../data/prakaran_repository.dart';
import '../domain/models/prakaran_models.dart';
import 'prakaran_details_screen.dart';

class PrakaranListScreen extends ConsumerWidget {
  const PrakaranListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prakaransAsync = ref.watch(prakaransProvider);
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;

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
                title: Text(prakaran.name, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                      onPressed: () => _showEditDialog(context, ref, prakaran),
                      tooltip: 'Edit Name',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, ref, prakaran.id),
                      tooltip: 'Delete',
                    ),
                  ],
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

  void _showEditDialog(BuildContext context, WidgetRef ref, Prakaran prakaran) {
    final controller = TextEditingController(text: prakaran.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Prakaran Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Prakaran Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != prakaran.name) {
                await ref.read(prakaranRepositoryProvider).renamePrakaran(prakaran.id, newName);
                ref.invalidate(prakaransProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
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

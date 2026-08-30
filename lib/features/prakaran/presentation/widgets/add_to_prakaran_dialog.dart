import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/prakaran_repository.dart';

class AddToPrakaranDialog extends ConsumerStatefulWidget {
  final String shabadId;
  final String titleGurmukhi;

  const AddToPrakaranDialog({
    super.key,
    required this.shabadId,
    required this.titleGurmukhi,
  });

  @override
  ConsumerState<AddToPrakaranDialog> createState() => _AddToPrakaranDialogState();
}

class _AddToPrakaranDialogState extends ConsumerState<AddToPrakaranDialog> {
  final _newPrakaranController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _newPrakaranController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prakaransAsync = ref.watch(prakaransProvider);

    return AlertDialog(
      title: const Text('Add to Prakaran'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isCreatingNew) ...[
              prakaransAsync.when(
                data: (prakarans) {
                  if (prakarans.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No Prakarans created yet.'),
                    );
                  }
                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: prakarans.length,
                      itemBuilder: (context, index) {
                        final prakaran = prakarans[index];
                        return ListTile(
                          title: Text(prakaran.name),
                          onTap: () => _addToExisting(prakaran.id),
                        );
                      },
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const Divider(),
              TextButton.icon(
                onPressed: () => setState(() => _isCreatingNew = true),
                icon: const Icon(Icons.add),
                label: const Text('Create New Prakaran'),
              ),
            ] else ...[
              TextField(
                controller: _newPrakaranController,
                decoration: const InputDecoration(
                  labelText: 'Prakaran Name',
                  hintText: 'e.g. Morning Prayers',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isCreatingNew = false),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _createAndAdd,
                    child: const Text('Create & Add'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isCreatingNew)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Future<void> _addToExisting(String prakaranId) async {
    await ref.read(prakaranRepositoryProvider).addShabadToPrakaran(
      prakaranId: prakaranId,
      shabadId: widget.shabadId,
      titleGurmukhi: widget.titleGurmukhi,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Prakaran')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _createAndAdd() async {
    final name = _newPrakaranController.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(prakaranRepositoryProvider);
    await repo.createPrakaran(name);
    
    // Refresh list to get the new ID
    final updatedList = await repo.getPrakarans();
    final newPrakaran = updatedList.firstWhere((p) => p.name == name);

    await repo.addShabadToPrakaran(
      prakaranId: newPrakaran.id,
      shabadId: widget.shabadId,
      titleGurmukhi: widget.titleGurmukhi,
    );

    ref.invalidate(prakaransProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prakaran created and Shabad added')),
      );
      Navigator.pop(context);
    }
  }
}

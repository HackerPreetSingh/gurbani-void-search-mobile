import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/providers/bani_providers.dart';

class NitnemScreen extends ConsumerWidget {
  const NitnemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('${AppConstants.logTag} [${DateTime.now()}] WIDGET_BUILD: NitnemScreen');
    final banisAsync = ref.watch(banisListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nitnem & Banis'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.drag_handle, color: Colors.grey),
          ),
        ],
      ),
      body: banisAsync.when(
        data: (banis) {
          if (banis.isEmpty) {
            return const Center(
              child: Text('No Banis found. Please run the sync utility.'),
            );
          }
          return ReorderableListView.builder(
            itemCount: banis.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(banisListProvider.notifier).reorder(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final bani = banis[index];
              return ListTile(
                key: ValueKey(bani.id),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.menu_book, size: 20, color: Colors.teal),
                ),
                title: Text(
                  bani.namePa,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(bani.nameEn),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/nitnem/${bani.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

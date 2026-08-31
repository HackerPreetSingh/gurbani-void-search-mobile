import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/core_providers.dart';
import '../../foundation/presentation/foundation_page.dart';
import '../domain/providers/bani_providers.dart';

class NitnemScreen extends ConsumerWidget {
  const NitnemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbStatus = ref.watch(databaseStatusProvider);

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
      body: dbStatus.when(
        data: (status) {
          if (!status.isAvailable) {
            return const FoundationPage();
          }
          return _buildNitnemContent(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNitnemContent(BuildContext context, WidgetRef ref) {
    print('${AppConstants.logTag} [${DateTime.now()}] WIDGET_BUILD: NitnemScreen');
    final banisAsync = ref.watch(banisListProvider);

    return banisAsync.when(
      data: (banis) {
        if (banis.isEmpty) {
          return const Center(
            child: Text('No Banis found. Please run the sync utility.'),
          );
        }
        return ReorderableListView.builder(
          itemCount: banis.length,
          onReorderItem: (oldIndex, newIndex) {
            ref.read(banisListProvider.notifier).reorder(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final bani = banis[index];
            return ListTile(
              key: ValueKey(bani.id),
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade50,
                radius: 24,
                child: const Icon(Icons.menu_book, size: 24, color: Colors.teal),
              ),
              title: Text(
                bani.namePa,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                if (bani.id == AppConstants.sggsVirtualId) {
                  context.push('/sggs/1');
                  return;
                }

                // [AI_GUARD:PERMANENT_LOG] Starting pre-load for smooth bani transition
                print('${AppConstants.logTag} [nitnem_screen.dart] UI_ACTION: Pre-loading bani ${bani.id}...');
                
                // Wait for the data to be in cache
                await ref.read(baniDetailsProvider(bani.id).future);
                
                if (context.mounted) {
                  print('${AppConstants.logTag} [nitnem_screen.dart] UI_ACTION: Pre-load complete. Pushing bani page.');
                  context.push('/nitnem/${bani.id}');
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

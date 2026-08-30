import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/tracker_models.dart';
import 'tracker_view_model.dart';
import 'progress_update_modal.dart';
import 'tracker_creation_wizard.dart';
import 'widgets/tracker_summary_card.dart';
import 'widgets/tracker_history_list.dart';

class TrackerDetailsPage extends ConsumerWidget {
  final String trackerId;
  const TrackerDetailsPage({super.key, required this.trackerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(trackerViewModelProvider);

    return trackersAsync.when(
      data: (trackers) {
        final goal = trackers.firstWhere((t) => t.id == trackerId);
        final dailyAggsAsync = ref.watch(trackerDailyAggsProvider(trackerId));

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditTracker(context, goal),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => ref.invalidate(trackerDailyAggsProvider(trackerId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrackerSummaryCard(goal: goal),
                  const SizedBox(height: 24),
                  _buildUpdateAction(context, ref, goal),
                  const SizedBox(height: 32),
                  const Text('Daily History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  dailyAggsAsync.when(
                    data: (aggs) => TrackerHistoryList(
                      aggregations: aggs,
                      goal: goal,
                      onEditLog: (log) => _showEditLog(context, ref, goal, log),
                      onDeleteLog: (id) => _confirmDeleteLog(context, ref, id),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading history: $e'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildUpdateAction(BuildContext context, WidgetRef ref, TrackerGoal goal) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showUpdateModal(context, ref, goal),
        icon: const Icon(Icons.add_task),
        label: const Text('Update Progress'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  void _showUpdateModal(BuildContext context, WidgetRef ref, TrackerGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProgressUpdateModal(goal: goal),
    ).then((_) {
      ref.invalidate(trackerDailyAggsProvider(goal.id));
      ref.invalidate(trackerViewModelProvider);
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tracker?'),
        content: const Text('This will permanently remove all progress logs for this goal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(trackerViewModelProvider.notifier).deleteTracker(trackerId);
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/tracker');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTracker(BuildContext context, TrackerGoal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackerCreationWizard(editGoal: goal),
      ),
    );
  }

  void _showEditLog(BuildContext context, WidgetRef ref, TrackerGoal goal, TrackerLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProgressUpdateModal(goal: goal, editLog: log),
    ).then((_) {
      ref.invalidate(trackerDailyAggsProvider(goal.id));
      ref.invalidate(trackerViewModelProvider);
    });
  }

  void _confirmDeleteLog(BuildContext context, WidgetRef ref, int logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This will remove this specific progress chunk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(trackerViewModelProvider.notifier).deleteLog(logId);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(trackerDailyAggsProvider(trackerId));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

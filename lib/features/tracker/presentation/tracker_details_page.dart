import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/models/tracker_models.dart';
import '../domain/services/tracker_analytics_service.dart';
import 'tracker_view_model.dart';
import 'progress_update_modal.dart';
import 'tracker_creation_wizard.dart';

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
                  _buildSummaryCard(context, ref, goal),
                  const SizedBox(height: 24),
                  Center(
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
                  ),
                  const SizedBox(height: 32),
                  const Text('Daily History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  dailyAggsAsync.when(
                    data: (aggs) => _buildHistoryTable(context, ref, aggs, goal),
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

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, TrackerGoal goal) {
    return FutureBuilder<TrackerStatus>(
      future: ref.read(trackerViewModelProvider.notifier).getStatus(goal),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final status = snapshot.data!;
        final analytics = TrackerAnalyticsService();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Done', analytics.formatCount(status.totalDone, goal.templateType)),
                    if (status.totalRemaining != null)
                      _buildStatItem('Remaining', analytics.formatCount(status.totalRemaining!, goal.templateType)),
                  ],
                ),
                const Divider(height: 32),
                _buildStatusIndicator(status, goal),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start: ${DateFormat('MMM dd, yyyy').format(goal.startDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (goal.deadlineDate != null)
                      Text('Deadline: ${DateFormat('MMM dd, yyyy').format(goal.deadlineDate!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
      ],
    );
  }

  Widget _buildStatusIndicator(TrackerStatus status, TrackerGoal goal) {
    if (goal.dailyTarget == null) {
      return Text(
        'Average: ${status.averagePerDay.toStringAsFixed(1)} ${goal.unitName} / day',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      );
    }

    Color color = Colors.orange;
    String text = 'On Track';
    IconData icon = Icons.check_circle_outline;

    if (status.trend == TrackerTrend.ahead) {
      color = Colors.green;
      text = 'Ahead by ${TrackerAnalyticsService().formatCount(status.diffFromExpected.abs(), goal.templateType)}';
      icon = Icons.trending_up;
    } else if (status.trend == TrackerTrend.behind) {
      color = Colors.red;
      text = 'Behind by ${TrackerAnalyticsService().formatCount(status.diffFromExpected.abs(), goal.templateType)}';
      icon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context, WidgetRef ref, List<TrackerDailyAggregation> aggs, TrackerGoal goal) {
    if (aggs.isEmpty) return const Center(child: Text('No logs found yet.'));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: aggs.length,
      itemBuilder: (context, index) {
        final agg = aggs[index];
        Color rowColor = Colors.grey.shade400;

        IconData? trendIcon;
        if (goal.dailyTarget != null) {
          if (agg.totalCount == goal.dailyTarget) {
            rowColor = Colors.orange;
            trendIcon = Icons.trending_flat;
          } else if (agg.totalCount > goal.dailyTarget!) {
            rowColor = Colors.green;
            trendIcon = Icons.trending_up;
          } else {
            rowColor = Colors.red;
            trendIcon = Icons.trending_down;
          }
        }

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: CircleAvatar(
              backgroundColor: rowColor.withAlpha(40),
              radius: 18,
              child: Icon(trendIcon ?? Icons.calendar_today, color: rowColor, size: 18),
            ),
            title: Text(DateFormat('EEEE, MMM dd').format(agg.date), style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(
              TrackerAnalyticsService().formatCount(agg.totalCount, goal.templateType),
              style: TextStyle(fontWeight: FontWeight.bold, color: rowColor == Colors.grey.shade400 ? Colors.black : rowColor),
            ),
            children: agg.logs.map((log) => ListTile(
              dense: true,
              title: Text('Chunk at ${DateFormat('HH:mm').format(log.createdAt)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(TrackerAnalyticsService().formatCount(log.count, goal.templateType)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                    onPressed: () => _showEditLog(context, ref, goal, log),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteLog(context, ref, log.id!),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      },
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
                Navigator.pop(context); // Close dialog
                context.go('/tracker'); // Proper navigation back to list
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

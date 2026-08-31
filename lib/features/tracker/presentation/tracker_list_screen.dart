import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/tracker_models.dart';
import 'tracker_view_model.dart';
import '../domain/services/tracker_analytics_service.dart';

class TrackerListScreen extends ConsumerWidget {
  const TrackerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(trackerViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nitnem Tracker'),
      ),
      body: trackersAsync.when(
        data: (trackers) {
          if (trackers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.track_changes, size: 64, color: Colors.teal.shade200),
                  const SizedBox(height: 16),
                  const Text('No active trackers found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/tracker/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Start New Nitnem'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trackers.length,
            itemBuilder: (context, index) {
              final goal = trackers[index];
              return Dismissible(
                key: Key('tracker_${goal.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (direction) => _confirmDelete(context, ref, goal.id),
                onDismissed: (direction) {
                  ref.read(trackerViewModelProvider.notifier).deleteTracker(goal.id);
                },
                child: _TrackerCard(goal: goal),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: trackersAsync.hasValue && trackersAsync.value!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/tracker/create'),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tracker?'),
        content: const Text('This will permanently remove all progress logs for this goal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends ConsumerWidget {
  final TrackerGoal goal;
  const _TrackerCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/tracker/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildTypeBadge(goal.templateType),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<TrackerStatus>(
                future: ref.read(trackerViewModelProvider.notifier).getStatus(goal),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final status = snapshot.data!;
                  
                  return Column(
                    children: [
                      if (goal.totalGoal != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${status.completionPercentage.toStringAsFixed(1)}% Complete'),
                            Text('${status.totalDone} / ${goal.totalGoal} ${goal.unitName}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: status.completionPercentage / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTrendInfo(status, goal),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (status.expectedPerDay != null)
                                Text(
                                  'Expected: ${status.expectedPerDay} / day',
                                  style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w500),
                                ),
                              Text(
                                'Avg: ${status.averagePerDay.toStringAsFixed(1)} / day',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TrackerTemplateType type) {
    String label = 'Custom';
    IconData icon = Icons.edit;
    Color color = Colors.blueGrey;

    switch (type) {
      case TrackerTemplateType.moolMantar:
        label = 'Mool Mantar';
        icon = Icons.auto_awesome;
        color = Colors.orange;
        break;
      case TrackerTemplateType.waheguruSimran:
        label = 'Simran';
        icon = Icons.favorite;
        color = Colors.redAccent;
        break;
      case TrackerTemplateType.baniCount:
        label = 'Bani';
        icon = Icons.menu_book;
        color = Colors.teal;
        break;
      case TrackerTemplateType.sehajPath:
        label = 'Sehaj Path';
        icon = Icons.library_books;
        color = Colors.purple;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrendInfo(TrackerStatus status, TrackerGoal goal) {
    if (goal.dailyTarget == null) return const SizedBox.shrink();
    
    Color color = Colors.grey;
    IconData icon = Icons.trending_flat;
    String label = 'On Track';

    if (status.trend == TrackerTrend.ahead) {
      color = Colors.green;
      icon = Icons.trending_up;
      label = 'Ahead';
    } else if (status.trend == TrackerTrend.behind) {
      color = Colors.red;
      icon = Icons.trending_down;
      label = 'Behind';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          '(${TrackerAnalyticsService().formatCount(status.diffFromExpected.abs(), goal.templateType)})',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/tracker_models.dart';
import '../../domain/services/tracker_analytics_service.dart';
import '../tracker_view_model.dart';

class TrackerSummaryCard extends ConsumerWidget {
  final TrackerGoal goal;

  const TrackerSummaryCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}

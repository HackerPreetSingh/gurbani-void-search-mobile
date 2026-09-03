import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../settings/presentation/display_settings_notifier.dart';
import '../../domain/models/tracker_models.dart';
import '../../domain/services/tracker_analytics_service.dart';
import '../tracker_view_model.dart';

class TrackerSummaryCard extends ConsumerWidget {
  final TrackerGoal goal;

  const TrackerSummaryCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;

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
                    _buildStatItem('Total Done', analytics.formatCount(status.totalDone, goal.templateType), isBold),
                    if (status.totalRemaining != null)
                      _buildStatItem('Remaining', analytics.formatCount(status.totalRemaining!, goal.templateType), isBold),
                  ],
                ),
                const Divider(height: 32),
                _buildStatusIndicator(status, goal, isBold),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start: ${DateFormat('MMM dd, yyyy').format(goal.startDate)}', style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey)),
                    if (goal.deadlineDate != null)
                      Text('Deadline: ${DateFormat('MMM dd, yyyy').format(goal.deadlineDate!)}', style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, bool isBold) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: Colors.teal)),
      ],
    );
  }

  Widget _buildStatusIndicator(TrackerStatus status, TrackerGoal goal, bool isBold) {
    if (goal.dailyTarget == null) {
      return Text(
        'Average: ${status.averagePerDay.toStringAsFixed(1)} ${goal.unitName} / day',
        style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(text, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Expected: ${status.expectedPerDay} ${goal.unitName} / day',
              style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.teal),
            ),
            const SizedBox(width: 16),
            Text(
              'Avg: ${status.averagePerDay.toStringAsFixed(1)} / day',
              style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

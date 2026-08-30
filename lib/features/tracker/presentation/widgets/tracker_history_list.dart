import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/tracker_models.dart';
import '../../domain/services/tracker_analytics_service.dart';

class TrackerHistoryList extends StatelessWidget {
  final List<TrackerDailyAggregation> aggregations;
  final TrackerGoal goal;
  final Function(TrackerLog) onEditLog;
  final Function(int) onDeleteLog;

  const TrackerHistoryList({
    super.key,
    required this.aggregations,
    required this.goal,
    required this.onEditLog,
    required this.onDeleteLog,
  });

  @override
  Widget build(BuildContext context) {
    if (aggregations.isEmpty) return const Center(child: Text('No logs found yet.'));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: aggregations.length,
      itemBuilder: (context, index) {
        final agg = aggregations[index];
        final rowColor = _getRowColor(agg, goal);
        final trendIcon = _getTrendIcon(agg, goal);

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
              child: Icon(trendIcon, color: rowColor, size: 18),
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
                    onPressed: () => onEditLog(log),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                    onPressed: () => onDeleteLog(log.id!),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Color _getRowColor(TrackerDailyAggregation agg, TrackerGoal goal) {
    if (goal.dailyTarget == null) return Colors.grey.shade400;
    if (agg.totalCount == goal.dailyTarget) return Colors.orange;
    if (agg.totalCount > goal.dailyTarget!) return Colors.green;
    return Colors.red;
  }

  IconData _getTrendIcon(TrackerDailyAggregation agg, TrackerGoal goal) {
    if (goal.dailyTarget == null) return Icons.calendar_today;
    if (agg.totalCount == goal.dailyTarget) return Icons.trending_flat;
    if (agg.totalCount > goal.dailyTarget!) return Icons.trending_up;
    return Icons.trending_down;
  }
}

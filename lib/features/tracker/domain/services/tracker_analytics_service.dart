import '../models/tracker_models.dart';

class TrackerAnalyticsService {
  TrackerStatus calculateStatus(TrackerGoal goal, List<TrackerLog> logs) {
    final totalDone = logs.fold<int>(0, (sum, l) => sum + l.count);
    final totalRemaining = goal.totalGoal != null ? (goal.totalGoal! - totalDone) : null;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(goal.startDate.year, goal.startDate.month, goal.startDate.day);
    
    final daysElapsed = today.difference(start).inDays + 1;
    final averagePerDay = daysElapsed > 0 ? totalDone / daysElapsed : totalDone.toDouble();
    
    int diffFromExpected = 0;
    TrackerTrend trend = TrackerTrend.neutral;

    if (goal.dailyTarget != null) {
      final expectedToDate = goal.dailyTarget! * daysElapsed;
      diffFromExpected = totalDone - expectedToDate;
      
      // Threshold for "On Track" is 10% of daily target
      final threshold = goal.dailyTarget! * 0.1;
      
      if (diffFromExpected > threshold) {
        trend = TrackerTrend.ahead;
      } else if (diffFromExpected < -threshold) {
        trend = TrackerTrend.behind;
      } else {
        trend = TrackerTrend.onTrack;
      }
    }

    double percentage = 0;
    if (goal.totalGoal != null && goal.totalGoal! > 0) {
      percentage = (totalDone / goal.totalGoal!) * 100;
      if (percentage > 100) percentage = 100;
    }

    return TrackerStatus(
      totalDone: totalDone,
      totalRemaining: totalRemaining != null && totalRemaining < 0 ? 0 : totalRemaining,
      diffFromExpected: diffFromExpected,
      trend: trend,
      completionPercentage: percentage,
      daysElapsed: daysElapsed,
      averagePerDay: averagePerDay,
    );
  }

  /// Calculates the required daily target to finish by a certain date.
  int calculateRequiredDailyTarget(int totalGoal, DateTime start, DateTime deadline) {
    final days = deadline.difference(start).inDays + 1;
    if (days <= 0) return totalGoal;
    return (totalGoal / days).ceil();
  }

  String formatCount(int count, TrackerTemplateType type) {
    if (type == TrackerTemplateType.moolMantar || type == TrackerTemplateType.waheguruSimran) {
      final maala = count ~/ 108;
      final raw = count % 108;
      if (maala > 0 && raw > 0) return '$maala Maala, $raw Units';
      if (maala > 0) return '$maala Maala';
      return '$raw Units';
    }
    if (type == TrackerTemplateType.sehajPath) return '$count Angs';
    return '$count Paths';
  }
}

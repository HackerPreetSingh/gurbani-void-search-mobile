import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/di/core_providers.dart';
import '../domain/models/tracker_models.dart';

class TrackerRepository {
  final LocalDatabase _database;

  TrackerRepository(this._database);

  Future<List<TrackerGoal>> getTrackers() async {
    final rows = await _database.read((executor) => executor.runSelect('SELECT * FROM trackers ORDER BY created_at DESC', []));
    return rows.map((r) => TrackerGoal.fromMap(r)).toList();
  }

  Future<TrackerGoal?> getTracker(String id) async {
    final rows = await _database.read((executor) => executor.runSelect('SELECT * FROM trackers WHERE id = ?', [id]));
    if (rows.isEmpty) return null;
    return TrackerGoal.fromMap(rows.first);
  }

  Future<void> createTracker(TrackerGoal goal) async {
    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT INTO trackers (id, template_type, title, total_goal, daily_target, start_date, deadline_date, unit_name, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          goal.id,
          goal.templateType.name,
          goal.title,
          goal.totalGoal,
          goal.dailyTarget,
          goal.startDate.toIso8601String(),
          goal.deadlineDate?.toIso8601String(),
          goal.unitName,
          goal.createdAt.toIso8601String(),
        ],
      );
    });
  }

  Future<void> updateTracker(TrackerGoal goal) async {
    await _database.transaction((executor) async {
      await executor.runCustom(
        'UPDATE trackers SET template_type = ?, title = ?, total_goal = ?, daily_target = ?, start_date = ?, deadline_date = ?, unit_name = ? WHERE id = ?',
        [
          goal.templateType.name,
          goal.title,
          goal.totalGoal,
          goal.dailyTarget,
          goal.startDate.toIso8601String(),
          goal.deadlineDate?.toIso8601String(),
          goal.unitName,
          goal.id,
        ],
      );
    });
  }

  Future<void> deleteTracker(String id) async {
    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM trackers WHERE id = ?', [id]);
    });
  }

  Future<void> addLog(TrackerLog log) async {
    await _database.transaction((executor) async {
      final map = log.toMap();
      await executor.runCustom(
        'INSERT INTO tracker_logs (tracker_id, log_date, count, input_mode, created_at) VALUES (?, ?, ?, ?, ?)',
        [
          map['tracker_id'],
          map['log_date'],
          map['count'],
          map['input_mode'],
          map['created_at'],
        ],
      );
    });
  }

  Future<void> deleteLog(int id) async {
    await _database.transaction((executor) async {
      await executor.runCustom('DELETE FROM tracker_logs WHERE id = ?', [id]);
    });
  }

  Future<void> updateLog(TrackerLog log) async {
    await _database.transaction((executor) async {
      final map = log.toMap();
      await executor.runCustom(
        'UPDATE tracker_logs SET log_date = ?, count = ?, input_mode = ? WHERE id = ?',
        [
          map['log_date'],
          map['count'],
          map['input_mode'],
          log.id,
        ],
      );
    });
  }

  Future<List<TrackerLog>> getLogsForTracker(String trackerId) async {
    final rows = await _database.read((executor) => executor.runSelect(
      'SELECT * FROM tracker_logs WHERE tracker_id = ? ORDER BY log_date DESC, created_at DESC',
      [trackerId],
    ));
    return rows.map((r) => TrackerLog.fromMap(r)).toList();
  }

  Future<List<TrackerDailyAggregation>> getDailyAggregations(String trackerId) async {
    final logs = await getLogsForTracker(trackerId);
    if (logs.isEmpty) return [];

    final Map<String, List<TrackerLog>> grouped = {};
    for (var log in logs) {
      final key = log.logDate.toIso8601String().split('T')[0];
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final List<TrackerDailyAggregation> result = [];
    grouped.forEach((dateStr, dailyLogs) {
      final total = dailyLogs.fold<int>(0, (sum, l) => sum + l.count);
      result.add(TrackerDailyAggregation(
        date: DateTime.parse(dateStr),
        totalCount: total,
        logs: dailyLogs,
      ));
    });

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }
}

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final database = ref.watch(userTrackerDatabaseProvider);
  return TrackerRepository(database);
});

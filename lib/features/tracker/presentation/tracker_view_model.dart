import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/tracker_repository.dart';
import '../domain/models/tracker_models.dart';
import '../domain/services/tracker_analytics_service.dart';

final trackerViewModelProvider = AsyncNotifierProvider<TrackerViewModel, List<TrackerGoal>>(() {
  return TrackerViewModel();
});

class TrackerViewModel extends AsyncNotifier<List<TrackerGoal>> {
  @override
  Future<List<TrackerGoal>> build() async {
    return ref.watch(trackerRepositoryProvider).getTrackers();
  }

  Future<void> createTracker({
    required TrackerTemplateType type,
    required String title,
    int? totalGoal,
    int? dailyTarget,
    required DateTime startDate,
    DateTime? deadlineDate,
    required String unitName,
  }) async {
    final goal = TrackerGoal(
      id: const Uuid().v4(),
      templateType: type,
      title: title,
      totalGoal: totalGoal,
      dailyTarget: dailyTarget,
      startDate: startDate,
      deadlineDate: deadlineDate,
      unitName: unitName,
      createdAt: DateTime.now(),
    );

    await ref.read(trackerRepositoryProvider).createTracker(goal);
    ref.invalidateSelf();
  }

  Future<void> updateTracker(TrackerGoal goal) async {
    await ref.read(trackerRepositoryProvider).updateTracker(goal);
    ref.invalidateSelf();
  }

  Future<void> deleteTracker(String id) async {
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncValue.data(previousState.where((t) => t.id != id).toList());
    }
    await ref.read(trackerRepositoryProvider).deleteTracker(id);
  }

  Future<TrackerStatus> getStatus(TrackerGoal goal) async {
    final logs = await ref.read(trackerRepositoryProvider).getLogsForTracker(goal.id);
    return TrackerAnalyticsService().calculateStatus(goal, logs);
  }

  Future<void> deleteLog(int id) async {
    await ref.read(trackerRepositoryProvider).deleteLog(id);
  }

  Future<void> updateLog(TrackerLog log) async {
    await ref.read(trackerRepositoryProvider).updateLog(log);
  }
}

final trackerLogsProvider = FutureProvider.family<List<TrackerLog>, String>((ref, trackerId) async {
  return ref.watch(trackerRepositoryProvider).getLogsForTracker(trackerId);
});

final trackerDailyAggsProvider = FutureProvider.family<List<TrackerDailyAggregation>, String>((ref, trackerId) async {
  return ref.watch(trackerRepositoryProvider).getDailyAggregations(trackerId);
});

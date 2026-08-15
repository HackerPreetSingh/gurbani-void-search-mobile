enum TrackerTemplateType {
  moolMantar,
  waheguruSimran,
  baniCount,
  sehajPath,
  custom;

  static TrackerTemplateType fromString(String val) {
    return TrackerTemplateType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TrackerTemplateType.custom,
    );
  }
}

enum TrackerUnitType {
  raw,
  maala,
  pathCount,
  ang;

  static TrackerUnitType fromString(String val) {
    return TrackerUnitType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TrackerUnitType.raw,
    );
  }
}

class TrackerGoal {
  final String id;
  final TrackerTemplateType templateType;
  final String title;
  final int? totalGoal;
  final int? dailyTarget;
  final DateTime startDate;
  final DateTime? deadlineDate;
  final String unitName;
  final DateTime createdAt;

  TrackerGoal({
    required this.id,
    required this.templateType,
    required this.title,
    this.totalGoal,
    this.dailyTarget,
    required this.startDate,
    this.deadlineDate,
    required this.unitName,
    required this.createdAt,
  });

  factory TrackerGoal.fromMap(Map<String, dynamic> map) {
    return TrackerGoal(
      id: map['id'],
      templateType: TrackerTemplateType.fromString(map['template_type']),
      title: map['title'],
      totalGoal: map['total_goal'],
      dailyTarget: map['daily_target'],
      startDate: DateTime.parse(map['start_date']),
      deadlineDate: map['deadline_date'] != null ? DateTime.parse(map['deadline_date']) : null,
      unitName: map['unit_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_type': templateType.name,
      'title': title,
      'total_goal': totalGoal,
      'daily_target': dailyTarget,
      'start_date': startDate.toIso8601String(),
      'deadline_date': deadlineDate?.toIso8601String(),
      'unit_name': unitName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TrackerLog {
  final int? id;
  final String trackerId;
  final DateTime logDate; // Normalized to YYYY-MM-DD
  final int count;
  final String inputMode; // 'raw' or 'maala'
  final DateTime createdAt;

  TrackerLog({
    this.id,
    required this.trackerId,
    required this.logDate,
    required this.count,
    required this.inputMode,
    required this.createdAt,
  });

  factory TrackerLog.fromMap(Map<String, dynamic> map) {
    return TrackerLog(
      id: map['id'],
      trackerId: map['tracker_id'],
      logDate: DateTime.parse(map['log_date']),
      count: map['count'],
      inputMode: map['input_mode'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tracker_id': trackerId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'count': count,
      'input_mode': inputMode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TrackerDailyAggregation {
  final DateTime date;
  final int totalCount;
  final List<TrackerLog> logs;

  TrackerDailyAggregation({
    required this.date,
    required this.totalCount,
    required this.logs,
  });
}

enum TrackerTrend { ahead, behind, onTrack, neutral }

class TrackerStatus {
  final int totalDone;
  final int? totalRemaining;
  final int diffFromExpected; // Positive if ahead, negative if behind
  final TrackerTrend trend;
  final double completionPercentage;
  final int daysElapsed;
  final double averagePerDay;

  TrackerStatus({
    required this.totalDone,
    this.totalRemaining,
    required this.diffFromExpected,
    required this.trend,
    required this.completionPercentage,
    required this.daysElapsed,
    required this.averagePerDay,
  });
}

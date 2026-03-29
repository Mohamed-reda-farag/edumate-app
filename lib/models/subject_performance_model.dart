import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'academic_semester_model.dart';

class SubjectPerformance {
  final String subjectId;
  final String subjectName;
  final int difficulty; // 1-5
  final int totalLectures;
  final int attendedCount;
  final int lateCount;
  final int initialAttendedCount;
  final double avgUnderstanding; // 0.0-5.0
  final double studyHoursLogged;
  final DateTime lastUpdated;

  const SubjectPerformance._({
    required this.subjectId,
    required this.subjectName,
    required this.difficulty,
    required this.totalLectures,
    required this.attendedCount,
    required this.lateCount,
    required this.initialAttendedCount,
    required this.avgUnderstanding,
    required this.studyHoursLogged,
    required this.lastUpdated,
  });

  factory SubjectPerformance({
    required String subjectId,
    required String subjectName,
    required int difficulty,
    required int totalLectures,
    required int attendedCount,
    required int lateCount,
    int initialAttendedCount = 0,
    required double avgUnderstanding,
    required double studyHoursLogged,
    required DateTime lastUpdated,
  }) {
    if (subjectId.isEmpty) throw ArgumentError('subjectId cannot be empty');
    if (subjectName.isEmpty) throw ArgumentError('subjectName cannot be empty');
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError('difficulty must be between 1 and 5');
    }
    if (totalLectures < 0) throw ArgumentError('totalLectures must be >= 0');
    if (attendedCount < 0) throw ArgumentError('attendedCount must be >= 0');
    if (lateCount < 0) throw ArgumentError('lateCount must be >= 0');
    if (avgUnderstanding < 0.0 || avgUnderstanding > 5.0) {
      throw ArgumentError('avgUnderstanding must be between 0.0 and 5.0');
    }
    if (studyHoursLogged < 0) {
      throw ArgumentError('studyHoursLogged must be >= 0');
    }

    if (initialAttendedCount < 0) {
      throw ArgumentError('initialAttendedCount must be >= 0');
    }
    assert(
      totalLectures == 0 || attendedCount + lateCount <= totalLectures,
      '[SubjectPerformance] attended ($attendedCount) + late ($lateCount) = '
      '${attendedCount + lateCount} > total ($totalLectures) — values will be clamped. '
      'Check for race condition or stale data.',
    );

    final safeAttended =
        totalLectures == 0 ? 0 : attendedCount.clamp(0, totalLectures);
    final safeLate =
        totalLectures == 0
            ? 0
            : lateCount.clamp(0, totalLectures - safeAttended);

    // تحذير إضافي في debug mode إذا فُقدت قيمة lateCount
    if (kDebugMode &&
        totalLectures > 0 &&
        lateCount > 0 &&
        safeLate != lateCount) {
      debugPrint(
        '[SubjectPerformance] lateCount clamped from $lateCount to $safeLate '
        '(attended=$attendedCount, total=$totalLectures)',
      );
    }

    return SubjectPerformance._(
      subjectId: subjectId,
      subjectName: subjectName,
      difficulty: difficulty,
      totalLectures: totalLectures,
      attendedCount: safeAttended,
      lateCount: safeLate,
      initialAttendedCount: initialAttendedCount,
      avgUnderstanding: avgUnderstanding,
      studyHoursLogged: studyHoursLogged,
      lastUpdated: lastUpdated,
    );
  }

  // ─── Computed Getters ────────────────────────────────────────────────────

  double get attendanceRate =>
      totalLectures == 0 ? 0.0 : (attendedCount + lateCount) / totalLectures;

  double priorityScoreWithSemester(AcademicSemester? semester) {
    final exam = semester?.nextExamFor(subjectId);
    final daysUntilExam =
        exam != null ? exam.daysUntilExam.clamp(0, 30).toDouble() : 15.0;

    return (1 - attendanceRate) * 25 +
        (1 - avgUnderstanding / 5) * 20 +
        (difficulty / 5) * 25 +
        (1 - daysUntilExam / 30) * 30;
  }

  double get priorityScore => priorityScoreWithSemester(null);

  // ─── Serialization ────────────────────────────────────────────────────────

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    final rawDate = json['lastUpdated'];
    final lastUpdated =
        rawDate is Timestamp
            ? rawDate.toDate()
            : DateTime.parse(rawDate as String);

    return SubjectPerformance(
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      difficulty: json['difficulty'] as int,
      totalLectures: json['totalLectures'] as int,
      attendedCount: json['attendedCount'] as int,
      lateCount: json['lateCount'] as int,
      initialAttendedCount: json['initialAttendedCount'] as int? ?? 0,
      avgUnderstanding: (json['avgUnderstanding'] as num).toDouble(),
      studyHoursLogged: (json['studyHoursLogged'] as num).toDouble(),
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'subjectName': subjectName,
    'difficulty': difficulty,
    'totalLectures': totalLectures,
    'attendedCount': attendedCount,
    'lateCount': lateCount,
    'initialAttendedCount': initialAttendedCount,
    'avgUnderstanding': avgUnderstanding,
    'studyHoursLogged': studyHoursLogged,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };

  /// للـ SharedPreferences cache فقط — lastUpdated كـ ISO string
  Map<String, dynamic> toJsonForCache() => {
    'subjectId': subjectId,
    'subjectName': subjectName,
    'difficulty': difficulty,
    'totalLectures': totalLectures,
    'attendedCount': attendedCount,
    'lateCount': lateCount,
    'initialAttendedCount': initialAttendedCount,
    'avgUnderstanding': avgUnderstanding,
    'studyHoursLogged': studyHoursLogged,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  SubjectPerformance copyWith({
    String? subjectId,
    String? subjectName,
    int? difficulty,
    int? totalLectures,
    int? attendedCount,
    int? lateCount,
    int? initialAttendedCount,
    double? avgUnderstanding,
    double? studyHoursLogged,
    DateTime? lastUpdated,
  }) {
    return SubjectPerformance(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      difficulty: difficulty ?? this.difficulty,
      totalLectures: totalLectures ?? this.totalLectures,
      attendedCount: attendedCount ?? this.attendedCount,
      lateCount: lateCount ?? this.lateCount,
      initialAttendedCount: initialAttendedCount ?? this.initialAttendedCount,
      avgUnderstanding: avgUnderstanding ?? this.avgUnderstanding,
      studyHoursLogged: studyHoursLogged ?? this.studyHoursLogged,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectPerformance &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          subjectName == other.subjectName &&
          difficulty == other.difficulty &&
          totalLectures == other.totalLectures &&
          attendedCount == other.attendedCount &&
          lateCount == other.lateCount &&
          avgUnderstanding == other.avgUnderstanding &&
          studyHoursLogged == other.studyHoursLogged &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(
    subjectId,
    subjectName,
    difficulty,
    totalLectures,
    attendedCount,
    lateCount,
    avgUnderstanding,
    studyHoursLogged,
    lastUpdated,
  );

  @override
  String toString() =>
      'SubjectPerformance(subject: $subjectName, '
      'attendance: ${(attendanceRate * 100).toStringAsFixed(1)}%, '
      'priority: ${priorityScore.toStringAsFixed(1)})';
}

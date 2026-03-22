import 'package:cloud_firestore/cloud_firestore.dart';

import 'academic_semester_model.dart';

// ─── SemesterStats ────────────────────────────────────────────────────────────

class SemesterStats {
  final int totalLecturesRecorded;
  final int attendedLectures;
  final double overallAttendanceRate;
  final double avgUnderstanding;
  final double totalStudyHours;
  final int completedStudySessions;
  final int skippedStudySessions;
  final double studyComplianceRate;
  final double maxPriorityScore;
  final Map<String, SubjectEndStats> perSubject;

  const SemesterStats({
    required this.totalLecturesRecorded,
    required this.attendedLectures,
    required this.overallAttendanceRate,
    required this.avgUnderstanding,
    required this.totalStudyHours,
    required this.completedStudySessions,
    required this.skippedStudySessions,
    required this.studyComplianceRate,
    required this.maxPriorityScore,
    required this.perSubject,
  });

  factory SemesterStats.fromJson(Map<String, dynamic> json) {
    return SemesterStats(
      totalLecturesRecorded: json['totalLecturesRecorded'] as int? ?? 0,
      attendedLectures: json['attendedLectures'] as int? ?? 0,
      overallAttendanceRate:
          (json['overallAttendanceRate'] as num? ?? 0.0).toDouble(),
      avgUnderstanding:
          (json['avgUnderstanding'] as num? ?? 0.0).toDouble(),
      totalStudyHours:
          (json['totalStudyHours'] as num? ?? 0.0).toDouble(),
      completedStudySessions: json['completedStudySessions'] as int? ?? 0,
      skippedStudySessions: json['skippedStudySessions'] as int? ?? 0,
      studyComplianceRate:
          (json['studyComplianceRate'] as num? ?? 0.0).toDouble(),
      maxPriorityScore:
          (json['maxPriorityScore'] as num? ?? 0.0).toDouble(),
      perSubject: (json['perSubject'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          SubjectEndStats.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalLecturesRecorded': totalLecturesRecorded,
        'attendedLectures': attendedLectures,
        'overallAttendanceRate': overallAttendanceRate,
        'avgUnderstanding': avgUnderstanding,
        'totalStudyHours': totalStudyHours,
        'completedStudySessions': completedStudySessions,
        'skippedStudySessions': skippedStudySessions,
        'studyComplianceRate': studyComplianceRate,
        'maxPriorityScore': maxPriorityScore,
        'perSubject': perSubject.map((k, v) => MapEntry(k, v.toJson())),
      };

  static const SemesterStats empty = SemesterStats(
    totalLecturesRecorded: 0,
    attendedLectures: 0,
    overallAttendanceRate: 0.0,
    avgUnderstanding: 0.0,
    totalStudyHours: 0.0,
    completedStudySessions: 0,
    skippedStudySessions: 0,
    studyComplianceRate: 0.0,
    maxPriorityScore: 0.0,
    perSubject: {},
  );
}

// ─── SubjectEndStats ──────────────────────────────────────────────────────────

class SubjectEndStats {
  final String subjectName;
  final int difficulty;
  final double attendanceRate;
  final double avgUnderstanding;
  final double studyHours;

  const SubjectEndStats({
    required this.subjectName,
    required this.difficulty,
    required this.attendanceRate,
    required this.avgUnderstanding,
    required this.studyHours,
  });

  factory SubjectEndStats.fromJson(Map<String, dynamic> json) {
    return SubjectEndStats(
      subjectName: json['subjectName'] as String,
      difficulty: json['difficulty'] as int? ?? 3,
      attendanceRate: (json['attendanceRate'] as num? ?? 0.0).toDouble(),
      avgUnderstanding:
          (json['avgUnderstanding'] as num? ?? 0.0).toDouble(),
      studyHours: (json['studyHours'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'difficulty': difficulty,
        'attendanceRate': attendanceRate,
        'avgUnderstanding': avgUnderstanding,
        'studyHours': studyHours,
      };
}

// ─── SemesterAchievementRecord ────────────────────────────────────────────────

class SemesterAchievementRecord {
  final String id;
  final String userId;
  final SemesterType semesterType;
  final String academicYear;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime archivedAt;
  final List<String> unlockedAchievementIds;
  final int semesterPoints;
  final int longestStreakInSemester;
  final SemesterStats stats;

  final int totalPointsAtEnd;

  const SemesterAchievementRecord({
    required this.id,
    required this.userId,
    required this.semesterType,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    required this.archivedAt,
    required this.unlockedAchievementIds,
    required this.semesterPoints,
    required this.longestStreakInSemester,
    required this.stats,
    this.totalPointsAtEnd = 0,
  });

  // ─── Computed Getters ──────────────────────────────────────────────────────

  int get durationDays => endDate.difference(startDate).inDays;
  int get achievementsCount => unlockedAchievementIds.length;
  String get displayTitle => '${semesterType.labelAr} — $academicYear';

  // ─── Serialization ─────────────────────────────────────────────────────────

  factory SemesterAchievementRecord.fromJson(Map<String, dynamic> json) {
    return SemesterAchievementRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      semesterType: SemesterType.values.firstWhere(
        (e) => e.name == json['semesterType'],
        orElse: () => SemesterType.first,
      ),
      academicYear: json['academicYear'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      archivedAt: (json['archivedAt'] as Timestamp).toDate(),
      unlockedAchievementIds:
          List<String>.from(json['unlockedAchievementIds'] as List? ?? []),
      semesterPoints: json['semesterPoints'] as int? ?? 0,
      longestStreakInSemester:
          json['longestStreakInSemester'] as int? ?? 0,
      stats: json['stats'] != null
          ? SemesterStats.fromJson(
              Map<String, dynamic>.from(json['stats'] as Map))
          : SemesterStats.empty,
      totalPointsAtEnd: json['totalPointsAtEnd'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'semesterType': semesterType.name,
        'academicYear': academicYear,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'archivedAt': Timestamp.fromDate(archivedAt),
        'unlockedAchievementIds': unlockedAchievementIds,
        'semesterPoints': semesterPoints,
        'longestStreakInSemester': longestStreakInSemester,
        'stats': stats.toJson(),
        'totalPointsAtEnd': totalPointsAtEnd,
      };

  SemesterAchievementRecord copyWith({
    String? id,
    String? userId,
    SemesterType? semesterType,
    String? academicYear,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? archivedAt,
    List<String>? unlockedAchievementIds,
    int? semesterPoints,
    int? longestStreakInSemester,
    SemesterStats? stats,
    int? totalPointsAtEnd,
  }) {
    return SemesterAchievementRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterType: semesterType ?? this.semesterType,
      academicYear: academicYear ?? this.academicYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      archivedAt: archivedAt ?? this.archivedAt,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      semesterPoints: semesterPoints ?? this.semesterPoints,
      longestStreakInSemester:
          longestStreakInSemester ?? this.longestStreakInSemester,
      stats: stats ?? this.stats,
      totalPointsAtEnd: totalPointsAtEnd ?? this.totalPointsAtEnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterAchievementRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(id, userId);

  @override
  String toString() =>
      'SemesterAchievementRecord(id: $id, $displayTitle, points: $semesterPoints)';
}
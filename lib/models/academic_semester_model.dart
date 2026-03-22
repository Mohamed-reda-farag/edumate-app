import 'package:cloud_firestore/cloud_firestore.dart';

import 'subject_model.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SemesterType { first, second, summer }

enum ExamType { midterm1, midterm2, finalExam }

// ─── SemesterType Extensions ──────────────────────────────────────────────────

extension SemesterTypeLabel on SemesterType {
  String get labelAr {
    switch (this) {
      case SemesterType.first:  return 'الفصل الأول';
      case SemesterType.second: return 'الفصل الثاني';
      case SemesterType.summer: return 'الفصل الصيفي';
    }
  }

  bool get isSummer => this == SemesterType.summer;
}

// ─── SemesterExam ─────────────────────────────────────────────────────────────

class SemesterExam {
  final String subjectId;
  final String subjectName;
  final ExamType type;
  final DateTime examDate;
  final bool completed;

  const SemesterExam({
    required this.subjectId,
    required this.subjectName,
    required this.type,
    required this.examDate,
    this.completed = false,
  });

  int get daysUntilExam {
    final diff = examDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isUrgent => daysUntilExam <= 14 && !completed;

  factory SemesterExam.fromJson(Map<String, dynamic> json) {
    final rawDate = json['examDate'];
    final examDate = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.parse(rawDate as String);
    return SemesterExam(
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      type: ExamType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExamType.finalExam,
      ),
      examDate: examDate,
      completed: json['completed'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJsonForCache() => {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'type': type.name,
      'examDate': examDate.toIso8601String(),
      'completed': completed,
    };

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'type': type.name,
        'examDate': Timestamp.fromDate(examDate),
        'completed': completed,
      };

  SemesterExam copyWith({
    String? subjectId,
    String? subjectName,
    ExamType? type,
    DateTime? examDate,
    bool? completed,
  }) {
    return SemesterExam(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      type: type ?? this.type,
      examDate: examDate ?? this.examDate,
      completed: completed ?? this.completed,
    );
  }
}

// ─── SemesterEndAction ────────────────────────────────────────────────────────

enum SemesterEndAction {
  startNew,
  startSummer,
  snooze,
}

// ─── AcademicSemester ─────────────────────────────────────────────────────────

class AcademicSemester {
  final String id;
  final String userId;
  final SemesterType type;
  final String academicYear;
  final DateTime startDate;
  final DateTime endDate;
  final int totalLecturesPerSubject;
  final List<Subject> subjects;
  final List<SemesterExam> exams;
  final bool isActive;
  final DateTime createdAt;
  final bool endNotified;
  final DateTime? snoozedUntil;

  const AcademicSemester._({
    required this.id,
    required this.userId,
    required this.type,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    required this.totalLecturesPerSubject,
    required this.subjects,
    required this.exams,
    required this.isActive,
    required this.createdAt,
    required this.endNotified,
    this.snoozedUntil,
  });

  factory AcademicSemester({
    required String id,
    required String userId,
    required SemesterType type,
    required String academicYear,
    required DateTime startDate,
    required DateTime endDate,
    required int totalLecturesPerSubject,
    required List<Subject> subjects,
    required List<SemesterExam> exams,
    bool isActive = true,
    required DateTime createdAt,
    bool endNotified = false,
    DateTime? snoozedUntil,
  }) {
    if (id.isEmpty) throw ArgumentError('id cannot be empty');
    if (userId.isEmpty) throw ArgumentError('userId cannot be empty');
    if (academicYear.isEmpty) throw ArgumentError('academicYear cannot be empty');
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('endDate must be after startDate');
    }
    if (totalLecturesPerSubject <= 0) {
      throw ArgumentError('totalLecturesPerSubject must be > 0');
    }

    return AcademicSemester._(
      id: id,
      userId: userId,
      type: type,
      academicYear: academicYear,
      startDate: startDate,
      endDate: endDate,
      totalLecturesPerSubject: totalLecturesPerSubject,
      subjects: List.unmodifiable(subjects),
      exams: List.unmodifiable(exams),
      isActive: isActive,
      createdAt: createdAt,
      endNotified: endNotified,
      snoozedUntil: snoozedUntil,
    );
  }

  // ─── Computed Getters ────────────────────────────────────────────────────────
  int get currentWeek {
    final diff = DateTime.now().difference(startDate).inDays;
    if (diff < 0) return 1;
    final week = (diff ~/ 7) + 1;
    final maxWeek = totalWeeks;
    return maxWeek > 0 ? week.clamp(1, maxWeek) : week;
  }

  int get totalWeeks => endDate.difference(startDate).inDays ~/ 7;

  double get semesterProgress {
    final total = endDate.difference(startDate).inMilliseconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startDate).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool get isExamPeriod {
    final threeWeeksBeforeEnd = endDate.subtract(const Duration(days: 21));
    return DateTime.now().isAfter(threeWeeksBeforeEnd);
  }

  bool get isFinished => DateTime.now().isAfter(endDate);

  bool get shouldShowEndDialog {
    if (!isFinished || endNotified) return false;
    if (snoozedUntil == null) return true;
    return DateTime.now().isAfter(snoozedUntil!);
  }

  SemesterExam? nextExamFor(String subjectId) {
    final subjectExams = exams
        .where((e) => e.subjectId == subjectId && !e.completed)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    return subjectExams.isEmpty ? null : subjectExams.first;
  }

  List<SemesterExam> get upcomingExams {
    final now = DateTime.now();
    return exams
        .where((e) => e.examDate.isAfter(now) && !e.completed)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
  }

  Subject? findSubject(String subjectId) {
    try {
      return subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  Subject? findSubjectByName(String name) {
    final normalized = name.trim().toLowerCase();
    try {
      return subjects.firstWhere(
        (s) => s.name.toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Academic Year Helper ─────────────────────────────────────────────────

  static String generateAcademicYear(DateTime startDate) {
    if (startDate.month >= 6) {
      return '${startDate.year}-${startDate.year + 1}';
    } else {
      return '${startDate.year - 1}-${startDate.year}';
    }
  }

  // ─── Serialization ────────────────────────────────────────────────────────────

  factory AcademicSemester.fromJson(Map<String, dynamic> json) {
    return AcademicSemester(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: SemesterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SemesterType.first,
      ),
      academicYear: json['academicYear'] as String? ??
          _fallbackAcademicYear(json),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      totalLecturesPerSubject: json['totalLecturesPerSubject'] as int,
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      exams: (json['exams'] as List<dynamic>? ?? [])
          .map((e) => SemesterExam.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      endNotified: json['endNotified'] as bool? ?? false,
      snoozedUntil: json['snoozedUntil'] != null
          ? _parseDate(json['snoozedUntil'])
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.parse(value as String);
  }

  static String _fallbackAcademicYear(Map<String, dynamic> json) {
    try {
      final startDate = _parseDate(json['startDate']);
      return generateAcademicYear(startDate);
    } catch (_) {
      return '${DateTime.now().year}-${DateTime.now().year + 1}';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'academicYear': academicYear,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'totalLecturesPerSubject': totalLecturesPerSubject,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'exams': exams.map((e) => e.toJson()).toList(),
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'endNotified': endNotified,
        'snoozedUntil':
            snoozedUntil != null ? Timestamp.fromDate(snoozedUntil!) : null,
      };

      Map<String, dynamic> toJsonForCache() => {
      'id': id,
      'userId': userId,
      'type': type.name,
      'academicYear': academicYear,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalLecturesPerSubject': totalLecturesPerSubject,
      'subjects': subjects.map((s) => s.toJsonForCache()).toList(),
      'exams': exams.map((e) => e.toJsonForCache()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'endNotified': endNotified,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };

  AcademicSemester copyWith({
    String? id,
    String? userId,
    SemesterType? type,
    String? academicYear,
    DateTime? startDate,
    DateTime? endDate,
    int? totalLecturesPerSubject,
    List<Subject>? subjects,
    List<SemesterExam>? exams,
    bool? isActive,
    DateTime? createdAt,
    bool? endNotified,
    Object? snoozedUntil = _sentinel,
  }) {
    return AcademicSemester(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      academicYear: academicYear ?? this.academicYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalLecturesPerSubject:
          totalLecturesPerSubject ?? this.totalLecturesPerSubject,
      subjects: subjects ?? this.subjects,
      exams: exams ?? this.exams,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      endNotified: endNotified ?? this.endNotified,
      snoozedUntil: snoozedUntil == _sentinel
          ? this.snoozedUntil
          : snoozedUntil as DateTime?,
    );
  }
}

const Object _sentinel = Object();
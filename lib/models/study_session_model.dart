import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum SessionType { review, practice, explain, activate }

enum SessionStatus { planned, completed, skipped }

const _sentinel = Object();

class StudySession {
  final String id;
  final String subjectId;
  final String subjectName;
  final String dayOfWeek; // السبت...الجمعة
  final String timeSlot;  // e.g. "8-10"
  final int durationMinutes;
  final int priorityScore;
  final SessionType sessionType;
  final SessionStatus status;
  final DateTime scheduledDate;
  final double? completionRate; // 0.0-1.0
  final int? actualDurationMinutes;
  final String? notes;
  final DateTime generatedAt;

  const StudySession._({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.durationMinutes,
    required this.priorityScore,
    required this.sessionType,
    required this.status,
    required this.scheduledDate,
    this.completionRate,
    this.actualDurationMinutes,
    this.notes,
    required this.generatedAt,
  });

  factory StudySession({
    required String id,
    required String subjectId,
    required String subjectName,
    required String dayOfWeek,
    required String timeSlot,
    required int durationMinutes,
    required int priorityScore,
    required SessionType sessionType,
    required SessionStatus status,
    required DateTime scheduledDate,
    double? completionRate,
    int? actualDurationMinutes,
    String? notes,
    required DateTime generatedAt,
  }) {
    const validDays = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء',
      'الأربعاء', 'الخميس', 'الجمعة'
    ];

    if (id.isEmpty) throw ArgumentError('id cannot be empty');
    if (subjectId.isEmpty) throw ArgumentError('subjectId cannot be empty');
    if (subjectName.isEmpty) throw ArgumentError('subjectName cannot be empty');
    if (!validDays.contains(dayOfWeek)) {
      throw ArgumentError('Invalid dayOfWeek: $dayOfWeek');
    }
    if (timeSlot.isEmpty) throw ArgumentError('timeSlot cannot be empty');
    if (durationMinutes <= 0) {
      throw ArgumentError('durationMinutes must be > 0');
    }
    if (priorityScore < 0) throw ArgumentError('priorityScore must be >= 0');
    if (completionRate != null &&
        (completionRate < 0.0 || completionRate > 1.0)) {
      throw ArgumentError('completionRate must be between 0.0 and 1.0');
    }
    if (actualDurationMinutes != null && actualDurationMinutes <= 0) {
      throw ArgumentError('actualDurationMinutes must be > 0');
    }

    return StudySession._(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      dayOfWeek: dayOfWeek,
      timeSlot: timeSlot,
      durationMinutes: durationMinutes,
      priorityScore: priorityScore,
      sessionType: sessionType,
      status: status,
      scheduledDate: scheduledDate,
      completionRate: completionRate,
      actualDurationMinutes: actualDurationMinutes,
      notes: notes,
      generatedAt: generatedAt,
    );
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final rawScheduled = json['scheduledDate'];
    final scheduledDate = rawScheduled is Timestamp
        ? rawScheduled.toDate()
        : DateTime.parse(rawScheduled as String);

    final rawGenerated = json['generatedAt'];
    final generatedAt = rawGenerated is Timestamp
        ? rawGenerated.toDate()
        : DateTime.parse(rawGenerated as String);

    return StudySession(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      timeSlot: json['timeSlot'] as String,
      durationMinutes: json['durationMinutes'] as int,
      priorityScore: json['priorityScore'] as int,
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == json['sessionType'],
        orElse: () {
          debugPrint('[StudySession] unknown sessionType "${json['sessionType']}" — defaulting to review');
          return SessionType.review;
        },
      ),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () {
          debugPrint('[StudySession] unknown status "${json['status']}" — defaulting to planned');
          return SessionStatus.planned;
        },
      ),
      scheduledDate: scheduledDate,
      completionRate: json['completionRate'] != null
          ? (json['completionRate'] as num).toDouble()
          : null,
      actualDurationMinutes: json['actualDurationMinutes'] as int?,
      notes: json['notes'] as String?,
      generatedAt: generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'dayOfWeek': dayOfWeek,
        'timeSlot': timeSlot,
        'durationMinutes': durationMinutes,
        'priorityScore': priorityScore,
        'sessionType': sessionType.name,
        'status': status.name,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'completionRate': completionRate,
        'actualDurationMinutes': actualDurationMinutes,
        'notes': notes,
        'generatedAt': Timestamp.fromDate(generatedAt),
      };

  /// للـ SharedPreferences cache فقط — التواريخ كـ ISO string
  Map<String, dynamic> toJsonForCache() => {
    'id': id,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'dayOfWeek': dayOfWeek,
    'timeSlot': timeSlot,
    'durationMinutes': durationMinutes,
    'priorityScore': priorityScore,
    'sessionType': sessionType.name,
    'status': status.name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'completionRate': completionRate,
    'actualDurationMinutes': actualDurationMinutes,
    'notes': notes,
    'generatedAt': generatedAt.toIso8601String(),
  };

  StudySession copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? dayOfWeek,
    String? timeSlot,
    int? durationMinutes,
    int? priorityScore,
    SessionType? sessionType,
    SessionStatus? status,
    DateTime? scheduledDate,
    Object? completionRate = _sentinel,
    Object? actualDurationMinutes = _sentinel,
    Object? notes = _sentinel,
    DateTime? generatedAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priorityScore: priorityScore ?? this.priorityScore,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completionRate: completionRate == _sentinel
          ? this.completionRate
          : completionRate as double?,
      actualDurationMinutes: actualDurationMinutes == _sentinel
          ? this.actualDurationMinutes
          : actualDurationMinutes as int?,
      notes: notes == _sentinel ? this.notes : notes as String?,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          subjectName == other.subjectName &&
          dayOfWeek == other.dayOfWeek &&
          timeSlot == other.timeSlot &&
          durationMinutes == other.durationMinutes &&
          priorityScore == other.priorityScore &&
          sessionType == other.sessionType &&
          status == other.status &&
          scheduledDate == other.scheduledDate &&
          completionRate == other.completionRate &&
          actualDurationMinutes == other.actualDurationMinutes &&
          notes == other.notes &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        subjectId,
        subjectName,
        dayOfWeek,
        timeSlot,
        durationMinutes,
        priorityScore,
        sessionType,
        status,
        scheduledDate,
        completionRate,
        actualDurationMinutes,
        notes,
        generatedAt,
      );

  @override
  String toString() =>
      'StudySession(id: $id, subject: $subjectName, $dayOfWeek $timeSlot, ${status.name})';

  bool get hasStarted {
    final now = DateTime.now();

    // نستخرج وقت البداية من الـ timeSlot (مثال: "8:00-10:00")
    final parts = timeSlot.split('-');
    if (parts.isNotEmpty) {
      final startParts = parts[0].trim().split(':');
      if (startParts.length >= 2) {
        final startHour   = int.tryParse(startParts[0]) ?? 0;
        final startMinute = int.tryParse(startParts[1]) ?? 0;
        final sessionStart = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          startHour,
          startMinute,
        );
        return !now.isBefore(sessionStart);
      }
    }

    // fallback: إذا فشل parsing نتحقق من بداية اليوم فقط
    final sessionDay = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return !now.isBefore(sessionDay);
  }
}
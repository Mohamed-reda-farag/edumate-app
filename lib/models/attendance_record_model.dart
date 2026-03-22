import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AttendanceStatus { attended, absent, late }

class AttendanceRecord {
  final String id;
  final String subjectId;
  final String subjectName;
  final DateTime date;
  final AttendanceStatus status;
  final int lateMinutes;
  final int? understandingRating;
  final int lectureNumber;
  final String? notes;
  final DateTime createdAt;
  final String sessionType;
  final int? lectureDurationMinutes;

  const AttendanceRecord._({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.status,
    required this.lateMinutes,
    this.understandingRating,
    required this.lectureNumber,
    this.notes,
    required this.createdAt,
    this.sessionType = 'lec',
    this.lectureDurationMinutes,
  });

  factory AttendanceRecord({
    required String id,
    required String subjectId,
    required String subjectName,
    required DateTime date,
    required AttendanceStatus status,
    int lateMinutes = 0,
    int? understandingRating,
    required int lectureNumber,
    String? notes,
    required DateTime createdAt,
    String sessionType = 'lec',
    int? lectureDurationMinutes,
  }) {
    if (id.isEmpty) throw ArgumentError('id cannot be empty');
    if (subjectId.isEmpty) throw ArgumentError('subjectId cannot be empty');
    if (subjectName.isEmpty) throw ArgumentError('subjectName cannot be empty');
    if (lectureNumber <= 0) throw ArgumentError('lectureNumber must be > 0');
    if (lateMinutes < 0) throw ArgumentError('lateMinutes must be >= 0');

    if (status == AttendanceStatus.attended ||
        status == AttendanceStatus.late) {
      if (understandingRating == null) {
        throw ArgumentError(
            'understandingRating is required when status is attended or late');
      }
      if (understandingRating < 1 || understandingRating > 5) {
        throw ArgumentError('understandingRating must be between 1 and 5');
      }
    }

    if (status == AttendanceStatus.late && lateMinutes <= 0) {
      throw ArgumentError('lateMinutes must be > 0 when status is late');
    }

    return AttendanceRecord._(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      date: date,
      status: status,
      lateMinutes: lateMinutes,
      understandingRating: understandingRating,
      lectureNumber: lectureNumber,
      notes: notes,
      createdAt: createdAt,
      sessionType: sessionType,
      lectureDurationMinutes: lectureDurationMinutes,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? '';
    final status =
        AttendanceStatus.values.cast<AttendanceStatus?>().firstWhere(
              (e) => e?.name == rawStatus,
              orElse: () => null,
            ) ??
        _fallbackStatus(rawStatus);

    final rawRating = json['understandingRating'] as int?;
    final needsRating = status == AttendanceStatus.attended ||
        status == AttendanceStatus.late;
    final understandingRating =
        needsRating ? (rawRating?.clamp(1, 5) ?? 3) : rawRating;

    final rawLateMinutes = json['lateMinutes'] as int? ?? 0;
    final lateMinutes =
        (status == AttendanceStatus.late && rawLateMinutes <= 0)
            ? 1
            : rawLateMinutes;

    return AttendanceRecord(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      date: (json['date'] as Timestamp).toDate(),
      status: status,
      lateMinutes: lateMinutes,
      understandingRating: understandingRating,
      lectureNumber: json['lectureNumber'] as int,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      sessionType: json['sessionType'] as String? ?? 'lec',
      lectureDurationMinutes: json['lectureDurationMinutes'] as int?,
    );
  }

  /// يُرجع fallback آمن عند status غير معروف ويُسجِّل تحذيراً.
  static AttendanceStatus _fallbackStatus(String raw) {

    debugPrint(
        '[AttendanceRecord] unknown status "$raw" — defaulting to absent');
    return AttendanceStatus.absent;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'date': Timestamp.fromDate(date),
        'status': status.name,
        'lateMinutes': lateMinutes,
        'understandingRating': understandingRating,
        'lectureNumber': lectureNumber,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'sessionType': sessionType,
        if (lectureDurationMinutes != null)
          'lectureDurationMinutes': lectureDurationMinutes,
      };

  AttendanceRecord copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    DateTime? date,
    AttendanceStatus? status,
    int? lateMinutes,
    Object? understandingRating = _sentinel,
    int? lectureNumber,
    Object? notes = _sentinel,
    DateTime? createdAt,
    String? sessionType,
    Object? lectureDurationMinutes = _sentinel,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
      status: status ?? this.status,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      understandingRating: understandingRating == _sentinel
          ? this.understandingRating
          : understandingRating as int?,
      lectureNumber: lectureNumber ?? this.lectureNumber,
      notes: notes == _sentinel ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      sessionType: sessionType ?? this.sessionType,
      lectureDurationMinutes: lectureDurationMinutes == _sentinel
          ? this.lectureDurationMinutes
          : lectureDurationMinutes as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          subjectName == other.subjectName &&
          date == other.date &&
          status == other.status &&
          lateMinutes == other.lateMinutes &&
          understandingRating == other.understandingRating &&
          lectureNumber == other.lectureNumber &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        subjectId,
        subjectName,
        date,
        status,
        lateMinutes,
        understandingRating,
        lectureNumber,
        notes,
        createdAt,
      );

  @override
  String toString() =>
      'AttendanceRecord(id: $id, subject: $subjectName, '
      'date: $date, status: ${status.name})';
}

// Sentinel value for nullable copyWith fields
const Object _sentinel = Object();
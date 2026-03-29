import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Enums
// ══════════════════════════════════════════════════════════════════════════════

enum TaskType {
  lecture,      // محاضرة (من الجدول)
  studySession, // جلسة مذاكرة (من الجدول الذكي)
  skillCourse,  // كورس مهارة (من المجالات)
  custom,       // مهمة مخصصة يضيفها المستخدم
}

enum TaskStatus {
  upcoming,   // قادمة
  ongoing,    // جارية
  completed,  // مكتملة
  missed,     // فائتة
}

// حالة محددة للمحاضرات
enum LectureAttendanceStatus {
  attended, // حضرت
  absent,   // غبت
  late,     // تأخرت
}

// حالة محددة لجلسات المذاكرة
enum StudySessionTaskStatus {
  notStarted, // لم تبدأ
  started,    // بدأت
  completed,  // أكملت
}

// نوع التكرار للمهام المخصصة الدورية
enum RecurrenceType {
  daily,   // يومي
  weekly,  // أسبوعي (نفس اليوم كل أسبوع)
}

// ══════════════════════════════════════════════════════════════════════════════
// TaskModel — النموذج الرئيسي للمهمة
// ══════════════════════════════════════════════════════════════════════════════

class TaskModel {
  final String id;
  final String userId;
  final TaskType type;

  // جميع الحقول final — التعديل يتم عبر copyWith حصراً.
  // هذا يضمن أن الـ Provider يستقبل كائناً جديداً في كل تغيير.
  final TaskStatus status;

  // ── بيانات مشتركة ──────────────────────────────────────────────────────────
  final String title;
  final String? description;
  final DateTime? scheduledDate;

  /// label من ScheduleTimeSlot مثل "8:00-10:00" أو "9:30-11:00".
  /// استخدم [parseTimeSlot] لتحليله — لا تفترض صيغة "H-H" ثابتة.
  final String? timeSlot;

  /// المدة بالدقائق — يأتي من ScheduleTimeSlot.durationMinutes مباشرةً.
  /// لجلسات المذاكرة يتفاوت حسب الأولوية (قد يكون 60 أو 210 دقيقة).
  /// للمحاضرات يساوي durationMinutes للـ slot المخصص.
  final int? durationMinutes;

  // ── بيانات المحاضرة (type == lecture) ──────────────────────────────────────
  final String? subjectId;
  final String? subjectName;
  final String? sessionType; // lec, sec, lab
  final LectureAttendanceStatus? attendanceStatus;

  // ── بيانات جلسة المذاكرة (type == studySession) ────────────────────────────
  final String? studySessionId;
  final StudySessionTaskStatus? studySessionStatus;

  // ── بيانات كورس المهارة (type == skillCourse) ──────────────────────────────
  final String? courseId;
  final String? skillId;
  final String? fieldId;
  final String? courseTitle;
  final int? currentLesson;
  final int? totalLessons;
  final double? progressPercentage;

  // ── بيانات المهمة المخصصة (type == custom) ─────────────────────────────────
  final bool isRecurring;
  final RecurrenceType? recurrenceType;
  final int reminderMinutesBefore;
  final DateTime? dueDate;
  final bool hasReminder;

  // ── Metadata ────────────────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    this.scheduledDate,
    this.timeSlot,
    this.durationMinutes,
    this.subjectId,
    this.subjectName,
    this.sessionType,
    this.attendanceStatus,
    this.studySessionId,
    this.studySessionStatus,
    this.courseId,
    this.skillId,
    this.fieldId,
    this.courseTitle,
    this.currentLesson,
    this.totalLessons,
    this.progressPercentage,
    this.isRecurring = false,
    this.recurrenceType,
    this.reminderMinutesBefore = 60,
    this.dueDate,
    this.hasReminder = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Factory constructors ────────────────────────────────────────────────────

  /// إنشاء مهمة محاضرة.
  /// [timeSlot] = ScheduleTimeSlot.label  مثل "8:00-10:00"
  /// [durationMinutes] = ScheduleTimeSlot.durationMinutes
  factory TaskModel.fromLecture({
    required String id,
    required String userId,
    required String subjectId,
    required String subjectName,
    required String sessionType,
    required String timeSlot,
    required int durationMinutes,
    required DateTime scheduledDate,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      type: TaskType.lecture,
      status: _computeInitialStatus(scheduledDate, timeSlot),
      title: subjectName,
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      durationMinutes: durationMinutes,
      subjectId: subjectId,
      subjectName: subjectName,
      sessionType: sessionType,
      attendanceStatus: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// إنشاء مهمة جلسة مذاكرة.
  /// [timeSlot] و [durationMinutes] يأتيان من StudySession مباشرةً
  /// (وهي بدورها تأتي من ScheduleTimeSlot في StudyPlanService).
  /// المدة تتفاوت حسب الأولوية — لا تفترض قيمة ثابتة.
  factory TaskModel.fromStudySession({
    required String id,
    required String userId,
    required String studySessionId,
    required String subjectName,
    required String timeSlot,
    required int durationMinutes,
    required DateTime scheduledDate,
    required int priorityScore,
    required String sessionTypeName,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      type: TaskType.studySession,
      status: _computeInitialStatus(scheduledDate, timeSlot),
      title: '$subjectName — ${_sessionTypeLabel(sessionTypeName)}',
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      durationMinutes: durationMinutes,
      subjectName: subjectName,
      studySessionId: studySessionId,
      studySessionStatus: StudySessionTaskStatus.notStarted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// إنشاء مهمة كورس مهارة.
  /// لا تحتاج حالة زمنية — تبقى upcoming حتى يكتملها المستخدم.
  factory TaskModel.fromSkillCourse({
    required String id,
    required String userId,
    required String courseId,
    required String skillId,
    required String fieldId,
    required String courseTitle,
    required int currentLesson,
    required int totalLessons,
    required double progressPercentage,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      type: TaskType.skillCourse,
      status: TaskStatus.upcoming,
      title: courseTitle,
      courseId: courseId,
      skillId: skillId,
      fieldId: fieldId,
      courseTitle: courseTitle,
      currentLesson: currentLesson,
      totalLessons: totalLessons,
      progressPercentage: progressPercentage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── Serialization ────────────────────────────────────────────────────────────

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.custom,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.upcoming,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledDate: json['scheduledDate'] != null
          ? (json['scheduledDate'] as Timestamp).toDate()
          : null,
      timeSlot: json['timeSlot'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      sessionType: json['sessionType'] as String?,
      attendanceStatus: json['attendanceStatus'] != null
          ? LectureAttendanceStatus.values.firstWhere(
              (e) => e.name == json['attendanceStatus'],
              orElse: () => LectureAttendanceStatus.attended,
            )
          : null,
      studySessionId: json['studySessionId'] as String?,
      studySessionStatus: json['studySessionStatus'] != null
          ? StudySessionTaskStatus.values.firstWhere(
              (e) => e.name == json['studySessionStatus'],
              orElse: () => StudySessionTaskStatus.notStarted,
            )
          : null,
      courseId: json['courseId'] as String?,
      skillId: json['skillId'] as String?,
      fieldId: json['fieldId'] as String?,
      courseTitle: json['courseTitle'] as String?,
      currentLesson: json['currentLesson'] as int?,
      totalLessons: json['totalLessons'] as int?,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble(),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceType: json['recurrenceType'] != null
          ? RecurrenceType.values.firstWhere(
              (e) => e.name == json['recurrenceType'],
              orElse: () => RecurrenceType.daily,
            )
          : null,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 60,
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : null,
      hasReminder: json['hasReminder'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// يكتب فقط الحقول غير الـ null لتقليل حجم الـ documents في Firestore.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'title': title,
      'isRecurring': isRecurring,
      'hasReminder': hasReminder,
      'reminderMinutesBefore': reminderMinutesBefore,
      if (recurrenceType != null) 'recurrenceType': recurrenceType!.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    if (description != null)    map['description'] = description;
    if (scheduledDate != null)  map['scheduledDate'] = Timestamp.fromDate(scheduledDate!);
    if (timeSlot != null)       map['timeSlot'] = timeSlot;
    if (durationMinutes != null) map['durationMinutes'] = durationMinutes;
    if (subjectId != null)      map['subjectId'] = subjectId;
    if (subjectName != null)    map['subjectName'] = subjectName;
    if (sessionType != null)    map['sessionType'] = sessionType;
    if (attendanceStatus != null) map['attendanceStatus'] = attendanceStatus!.name;
    if (studySessionId != null) map['studySessionId'] = studySessionId;
    if (studySessionStatus != null) map['studySessionStatus'] = studySessionStatus!.name;
    if (courseId != null)       map['courseId'] = courseId;
    if (skillId != null)        map['skillId'] = skillId;
    if (fieldId != null)        map['fieldId'] = fieldId;
    if (courseTitle != null)    map['courseTitle'] = courseTitle;
    if (currentLesson != null)  map['currentLesson'] = currentLesson;
    if (totalLessons != null)   map['totalLessons'] = totalLessons;
    if (progressPercentage != null) map['progressPercentage'] = progressPercentage;
    if (dueDate != null)        map['dueDate'] = Timestamp.fromDate(dueDate!);

    return map;
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    TaskType? type,
    TaskStatus? status,
    String? title,
    Object? description = _sentinel,
    Object? scheduledDate = _sentinel,
    Object? timeSlot = _sentinel,
    Object? durationMinutes = _sentinel,
    Object? subjectId = _sentinel,
    Object? subjectName = _sentinel,
    Object? sessionType = _sentinel,
    Object? attendanceStatus = _sentinel,
    Object? studySessionId = _sentinel,
    Object? studySessionStatus = _sentinel,
    Object? courseId = _sentinel,
    Object? skillId = _sentinel,
    Object? fieldId = _sentinel,
    Object? courseTitle = _sentinel,
    Object? currentLesson = _sentinel,
    Object? totalLessons = _sentinel,
    Object? progressPercentage = _sentinel,
    bool? isRecurring,
    Object? recurrenceType = _sentinel,
    int? reminderMinutesBefore,
    Object? dueDate = _sentinel,
    bool? hasReminder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description:
          description == _sentinel ? this.description : description as String?,
      scheduledDate: scheduledDate == _sentinel
          ? this.scheduledDate
          : scheduledDate as DateTime?,
      timeSlot: timeSlot == _sentinel ? this.timeSlot : timeSlot as String?,
      durationMinutes: durationMinutes == _sentinel
          ? this.durationMinutes
          : durationMinutes as int?,
      subjectId:
          subjectId == _sentinel ? this.subjectId : subjectId as String?,
      subjectName:
          subjectName == _sentinel ? this.subjectName : subjectName as String?,
      sessionType:
          sessionType == _sentinel ? this.sessionType : sessionType as String?,
      attendanceStatus: attendanceStatus == _sentinel
          ? this.attendanceStatus
          : attendanceStatus as LectureAttendanceStatus?,
      studySessionId: studySessionId == _sentinel
          ? this.studySessionId
          : studySessionId as String?,
      studySessionStatus: studySessionStatus == _sentinel
          ? this.studySessionStatus
          : studySessionStatus as StudySessionTaskStatus?,
      courseId: courseId == _sentinel ? this.courseId : courseId as String?,
      skillId: skillId == _sentinel ? this.skillId : skillId as String?,
      fieldId: fieldId == _sentinel ? this.fieldId : fieldId as String?,
      courseTitle:
          courseTitle == _sentinel ? this.courseTitle : courseTitle as String?,
      currentLesson: currentLesson == _sentinel
          ? this.currentLesson
          : currentLesson as int?,
      totalLessons: totalLessons == _sentinel
          ? this.totalLessons
          : totalLessons as int?,
      progressPercentage: progressPercentage == _sentinel
          ? this.progressPercentage
          : progressPercentage as double?,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType == _sentinel
          ? this.recurrenceType
          : recurrenceType as RecurrenceType?,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      hasReminder: hasReminder ?? this.hasReminder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Time Slot Parsing
  // ══════════════════════════════════════════════════════════════════════════

  /// يُحلِّل timeSlot label ويُرجع (startMin, endMin) بالدقائق من منتصف الليل.
  ///
  /// يدعم الصيغتين:
  ///   "8:00-10:00"  ← ScheduleTimeSlot.label عند وجود دقائق
  ///   "8-10"        ← صيغة مختصرة (دقائق = 0)
  ///   "9:30-11:00"  ← slot مخصص بدقائق
  ///
  /// يُرجع null إذا كان الـ label غير قابل للتحليل.
  static ({int startMin, int endMin})? parseTimeSlot(String slot) {
    final trimmed = slot.trim();

    // نجد أول '-' بعد موضع 0 كفاصل بين البداية والنهاية.
    // "9:30-11:00" → separator عند index 4
    // "8-10"       → separator عند index 1
    int separatorIdx = -1;
    for (int i = 1; i < trimmed.length; i++) {
      if (trimmed[i] == '-') {
        separatorIdx = i;
        break;
      }
    }
    if (separatorIdx == -1) return null;

    final startPart = trimmed.substring(0, separatorIdx).trim();
    final endPart   = trimmed.substring(separatorIdx + 1).trim();

    int? parsePart(String part) {
      final colonIdx = part.indexOf(':');
      if (colonIdx == -1) {
        final h = int.tryParse(part);
        return h != null ? h * 60 : null;
      }
      final h = int.tryParse(part.substring(0, colonIdx));
      final m = int.tryParse(part.substring(colonIdx + 1));
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    final startMin = parsePart(startPart);
    final endMin   = parsePart(endPart);
    if (startMin == null || endMin == null) return null;

    return (startMin: startMin, endMin: endMin);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Status Computation
  // ══════════════════════════════════════════════════════════════════════════

  /// يحسب الحالة الزمنية للمهمة بناءً على الوقت الحالي.
  ///
  /// لا تُعيد [TaskStatus.completed] أبداً —
  /// المهام المكتملة تُحفظ في Firestore وتُقرأ منه، ويجب تخطيها من الخارج.
  ///
  /// يدعم timeSlot بصيغتي "8:00-10:00" و "8-10" و "9:30-11:00".
  static TaskStatus computeCurrentStatus(DateTime date, String timeSlot) {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);

    if (taskDay.isAfter(today))  return TaskStatus.upcoming;
    if (taskDay.isBefore(today)) return TaskStatus.missed;

    // نفس اليوم — نحلّل timeSlot
    final parsed = parseTimeSlot(timeSlot);
    if (parsed == null) return TaskStatus.upcoming;

    final startDt = DateTime(
        now.year, now.month, now.day,
        parsed.startMin ~/ 60, parsed.startMin % 60);
    final endDt = DateTime(
        now.year, now.month, now.day,
        parsed.endMin ~/ 60, parsed.endMin % 60);

    if (now.isBefore(startDt)) return TaskStatus.upcoming;
    if (now.isAfter(endDt))    return TaskStatus.missed;
    return TaskStatus.ongoing;
  }

  static TaskStatus _computeInitialStatus(DateTime date, String timeSlot) =>
      computeCurrentStatus(date, timeSlot);

  // ══════════════════════════════════════════════════════════════════════════
  //  Display Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// يُرجع timeSlot بصيغة عرض موحدة "HH:MM - HH:MM".
  /// يعمل مع "8:00-10:00" و "9:30-11:00" و "8-10".
  String get formattedTimeSlot {
    if (timeSlot == null) return '';
    final parsed = parseTimeSlot(timeSlot!);
    if (parsed == null) return timeSlot!;

    String fmt(int totalMin) {
      final h = (totalMin ~/ 60).toString().padLeft(2, '0');
      final m = (totalMin % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${fmt(parsed.startMin)} - ${fmt(parsed.endMin)}';
  }

  /// تسمية نوع الجلسة (محاضرة / سيكشن / معمل)
  String get sessionTypeLabel {
    switch (sessionType) {
      case 'lec': return 'محاضرة';
      case 'sec': return 'سيكشن';
      case 'lab': return 'معمل';
      default:    return 'جلسة';
    }
  }

  /// هل المهمة من اليوم؟
  bool get isToday {
    if (scheduledDate == null) return false;
    final now = DateTime.now();
    return scheduledDate!.year == now.year &&
        scheduledDate!.month == now.month &&
        scheduledDate!.day == now.day;
  }

  static String _sessionTypeLabel(String type) {
    switch (type) {
      case 'explain':  return 'شرح';
      case 'practice': return 'تمارين';
      case 'review':   return 'مراجعة';
      case 'activate': return 'تفعيل';
      default:         return 'مذاكرة';
    }
  }

  @override
  String toString() =>
      'TaskModel(id: $id, type: ${type.name}, title: $title, status: ${status.name})';
}

const Object _sentinel = Object();
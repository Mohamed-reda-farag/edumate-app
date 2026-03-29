import 'package:uuid/uuid.dart';

import '../models/study_session_model.dart';
import '../models/academic_semester_model.dart';
import '../models/subject_performance_model.dart';
import '../models/schedule_time_settings.dart';
import '../models/subject_schedule_entry_model.dart';
import '../utils/stable_hash.dart';

// الجمعة مستثناة عمداً — يوم راحة أسبوعي
const List<String> _kStudyDays = [
  'السبت',
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
];

// تفضيلات الوقت → ساعات البداية المقابلة
const Map<String, List<int>> _kPreferredTimeRanges = {
  'morning': [6, 7, 8, 9, 10, 11],
  'afternoon': [12, 13, 14, 15],
  'evening': [16, 17, 18, 19, 20],
  'night': [21, 22, 23, 0, 1],
};

// جدول الطاقة: (sessionDuration, commitmentLevel) → (maxSessionsPerDay, durationMinutes)
const Map<String, Map<String, _Capacity>> _kCapacityTable = {
  'short': {
    'low': _Capacity(maxPerDay: 1, minutes: 30),
    'medium': _Capacity(maxPerDay: 1, minutes: 30),
    'high': _Capacity(maxPerDay: 2, minutes: 30),
  },
  'medium': {
    'low': _Capacity(maxPerDay: 1, minutes: 45),
    'medium': _Capacity(maxPerDay: 2, minutes: 60),
    'high': _Capacity(maxPerDay: 3, minutes: 60),
  },
  'long': {
    'low': _Capacity(maxPerDay: 1, minutes: 60),
    'medium': _Capacity(maxPerDay: 2, minutes: 90),
    'high': _Capacity(maxPerDay: 3, minutes: 90),
  },
};

class _Capacity {
  final int maxPerDay;
  final int minutes;
  const _Capacity({required this.maxPerDay, required this.minutes});
}

class StudyPlanService {
  const StudyPlanService();

  Future<List<StudySession>> generateWeeklyPlan({
    required List<SubjectScheduleEntry> schedule,
    required List<SubjectPerformance> performances,
    AcademicSemester? semester,
    required String userId,
    Map<String, dynamic>? userPreferences,
    List<StudySession> preservedSessions = const [],
  }) async {
    final timeSlots =
        userId.isNotEmpty
            ? await ScheduleTimeSettings.instance.load(userId)
            : List<ScheduleTimeSlot>.from(kDefaultTimeSlots);

    // ── استخراج تفضيلات المستخدم ──────────────────────────────────────────
    final schedulePrefs =
        userPreferences?['schedule'] is Map
            ? Map<String, dynamic>.from(userPreferences!['schedule'] as Map)
            : null;

    final goalsPrefs =
        userPreferences?['goals'] is Map
            ? Map<String, dynamic>.from(userPreferences!['goals'] as Map)
            : null;

    final preferredTimes =
        schedulePrefs?['preferredTimes'] is List
            ? List<String>.from(schedulePrefs!['preferredTimes'] as List)
            : <String>[];

    final rawDaysPerWeek =
        (schedulePrefs?['daysPerWeek'] as num?)?.toInt() ?? 6;

    final sessionDuration =
        (userPreferences?['sessionDuration'] as String?) ?? 'medium';

    final commitmentLevel =
        (goalsPrefs?['commitmentLevel'] as String?) ?? 'medium';

    // ── حساب الطاقة الفعلية ────────────────────────────────────────────────
    final capacity = _resolveCapacity(sessionDuration, commitmentLevel);

    // ── حساب أيام المذاكرة المعدَّلة ──────────────────────────────────────
    final effectiveDays = _resolveEffectiveDays(
      rawDaysPerWeek,
      commitmentLevel,
    );

    // ── حساب الأيام المتبقية في الأسبوع ───────────────────────────────────
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final weekStart = _currentWeekStart(now);

    final remainingDaysCount =
        _kStudyDays.where((day) {
          final idx = _kStudyDays.indexOf(day);
          final date = weekStart.add(Duration(days: idx));
          return !date.isBefore(todayDate);
        }).length;

    final adjustedEffectiveDays = effectiveDays.clamp(
      1,
      remainingDaysCount > 0 ? remainingDaysCount : 1,
    );

    // ── ترتيب الفترات الزمنية حسب التفضيل ────────────────────────────────
    final sortedSlots = _sortSlotsByPreference(timeSlots, preferredTimes);

    // ── Step 1: unique subjects from the schedule ──────────────────────────
    String norm(String s) => s.trim().toLowerCase();

    final Map<String, String> normToOriginal = {};
    for (final e in schedule) {
      final n = norm(e.subjectName);
      normToOriginal.putIfAbsent(n, () => e.subjectName.trim());
    }
    final subjectNames = normToOriginal.values.toList();

    final perfById = {for (final p in performances) p.subjectId: p};
    final perfByNorm = {for (final p in performances) norm(p.subjectName): p};

    SubjectPerformance? findPerf(String subjectName) {
      final entry = schedule.cast<SubjectScheduleEntry?>().firstWhere(
        (e) => norm(e?.subjectName ?? '') == norm(subjectName),
        orElse: () => null,
      );
      if (entry?.subjectId.isNotEmpty == true) {
        final byId = perfById[entry!.subjectId];
        if (byId != null) return byId;
      }
      return perfByNorm[norm(subjectName)];
    }

    // ── Step 2: ترتيب المواد بالأولوية ────────────────────────────────────
    final subjects =
        subjectNames
            .map(
              (name) => _SubjectMeta(
                name: name,
                performance: findPerf(name),
                semester: semester,
              ),
            )
            .toList()
          ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    // ── Step 3: حساب عدد الجلسات ونوعها لكل مادة ─────────────────────────

    // نبني خريطة: subjectId/name → عدد الجلسات المحمية لهذا الأسبوع
    // الجلسات المحمية هي completed أو skipped — لا نُعيد توليدها
    final preservedCountBySubject = <String, int>{};
    for (final s in preservedSessions) {
      if (s.status != SessionStatus.completed) continue;
      final key = s.subjectId.isNotEmpty ? s.subjectId : s.subjectName;
      preservedCountBySubject[key] = (preservedCountBySubject[key] ?? 0) + 1;
    }

    // الحد الأسبوعي الكلي المتاح للتوليد الجديد
    final totalWeeklyCapacity = capacity.maxPerDay * adjustedEffectiveDays;
    // عدد الجلسات المحمية الكلي عبر جميع المواد
    final totalPreserved = preservedSessions
      .where((s) => s.status == SessionStatus.completed)
      .length;
    // ما تبقى من الحصة الأسبوعية للتوليد الجديد
    final remainingWeeklyCapacity = (totalWeeklyCapacity - totalPreserved)
        .clamp(0, totalWeeklyCapacity);

    final subjectRequirements =
        subjects.map((meta) {
          // عدد الجلسات الأساسي من الأولوية
          int sessionCount = (meta.priorityScore / 100 * 4).ceil().clamp(1, 4);

          // وضع الطوارئ: امتحان قريب جداً + فهم منخفض
          final exam = semester?.nextExamFor(
            performances
                    .cast<SubjectPerformance?>()
                    .firstWhere(
                      (p) => norm(p?.subjectName ?? '') == norm(meta.name),
                      orElse: () => null,
                    )
                    ?.subjectId ??
                '',
          );
          final daysUntilExam = exam?.daysUntilExam ?? 99;
          final isEmergency = daysUntilExam <= 3 && meta.avgUnderstanding < 3.5;
          final isUrgent = daysUntilExam <= 7 && meta.priorityScore > 70;

          if (isEmergency) {
            sessionCount = (sessionCount + 2).clamp(1, 4);
          } else if (isUrgent) {
            sessionCount = (sessionCount + 1).clamp(1, 4);
          }

          // [FIX] احسب الجلسات المحمية لهذه المادة تحديداً
          final subjectKey =
              schedule
                  .cast<SubjectScheduleEntry?>()
                  .firstWhere(
                    (e) => norm(e?.subjectName ?? '') == norm(meta.name),
                    orElse: () => null,
                  )
                  ?.subjectId ??
              '';
          final preservedForSubject =
              preservedCountBySubject[subjectKey] ??
              preservedCountBySubject[meta.name] ??
              0;

          // اطرح الجلسات المحمية من العدد المطلوب لهذه المادة
          sessionCount = (sessionCount - preservedForSubject).clamp(
            0,
            sessionCount,
          );

          // لا تتجاوز الحد الأسبوعي المتبقي (الكلي - المحمي)
          // الطوارئ تستثنى من هذا القيد
          if (!isEmergency) {
            sessionCount = sessionCount.clamp(0, remainingWeeklyCapacity);
          } else {
            // الطوارئ: حد أقصى مرن لكن لا تتجاوز 2 جلسة إضافية
            sessionCount = sessionCount.clamp(0, remainingWeeklyCapacity + 2);
          }

          final type = _sessionTypeFor(meta.avgUnderstanding);

          final scheduleEntry = schedule
              .cast<SubjectScheduleEntry?>()
              .firstWhere(
                (e) => norm(e?.subjectName ?? '') == norm(meta.name),
                orElse: () => null,
              );
          final realSubjectId =
              (scheduleEntry?.subjectId.isNotEmpty == true)
                  ? scheduleEntry!.subjectId
                  : findPerf(meta.name)?.subjectId;

          return _SubjectRequirement(
            name: meta.name,
            subjectId: realSubjectId,
            sessionCount: sessionCount,
            sessionType: type,
            priorityScore: meta.priorityScore.round(),
            semesterId: semester?.id,
            isEmergency: isEmergency,
            isUrgent: isUrgent,
          );
        }).toList();

    // ── Step 4: توزيع الجلسات ─────────────────────────────────────────────
    final occupied = _buildOccupiedSlots(schedule, sortedSlots);
    return _distributeSessionsAcrossWeek(
      requirements: subjectRequirements,
      occupied: occupied,
      timeSlots: sortedSlots,
      capacity: capacity,
      effectiveDays: adjustedEffectiveDays,
      preservedSessions: preservedSessions,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  _Capacity _resolveCapacity(String duration, String commitment) {
    final row = _kCapacityTable[duration] ?? _kCapacityTable['medium']!;
    return row[commitment] ?? row['medium']!;
  }

  int _resolveEffectiveDays(int rawDays, String commitment) {
    return switch (commitment) {
      'low' => rawDays.clamp(1, 3),
      'high' => rawDays.clamp(4, 6),
      _ => rawDays.clamp(1, 6),
    };
  }

  List<ScheduleTimeSlot> _sortSlotsByPreference(
    List<ScheduleTimeSlot> slots,
    List<String> preferredTimes,
  ) {
    if (preferredTimes.isEmpty) return slots;

    final preferredHours = <int>[];
    for (final time in preferredTimes) {
      preferredHours.addAll(_kPreferredTimeRanges[time] ?? []);
    }
    if (preferredHours.isEmpty) return slots;

    final preferred = <ScheduleTimeSlot>[];
    final others = <ScheduleTimeSlot>[];
    for (final slot in slots) {
      (preferredHours.contains(slot.startHour) ? preferred : others).add(slot);
    }
    return [...preferred, ...others];
  }

  SessionType _sessionTypeFor(double avgUnderstanding) {
    if (avgUnderstanding < 2.5) return SessionType.explain;
    if (avgUnderstanding < 3.5) return SessionType.practice;
    if (avgUnderstanding < 4.5) return SessionType.review;
    return SessionType.activate;
  }

  Map<String, Set<String>> _buildOccupiedSlots(
    List<SubjectScheduleEntry> schedule,
    List<ScheduleTimeSlot> timeSlots,
  ) {
    final occupied = <String, Set<String>>{};
    for (final day in _kStudyDays) {
      occupied[day] = {};
    }
    for (final entry in schedule) {
      if (entry.col >= 0 &&
          entry.col < _kStudyDays.length &&
          entry.row >= 0 &&
          entry.row < timeSlots.length) {
        occupied[_kStudyDays[entry.col]]!.add(timeSlots[entry.row].label);
      }
    }
    return occupied;
  }

  List<StudySession> _distributeSessionsAcrossWeek({
    required List<_SubjectRequirement> requirements,
    required Map<String, Set<String>> occupied,
    required List<ScheduleTimeSlot> timeSlots,
    required _Capacity capacity,
    required int effectiveDays,
    List<StudySession> preservedSessions = const [],
  }) {
    final sessionsPerDay = {for (final d in _kStudyDays) d: 0};
    final takenSlots = {
      for (final d in _kStudyDays) d: Set<String>.from(occupied[d]!),
    };

    for (final s in preservedSessions) {
      if (takenSlots.containsKey(s.dayOfWeek)) {
        takenSlots[s.dayOfWeek]!.add(s.timeSlot);
        // احسب هذه الجلسة ضمن عداد اليوم
        sessionsPerDay[s.dayOfWeek] = (sessionsPerDay[s.dayOfWeek] ?? 0) + 1;
      }
    }

    final generatedAt = DateTime.now();
    final weekStart = _currentWeekStart(generatedAt);
    final todayDate = DateTime(
      generatedAt.year,
      generatedAt.month,
      generatedAt.day,
    );

    final nowMinutes = generatedAt.hour * 60 + generatedAt.minute;

    final availableDays =
        _kStudyDays.where((day) {
          final idx = _kStudyDays.indexOf(day);
          final date = weekStart.add(Duration(days: idx));
          return !date.isBefore(todayDate);
        }).toList();

    final studyDays = availableDays.take(effectiveDays).toSet();
    final sessions = <StudySession>[];

    final sorted = [...requirements]..sort((a, b) {
      if (a.isEmergency && !b.isEmergency) return -1;
      if (!a.isEmergency && b.isEmergency) return 1;
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.priorityScore.compareTo(a.priorityScore);
    });

    for (final req in sorted) {
      var remaining = req.sessionCount;
      final daysToUse = req.isEmergency ? availableDays : studyDays.toList();
      final sessionMinutes =
          req.isEmergency ? capacity.minutes.clamp(60, 120) : capacity.minutes;

      final dayOrder = List.of(daysToUse)
        ..sort((a, b) => sessionsPerDay[a]!.compareTo(sessionsPerDay[b]!));

      for (var pass = 0; pass < 2; pass++) {
        for (final day in dayOrder) {
          if (remaining == 0) break;

          final dailyLimit =
              (pass == 1 && req.isEmergency)
                  ? capacity.maxPerDay * 2
                  : capacity.maxPerDay;
          if (sessionsPerDay[day]! >= dailyLimit) continue;

          final dayIdx = _kStudyDays.indexOf(day);
          final scheduledDate = weekStart.add(Duration(days: dayIdx));
          if (scheduledDate.isBefore(todayDate)) continue;

          final isToday = scheduledDate == todayDate;

          final freeSlot =
              isToday
                  ? _firstFreeSlotWithDurationAfter(
                    takenSlots[day]!,
                    timeSlots,
                    sessionMinutes,
                    nowMinutes, // ← تجاهل الـ slots المنقضية
                  )
                  : _firstFreeSlotWithDuration(
                    takenSlots[day]!,
                    timeSlots,
                    sessionMinutes,
                  );

          if (freeSlot == null) continue;

          takenSlots[day]!.add(freeSlot.label);
          sessionsPerDay[day] = sessionsPerDay[day]! + 1;

          sessions.add(
            StudySession(
              id: _generateId(),
              subjectId: req.subjectId ?? _slugify(req.name, req.semesterId),
              subjectName: req.name,
              dayOfWeek: day,
              timeSlot: freeSlot.label,
              durationMinutes: sessionMinutes.clamp(
                1,
                freeSlot.durationMinutes,
              ),
              priorityScore: req.priorityScore,
              sessionType: req.sessionType,
              status: SessionStatus.planned,
              scheduledDate: scheduledDate,
              generatedAt: generatedAt,
            ),
          );
          remaining--;
        }
        if (remaining == 0) break;
      }
    }

    sessions.sort((a, b) {
      final dc = a.scheduledDate.compareTo(b.scheduledDate);
      return dc != 0
          ? dc
          : _slotStartHour(a.timeSlot).compareTo(_slotStartHour(b.timeSlot));
    });

    return sessions;
  }

  ScheduleTimeSlot? _firstFreeSlotWithDurationAfter(
    Set<String> taken,
    List<ScheduleTimeSlot> timeSlots,
    int requiredMinutes,
    int afterMinutes, // الوقت الحالي بالدقائق منذ منتصف الليل
  ) {
    // المرحلة 1: slot حر + مدة كافية + لم يبدأ بعد
    for (final slot in timeSlots) {
      if (taken.contains(slot.label)) continue;
      if (slot.durationMinutes < requiredMinutes) continue;
      final slotStart = slot.startHour * 60 + slot.startMinute;
      if (slotStart <= afterMinutes) continue; // منقضٍ
      return slot;
    }
    // المرحلة 2: fallback — أي slot حر لم يبدأ بعد (حتى لو مدته أقل)
    for (final slot in timeSlots) {
      if (taken.contains(slot.label)) continue;
      final slotStart = slot.startHour * 60 + slot.startMinute;
      if (slotStart <= afterMinutes) continue;
      return slot;
    }
    // لا يوجد slot متاح اليوم — لا تُولِّد شيئاً
    return null;
  }

  /// يجد أول فترة حرة بمدة كافية
  ScheduleTimeSlot? _firstFreeSlotWithDuration(
    Set<String> taken,
    List<ScheduleTimeSlot> timeSlots,
    int requiredMinutes,
  ) {
    for (final slot in timeSlots) {
      if (!taken.contains(slot.label) &&
          slot.durationMinutes >= requiredMinutes) {
        return slot;
      }
    }
    // fallback: أي فترة حرة حتى لو أقصر من المطلوب
    for (final slot in timeSlots) {
      if (!taken.contains(slot.label)) return slot;
    }
    return null;
  }

  int _slotStartHour(String slotLabel) {
    final startPart = slotLabel.split('-').first.trim();
    return int.tryParse(startPart.split(':').first) ?? 0;
  }

  DateTime _currentWeekStart(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final daysSinceSaturday = switch (today.weekday) {
      6 => 0,
      7 => 1,
      _ => today.weekday + 1,
    };
    return today.subtract(Duration(days: daysSinceSaturday));
  }

  final _uuid = const Uuid();
  String _generateId() => _uuid.v4();

  String _slugify(String name, String? semesterId) {
    final normalized = name.trim().toLowerCase();
    final hash = stableHash(normalized);
    return semesterId?.isNotEmpty == true
        ? 'subj_${semesterId}_$hash'
        : 'subj_$hash';
  }
}

class _SubjectMeta {
  _SubjectMeta({required this.name, required this.performance, this.semester});
  final String name;
  final SubjectPerformance? performance;
  final AcademicSemester? semester;

  double get priorityScore =>
      performance?.priorityScoreWithSemester(semester) ?? 50.0;
  double get avgUnderstanding => performance?.avgUnderstanding ?? 3.0;
}

class _SubjectRequirement {
  const _SubjectRequirement({
    required this.name,
    required this.sessionCount,
    required this.sessionType,
    required this.priorityScore,
    this.subjectId,
    this.semesterId,
    this.isEmergency = false,
    this.isUrgent = false,
  });

  final String name;
  final int sessionCount;
  final SessionType sessionType;
  final int priorityScore;
  final String? subjectId;
  final String? semesterId;
  final bool isEmergency;
  final bool isUrgent;
}

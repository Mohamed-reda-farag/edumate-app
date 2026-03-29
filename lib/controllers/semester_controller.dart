import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/gamification_model.dart';
import '../models/study_session_model.dart';
import '../models/academic_semester_model.dart';
import '../models/subject_performance_model.dart';
import '../models/semester_achievement_record_model.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/semester_repository.dart';
import '../repositories/attendance_repository.dart';
import '../controllers/notification_controller.dart';

// ─── SemesterController ───────────────────────────────────────────────────────

class SemesterController extends ChangeNotifier {
  SemesterController({
    required SemesterRepository semesterRepo,
    required ScheduleRepository scheduleRepo,
    required AttendanceRepository attendanceRepo,
    required NotificationController notificationController,
  }) : _repo = semesterRepo,
       _scheduleRepo = scheduleRepo,
       _attendanceRepo = attendanceRepo,
       _notifController = notificationController;

  final SemesterRepository _repo;
  final ScheduleRepository _scheduleRepo;
  final AttendanceRepository _attendanceRepo;
  final NotificationController _notifController;

  // ── State ─────────────────────────────────────────────────────────────────

  AcademicSemester? _activeSemester;
  List<SemesterAchievementRecord> _semesterRecords = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  bool _archivingInProgress = false;

  StreamSubscription<AcademicSemester?>? _semesterSub;
  StreamSubscription<List<SemesterAchievementRecord>>? _recordsSub;

  // ── Public Getters ────────────────────────────────────────────────────────

  AcademicSemester? get activeSemester => _activeSemester;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Subject> get subjects =>
      List.unmodifiable(_activeSemester?.subjects ?? []);

  bool get needsSetup => _activeSemester == null && !_isLoading;

  bool get hasUrgentExam =>
      _activeSemester?.upcomingExams.any((e) => e.isUrgent) ?? false;

  bool get shouldShowEndDialog => _activeSemester?.shouldShowEndDialog ?? false;

  List<SemesterAchievementRecord> get semesterRecords =>
      List.unmodifiable(_semesterRecords);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    await _cancelSubscriptions();

    _isLoading = true;
    _error = null;

    // [FIX #10] _initialized يُعيَّن true داخل الـ try بعد نجاح التحميل
    // فقط — مطابقةً لنمط task_controller.
    //
    // القديم: _initialized = true قبل الـ try مع إعادته false في الـ catch.
    // هذا يُنشئ window خطيرة: إذا حدث استثناء غير متوقع بين السطرين،
    // يبقى _initialized = true ولا يمكن إعادة init() أبداً.
    //
    // الجديد: _initialized = true بعد النجاح فقط — إذا فشل يبقى false
    // ويمكن إعادة المحاولة بأمان.
    try {
      _activeSemester = await _repo.getActiveSemester();
      debugPrint(
        '[DEBUG-CTRL] activeSemester after load: ${_activeSemester?.id}',
      );
      debugPrint('[DEBUG-CTRL] needsSetup will be: ${_activeSemester == null}');
      _semesterRecords = await _scheduleRepo.getAllSemesterRecords();

      _initialized = true; // ✅ بعد النجاح فقط
    } catch (e) {
      _error = e.toString();
      // _initialized يبقى false — يمكن إعادة استدعاء init()
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = false;
    notifyListeners();

    // جدولة تذكيرات الامتحانات — fire-and-forget
    if (_activeSemester != null) {
      _scheduleExamsForSemester(_activeSemester!);
    }

    _semesterSub = _repo.watchActiveSemester().listen(
      (s) {
        if (_archivingInProgress) return;
        if (s == null && _activeSemester != null) return;
        _activeSemester = s;
        notifyListeners();

        if (s != null && s.shouldShowEndDialog) {
          _notifController
              .onSemesterEnd(
                semesterLabel: '${s.type.labelAr} ${s.academicYear}',
                endNotified: s.endNotified,
              )
              .ignore();
        }
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    _recordsSub = _scheduleRepo.watchSemesterRecords().listen(
      (records) {
        _semesterRecords = records;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> reset() async {
    await _cancelSubscriptions();
    _activeSemester = null;
    _semesterRecords = [];
    _isLoading = false;
    _error = null;
    _initialized = false;
    _archivingInProgress = false;
    notifyListeners();
  }

  // ── Semester CRUD ─────────────────────────────────────────────────────────

  Future<void> saveSemester(AcademicSemester semester) async {
    debugPrint('[DEBUG-CTRL-SAVE] saveSemester called for ${semester.id}');
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.saveSemester(semester);
      debugPrint('[DEBUG-CTRL-SAVE] repo.saveSemester SUCCESS');
      _activeSemester = semester;
      _error = null;
    } catch (e) {
      debugPrint('[DEBUG-CTRL-SAVE] repo.saveSemester FAILED: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Subjects Management ───────────────────────────────────────────────────

  Future<void> saveSubjects(List<Subject> subjects) async {
    if (_activeSemester == null) return;
    await saveSemester(_activeSemester!.copyWith(subjects: subjects));
  }

  Future<void> addSubject(Subject subject) async {
    if (_activeSemester == null) return;
    final exists = _activeSemester!.subjects.any((s) => s.id == subject.id);
    if (exists) return;
    await saveSemester(
      _activeSemester!.copyWith(
        subjects: [..._activeSemester!.subjects, subject],
      ),
    );
  }

  Future<void> updateSubject(Subject subject) async {
    if (_activeSemester == null) return;
    await saveSemester(
      _activeSemester!.copyWith(
        subjects:
            _activeSemester!.subjects
                .map((s) => s.id == subject.id ? subject : s)
                .toList(),
      ),
    );
  }

  Future<void> removeSubject(String subjectId) async {
    if (_activeSemester == null) return;
    await saveSemester(
      _activeSemester!.copyWith(
        subjects:
            _activeSemester!.subjects.where((s) => s.id != subjectId).toList(),
      ),
    );
  }

  // ── Exam Management ───────────────────────────────────────────────────────

  Future<void> updateExam(SemesterExam updatedExam) async {
    if (_activeSemester == null) return;
    await saveSemester(
      _activeSemester!.copyWith(
        exams:
            _activeSemester!.exams
                .map(
                  (e) =>
                      e.subjectId == updatedExam.subjectId &&
                              e.type == updatedExam.type
                          ? updatedExam
                          : e,
                )
                .toList(),
      ),
    );

    final examId = _buildExamId(updatedExam);
    if (updatedExam.completed) {
      _notifController.cancelExamReminders(examId).ignore();
    } else {
      _notifController
          .scheduleExamReminders(
            examId: examId,
            subjectName: updatedExam.subjectName,
            examTypeLabel: _examTypeLabel(updatedExam.type),
            examDate: updatedExam.examDate,
          )
          .ignore();
    }
  }

  Future<void> addExam(SemesterExam exam) async {
    if (_activeSemester == null) return;
    await saveSemester(
      _activeSemester!.copyWith(exams: [..._activeSemester!.exams, exam]),
    );
    _notifController
        .scheduleExamReminders(
          examId: _buildExamId(exam),
          subjectName: exam.subjectName,
          examTypeLabel: _examTypeLabel(exam.type),
          examDate: exam.examDate,
        )
        .ignore();
  }

  Future<void> removeExam(String subjectId, ExamType type) async {
    if (_activeSemester == null) return;
    final exam = _activeSemester!.exams.firstWhere(
      (e) => e.subjectId == subjectId && e.type == type,
      orElse: () => throw StateError('Exam not found: $subjectId / ${type.name}'),
    );
    _notifController.cancelExamReminders(_buildExamId(exam)).ignore();

    await saveSemester(
      _activeSemester!.copyWith(
        exams:
            _activeSemester!.exams
                .where((e) => !(e.subjectId == subjectId && e.type == type))
                .toList(),
      ),
    );
  }

  Future<void> markEndNotified() async {
    if (_activeSemester == null) return;
    await saveSemester(_activeSemester!.copyWith(endNotified: true));
  }

  // ── Semester End Flow ─────────────────────────────────────────────────────

  Future<void> snoozeEndDialog() async {
    if (_activeSemester == null) return;
    await saveSemester(
      _activeSemester!.copyWith(
        snoozedUntil: DateTime.now().add(const Duration(hours: 24)),
      ),
    );
  }

  Future<void> archiveAndEndSemester({
    required GamificationData currentGamification,
    required List<SubjectPerformance> performances,
  }) async {
    if (_activeSemester == null) return;

    _isLoading = true;
    _archivingInProgress = true;
    notifyListeners();

    try {
      final semester = _activeSemester!;

      // ── 1. جلب جلسات الأسبوع قبل المسح ──────────────────────────────────
      List<StudySession> allSessionsSnapshot = [];
      try {
        allSessionsSnapshot = await _attendanceRepo.getWeekSessions();
      } catch (_) {
        // نكمل الأرشفة بدون إحصائيات الجلسات إذا فشل الجلب
      }

      // ── 2. بناء إحصائيات الفصل ────────────────────────────────────────────
      final stats = _buildSemesterStats(
        performances,
        weekSessions: allSessionsSnapshot,
      );

      // ── 3. حساب الإنجازات الخاصة بهذا الفصل ──────────────────────────────
      final sortedRecords = List.of(_semesterRecords)
        ..sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
      final previousUnlocked = sortedRecords.isNotEmpty
          ? sortedRecords.first.unlockedAchievementIds.toSet()
          : <String>{};

      final thisSemesterAchievements =
          currentGamification.unlockedAchievements
              .where((id) => !previousUnlocked.contains(id))
              .toList();
      final previousTotalPoints =
          _semesterRecords.isNotEmpty
              ? _semesterRecords.first.totalPointsAtEnd
              : 0;
      final semesterPoints = (currentGamification.totalPoints -
              previousTotalPoints)
          .clamp(0, currentGamification.totalPoints);

      final record = SemesterAchievementRecord(
        id: semester.id,
        userId: semester.userId,
        semesterType: semester.type,
        academicYear: semester.academicYear,
        startDate: semester.startDate,
        endDate: semester.endDate,
        archivedAt: DateTime.now(),
        unlockedAchievementIds: thisSemesterAchievements,
        semesterPoints: semesterPoints,
        longestStreakInSemester: currentGamification.longestStreak,
        stats: stats,
        totalPointsAtEnd: currentGamification.totalPoints,
      );

      // ── 4. حفظ الأرشيف ────────────────────────────────────────────────────
      await _scheduleRepo.saveSemesterRecord(record);

      // ── 5. إلغاء تفعيل الفصل القديم ─────────────────────────────────────
      await _repo.deactivateSemester(semester.id);

      // ── 6. مسح بيانات الفصل القديم ────────────────────────────────────────
      await Future.wait([
        _scheduleRepo.clearSchedule(),
        _scheduleRepo.clearAllPerformances(),
        _attendanceRepo.clearWeekSessions(),
        // ملاحظة: attendance records لا تُمسح عمداً —
        // تُستخدم لمراجعة تفاصيل الفصول السابقة
      ], eagerError: false);

      _activeSemester = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _archivingInProgress = false;
      notifyListeners();
    }
  }

  // ── Legacy ────────────────────────────────────────────────────────────────
  @Deprecated('استخدم archiveAndEndSemester بدلاً منه — يحفظ الإنجازات والإحصائيات قبل الإنهاء')
  Future<void> endSemester() async {
    if (_activeSemester == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.deactivateSemester(_activeSemester!.id);
      _activeSemester = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _cancelSubscriptions() async {
    await _semesterSub?.cancel();
    await _recordsSub?.cancel();
    _semesterSub = null;
    _recordsSub = null;
  }

  String _buildExamId(SemesterExam exam) =>
      '${exam.subjectId}_${exam.type.name}';

  String _examTypeLabel(ExamType type) {
    switch (type) {
      case ExamType.midterm1:
        return 'ميدترم 1';
      case ExamType.midterm2:
        return 'ميدترم 2';
      case ExamType.finalExam:
        return 'فاينال';
    }
  }

  void _scheduleExamsForSemester(AcademicSemester semester) {
    _notifController
        .scheduleAllExamReminders(
          exams:
              semester.exams
                  .map(
                    (e) => (
                      examId: _buildExamId(e),
                      subjectName: e.subjectName,
                      examTypeLabel: _examTypeLabel(e.type),
                      examDate: e.examDate,
                      completed: e.completed,
                    ),
                  )
                  .toList(),
        )
        .ignore();
  }

  SemesterStats _buildSemesterStats(
    List<SubjectPerformance> performances, {
    List<StudySession> weekSessions = const [],
  }) {
    if (performances.isEmpty) return SemesterStats.empty;

    int totalLectures = 0;
    int attended = 0;
    double totalUnderstanding = 0;
    double totalStudyHours = 0;
    double maxPriority = 0;

    final perSubject = <String, SubjectEndStats>{};

    for (final p in performances) {
      totalLectures += p.totalLectures;
      attended += p.attendedCount + p.lateCount;
      totalUnderstanding += p.avgUnderstanding;
      totalStudyHours += p.studyHoursLogged;
      if (p.priorityScore > maxPriority) maxPriority = p.priorityScore;

      perSubject[p.subjectId] = SubjectEndStats(
        subjectName: p.subjectName,
        difficulty: p.difficulty,
        attendanceRate: p.attendanceRate,
        avgUnderstanding: p.avgUnderstanding,
        studyHours: p.studyHoursLogged,
      );
    }

    final overallAttendance =
        totalLectures == 0 ? 0.0 : attended / totalLectures;
    final avgUnderstanding = totalUnderstanding / performances.length;

    final completedSessions =
        weekSessions.where((s) => s.status == SessionStatus.completed).length;
    final skippedSessions =
        weekSessions.where((s) => s.status == SessionStatus.skipped).length;
    final totalSessions = weekSessions.length;
    final complianceRate =
        totalSessions == 0 ? 0.0 : completedSessions / totalSessions;

    return SemesterStats(
      totalLecturesRecorded: totalLectures,
      attendedLectures: attended,
      overallAttendanceRate: overallAttendance,
      avgUnderstanding: avgUnderstanding,
      totalStudyHours: totalStudyHours,
      completedStudySessions: completedSessions,
      skippedStudySessions: skippedSessions,
      studyComplianceRate: complianceRate,
      maxPriorityScore: maxPriority,
      perSubject: perSubject,
    );
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

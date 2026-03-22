import 'dart:async';

import 'package:flutter/material.dart';

import 'semester_controller.dart';
import '../models/study_session_model.dart';
import '../models/subject_performance_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/schedule_repository.dart';
import '../services/study_plan_service.dart';

class ScheduleController extends ChangeNotifier {
  ScheduleController({
    required ScheduleRepository scheduleRepo,
    required AttendanceRepository attendanceRepo,
    required StudyPlanService planService,
    required SemesterController semesterController,
    required String Function() getUserId,
  })  : _scheduleRepo = scheduleRepo,
        _attendanceRepo = attendanceRepo,
        _planService = planService,
        _semesterController = semesterController,
        _getUserId = getUserId;

  final ScheduleRepository _scheduleRepo;
  final AttendanceRepository _attendanceRepo;
  final StudyPlanService _planService;
  final SemesterController _semesterController;
  final String Function() _getUserId;

  // [FIX] callback يُستدعى بعد حفظ الجدول أو توليد خطة المذاكرة —
  // يُسجَّل من main.dart بعد إنشاء TaskSyncService لتجنب circular dependency.
  // الهدف: إخبار TaskController بإعادة sync المهام عند تغيّر البيانات،
  // لأن taskController.init() يُستدعى مرة واحدة فقط عند تسجيل الدخول
  // وقد يكون الجدول/الخطة فارغَين في تلك اللحظة.
  Future<void> Function()? onScheduleChanged;

  // ── State ─────────────────────────────────────────────────────────────────

  List<SubjectScheduleEntry> _schedule = [];
  List<SubjectPerformance> _performances = [];
  List<StudySession> _todaySessions = [];
  List<StudySession> _weekSessions = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  StreamSubscription<List<SubjectScheduleEntry>>? _scheduleSub;
  StreamSubscription<List<SubjectPerformance>>? _performancesSub;
  StreamSubscription<List<StudySession>>? _todaySessionsSub;
  StreamSubscription<List<StudySession>>? _weekSessionsSub;

  // ── Public Getters ────────────────────────────────────────────────────────

  List<SubjectScheduleEntry> get schedule      => List.unmodifiable(_schedule);
  List<SubjectPerformance>   get performances  => List.unmodifiable(_performances);
  List<StudySession>         get todaySessions => List.unmodifiable(_todaySessions);
  List<StudySession>         get weekSessions  => List.unmodifiable(_weekSessions);
  bool                       get isLoading     => _isLoading;
  String?                    get error         => _error;
  bool                       get isInitialized => _initialized;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _cancelSubscriptions();
    await _autoSkipMissedSessions();

    _isLoading = true;
    _error = null;

    try {
      final results = await Future.wait([
        _scheduleRepo.loadSchedule(),
        _scheduleRepo.getAllPerformances(),
        _attendanceRepo.getSessionsByDate(DateTime.now()),
      ]);

      _schedule      = results[0] as List<SubjectScheduleEntry>;
      _performances  = results[1] as List<SubjectPerformance>;
      _todaySessions = results[2] as List<StudySession>;
    } catch (e) {
      _error = e.toString();
      _initialized = false;
      _isLoading = false;
      notifyListeners();
      return;
    } finally {
      if (_initialized) {
        _isLoading = false;
        notifyListeners();
      }
    }

    // ── streams حية ──────────────────────────────────────────────────────────

    _scheduleSub = _scheduleRepo.watchSchedule().listen(
      (entries) { _schedule = entries; notifyListeners(); },
      onError: (Object e) { _error = e.toString(); notifyListeners(); },
    );

    _performancesSub = _scheduleRepo.watchAllPerformances().listen(
      (perfs) { _performances = perfs; notifyListeners(); },
      onError: (Object e) { _error = e.toString(); notifyListeners(); },
    );

    _todaySessionsSub = _attendanceRepo.watchTodaySessions().listen(
      (sessions) { _todaySessions = sessions; notifyListeners(); },
      onError: (Object e) { _error = e.toString(); notifyListeners(); },
    );

    _weekSessionsSub = _attendanceRepo.watchWeekSessions().listen(
      (sessions) { _weekSessions = sessions; notifyListeners(); },
      onError: (Object e) { _error = e.toString(); notifyListeners(); },
    );
  }

  Future<void> reset() async {
    _initialized = false;
    await _cancelSubscriptions();

    _schedule      = [];
    _performances  = [];
    _todaySessions = [];
    _weekSessions  = [];
    _isLoading     = false;
    _error         = null;

    notifyListeners();
  }

  Future<void> _autoSkipMissedSessions() async {
    final now = DateTime.now();
    final missed = _weekSessions.where((s) =>
        s.status == SessionStatus.planned &&
        s.scheduledDate.isBefore(DateTime(now.year, now.month, now.day))).toList();

    for (final s in missed) {
      await _attendanceRepo.updateSessionStatus(s.id, SessionStatus.skipped);
    }
  }

  // ── Schedule CRUD ─────────────────────────────────────────────────────────

  Future<void> saveSchedule(List<SubjectScheduleEntry> entries) async {
    _setLoading(true);
    try {
      await _scheduleRepo.saveSchedule(entries);
      _schedule = entries;
      _error = null;
      // [FIX] إخطار TaskController بتغيّر الجدول لإعادة sync المهام
      onScheduleChanged?.call().ignore();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addScheduleEntry(SubjectScheduleEntry entry) async {
    _setLoading(true);
    try {
      final updated = [..._schedule, entry];
      await _scheduleRepo.saveSchedule(updated);
      _schedule = updated;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateScheduleEntry(SubjectScheduleEntry entry) async {
    _setLoading(true);
    try {
      final updated = _schedule
          .map((e) => e.id == entry.id ? entry : e)
          .toList();
      await _scheduleRepo.saveSchedule(updated);
      _schedule = updated;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteScheduleEntry(String entryId) async {
    _setLoading(true);
    try {
      final updated = _schedule.where((e) => e.id != entryId).toList();
      await _scheduleRepo.saveSchedule(updated);
      _schedule = updated;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// حذف بيانات أداء مادة — يُستدعى من SubjectManagementScreen عند حذف مادة
  Future<void> deleteSubjectPerformance(String subjectId) async {
    _setLoading(true);
    try {
      await _scheduleRepo.deletePerformance(subjectId);
      _performances = _performances
          .where((p) => p.subjectId != subjectId)
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePerformanceDifficulty(
      String subjectId, int difficulty, {String? subjectName}) async {
    _setLoading(true);
    try {
      final existing = _performances.cast<SubjectPerformance?>().firstWhere(
            (p) => p?.subjectId == subjectId,
            orElse: () => null,
          );

      final SubjectPerformance updated;
      if (existing != null) {
        updated = existing.copyWith(
          difficulty: difficulty,
          lastUpdated: DateTime.now(),
        );
        _performances = _performances
            .map((p) => p.subjectId == subjectId ? updated : p)
            .toList();
      } else {
        // استخدم subjectName الممرَّر مباشرة — لا تبحث في _schedule
        final name = subjectName ??
            _schedule
                .cast<SubjectScheduleEntry?>()
                .firstWhere((e) => e?.subjectId == subjectId,
                    orElse: () => null)
                ?.subjectName ??
            subjectId;

        final totalLectures =
            _semesterController.activeSemester?.totalLecturesPerSubject ?? 0;

        updated = SubjectPerformance(
          subjectId: subjectId,
          subjectName: name,
          difficulty: difficulty,
          totalLectures: totalLectures,
          attendedCount: 0,
          lateCount: 0,
          avgUnderstanding: 3.0,
          studyHoursLogged: 0,
          lastUpdated: DateTime.now(),
        );
        _performances = [..._performances, updated];
      }

      await _scheduleRepo.savePerformance(updated);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeSubjectProgress({
    required String subjectId,
    required String subjectName,
    required int difficulty,
    required int attendedCount,
    required int totalLectures,
  }) async {
    final safeTotalLectures = totalLectures > 0 ? totalLectures : 1;
    final safeAttended = attendedCount.clamp(0, safeTotalLectures);

    try {
      final existing = _performances.cast<SubjectPerformance?>().firstWhere(
            (p) => p?.subjectId == subjectId,
            orElse: () => null,
          );

      final perf = existing != null
          ? existing.copyWith(
              attendedCount: safeAttended,
              totalLectures: safeTotalLectures,
              difficulty: difficulty,
              lastUpdated: DateTime.now(),
            )
          : SubjectPerformance(
              subjectId: subjectId,
              subjectName: subjectName,
              difficulty: difficulty,
              attendedCount: safeAttended,
              lateCount: 0,
              totalLectures: safeTotalLectures,
              avgUnderstanding: 3.0,
              studyHoursLogged: 0,
              lastUpdated: DateTime.now(),
            );

      await _scheduleRepo.savePerformance(perf);

      if (existing != null) {
        _performances = _performances
            .map((p) => p.subjectId == subjectId ? perf : p)
            .toList();
      } else {
        _performances = [..._performances, perf];
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> generateAndSavePlan({
    Map<String, dynamic>? userPreferences,
  }) async {
    if (_schedule.isEmpty) {
      _error = 'لا يمكن توليد الخطة: الجدول الدراسي فارغ';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final userId = _semesterController.activeSemester?.userId.isNotEmpty == true
          ? _semesterController.activeSemester!.userId
          : _getUserId();

      // [FIX] تخطي الجلسات الفائتة من الأسبوع الحالي قبل المسح
      // حتى تُخصم نقاطها ولا تُفقد بصمت عند clearWeekSessions
      final now = DateTime.now();
      final missedSessions = _weekSessions.where((s) =>
          s.status == SessionStatus.planned &&
          s.scheduledDate.isBefore(DateTime(now.year, now.month, now.day))).toList();

      for (final s in missedSessions) {
        await _attendanceRepo.updateSessionStatus(
          s.id,
          SessionStatus.skipped,
        );
      }

      final sessions = await _planService.generateWeeklyPlan(
        schedule:        _schedule,
        performances:    _performances,
        semester:        _semesterController.activeSemester,
        userId:          userId,
        userPreferences: userPreferences,
      );

      await _attendanceRepo.clearWeekSessions();
      await _attendanceRepo.saveSessions(sessions);
      _error = null;
      onScheduleChanged?.call().ignore();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _scheduleSub?.cancel();
    _performancesSub?.cancel();
    _todaySessionsSub?.cancel();
    _weekSessionsSub?.cancel();
    super.dispose();
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _cancelSubscriptions() async {
    await _scheduleSub?.cancel();
    await _performancesSub?.cancel();
    await _todaySessionsSub?.cancel();
    await _weekSessionsSub?.cancel();
    _scheduleSub      = null;
    _performancesSub  = null;
    _todaySessionsSub = null;
    _weekSessionsSub  = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
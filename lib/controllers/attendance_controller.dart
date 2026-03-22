import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/attendance_record_model.dart';
import '../models/gamification_model.dart';
import '../models/study_session_model.dart';
import '../models/subject_performance_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/schedule_repository.dart';
import '../services/gamification_service.dart';
import 'semester_controller.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController({
    required AttendanceRepository attendanceRepo,
    required ScheduleRepository scheduleRepo,
    required GamificationService gamificationService,
    required SemesterController semesterController,
  })  : _attendanceRepo = attendanceRepo,
        _scheduleRepo = scheduleRepo,
        _gamificationService = gamificationService,
        _semesterController = semesterController;

  final AttendanceRepository _attendanceRepo;
  final ScheduleRepository _scheduleRepo;
  final GamificationService _gamificationService;
  final SemesterController _semesterController;

  // ── State ─────────────────────────────────────────────────────────────────

  final Map<String, List<AttendanceRecord>> _recordsBySubject = {};
  List<StudySession> _todaySessions = [];
  GamificationData? _gamification;
  bool _isLoading = false;
  String? _error;

  int _suppressCount = 0;
  bool get _shouldSuppressStream => _suppressCount > 0;

  StreamSubscription<GamificationData?>? _gamificationSub;
  StreamSubscription<List<StudySession>>? _todaySessionsSub;

  // ── Public Getters ────────────────────────────────────────────────────────

  List<StudySession> get todaySessions => List.unmodifiable(_todaySessions);
  GamificationData? get gamification => _gamification;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AttendanceRecord> getSubjectRecords(String subjectId) =>
      List.unmodifiable(_recordsBySubject[subjectId] ?? []);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _cancelSubscriptions();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _attendanceRepo.getGamification(),
        _attendanceRepo.getSessionsByDate(DateTime.now()),
      ]);

      _gamification = results[0] as GamificationData?;
      _gamification =
          await _attendanceRepo.checkAndResetWeeklyPoints() ?? _gamification;
      _todaySessions = results[1] as List<StudySession>;

      await _preloadAllSubjectRecords();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _gamificationSub = _attendanceRepo.watchGamification().listen(
      (data) {
        if (_shouldSuppressStream) return;
        _gamification = data;
        notifyListeners();
      },
      onError: (Object e) {
        if (_shouldSuppressStream) return;
        _error = '[gamification] ${e.toString()}';
        notifyListeners();
      },
    );

    _todaySessionsSub = _attendanceRepo.watchTodaySessions().listen(
      (sessions) {
        _todaySessions = sessions;
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

    _recordsBySubject.clear();
    _todaySessions = [];
    _gamification = null;
    _isLoading = false;
    _error = null;
    _suppressCount = 0;

    notifyListeners();
  }

  // ── Methods ───────────────────────────────────────────────────────────────

  Future<void> loadSubjectRecords(String subjectId) async {
    _setLoading(true);
    try {
      final records = await _attendanceRepo.getRecordsBySubject(subjectId);
      _recordsBySubject[subjectId] = records;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    _setLoading(true);
    _suppressCount++;
    try {
      await _attendanceRepo.addRecord(record);

      final list =
          List<AttendanceRecord>.from(_recordsBySubject[record.subjectId] ?? []);
      list.insert(0, record);
      _recordsBySubject[record.subjectId] = list;

      await _recalculatePerformance(record.subjectId);

      if (_gamification == null) {
        _error = 'لم يتم تحميل بيانات النقاط، لن تُحتسب النقاط';
      } else {
        var gam = _gamificationService.addAttendancePoints(
          _gamification!,
          record,
        );

        final allRecords = _recordsBySubject.values.expand((r) => r).toList();
        gam = _gamificationService.checkAndUnlockAchievements(
          gam,
          allRecords,
          _todaySessions,
        );

        await _attendanceRepo.updateGamification(gam);
        _gamification = gam;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _suppressCount--;
      _setLoading(false);
    }
  }

  /// [understandingRating] تقييم فهم الطالب لجلسة المذاكرة (1-5) —
  /// يُمرَّر عند إكمال الجلسة ويؤثر على أولوية المادة في خطة المذاكرة.
  Future<void> updateSessionStatus(
    String sessionId,
    SessionStatus status, {
    double? completionRate,
    int? understandingRating,
    String? notes,
  }) async {
    _setLoading(true);
    _suppressCount++;
    try {
      await _attendanceRepo.updateSessionStatus(
        sessionId,
        status,
        completionRate: completionRate,
        notes: notes,
      );

      final targetSession = _todaySessions.cast<StudySession?>().firstWhere(
            (s) => s?.id == sessionId,
            orElse: () => null,
          );

      if (targetSession != null) {
        final updatedSession = targetSession.copyWith(
          status: status,
          completionRate: completionRate,
          notes: notes,
        );

        // [FIX] تحديث studyHoursLogged و avgUnderstanding في SubjectPerformance
        // عند إكمال جلسة المذاكرة — كان مفقوداً مما يجعل أولويات المواد
        // في خطة المذاكرة لا تعكس واقع جلسات الطالب الفعلية.
        if (status == SessionStatus.completed) {
          await _updateStudyPerformance(
            subjectId: targetSession.subjectId,
            durationMinutes: targetSession.durationMinutes,
            understandingRating: understandingRating,
          );
        }

        if (_gamification != null) {
          var gam = _gamificationService.addStudySessionPoints(
            _gamification!,
            updatedSession,
          );

          final allRecords = _recordsBySubject.values.expand((r) => r).toList();
          gam = _gamificationService.checkAndUnlockAchievements(
            gam,
            allRecords,
            _todaySessions,
          );

          await _attendanceRepo.updateGamification(gam);
          _gamification = gam;
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _suppressCount--;
      _setLoading(false);
    }
  }

  /// حذف جلسات المذاكرة الخاصة بمادة — يُستدعى من SubjectManagementScreen
  Future<void> deleteSessionsBySubject(String subjectId) async {
    _setLoading(true);
    try {
      await _attendanceRepo.deleteSessionsBySubject(subjectId);
      _todaySessions = _todaySessions
          .where((s) => s.subjectId != subjectId)
          .toList();
      _recordsBySubject.remove(subjectId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _gamificationSub?.cancel();
    _todaySessionsSub?.cancel();
    super.dispose();
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _cancelSubscriptions() async {
    await _gamificationSub?.cancel();
    await _todaySessionsSub?.cancel();
    _gamificationSub = null;
    _todaySessionsSub = null;
  }

  Future<void> _preloadAllSubjectRecords() async {
    final subjects = _semesterController.activeSemester?.subjects ?? [];
    if (subjects.isEmpty) return;

    try {
      final futures = subjects.map(
        (s) => _attendanceRepo
            .getRecordsBySubject(s.id)
            .then((records) => _recordsBySubject[s.id] = records),
      );
      await Future.wait(futures, eagerError: false);
    } catch (e) {
      debugPrint('[AttendanceController] _preloadAllSubjectRecords partial error: $e');
    }
  }

  Future<void> _recalculatePerformance(String subjectId) async {
    try {
      final records = _recordsBySubject[subjectId] ?? [];
      if (records.isEmpty) return;

      final existing = await _scheduleRepo.getPerformance(subjectId);
      final totalLectures =
          _semesterController.activeSemester?.totalLecturesPerSubject ??
              records.length;

      // ── المحاضرات فقط لحساب attendedCount و lateCount ────────────────
      final lectureRecords = records
          .where((r) => r.sessionType == 'lec')
          .toList();

      int attendedCount = 0;
      int lateCount     = 0;

      for (final r in lectureRecords) {
        if (r.status == AttendanceStatus.attended) {
          attendedCount++;
        } else if (r.status == AttendanceStatus.late) {
          // دائماً يُحسب ضمن lateCount بغض النظر عن مدة التأخر
          lateCount++;
        }
      }

      // ── avgUnderstanding من كل الأنواع مع تأثير التأخر ───────────────
      final allRatedRecords = records
          .where((r) =>
              r.understandingRating != null &&
              (r.status == AttendanceStatus.attended ||
                  r.status == AttendanceStatus.late))
          .toList();

      double totalRating = 0;
      double totalWeight = 0;

      for (final r in allRatedRecords) {
        final rawRating = r.understandingRating!.toDouble();
        double rating   = rawRating;

        if (r.status == AttendanceStatus.late &&
            r.lectureDurationMinutes != null &&
            r.lectureDurationMinutes! > 0) {
          final lateRatio = r.lateMinutes / r.lectureDurationMinutes!;

          if (lateRatio >= 0.5) {
            // تأخر > 50% → لا يدخل في avgUnderstanding
            continue;
          } else if (lateRatio >= 0.25) {
            // تأخر 25-50% → ينقص 1.0
            rating = (rawRating - 1.0).clamp(1.0, 5.0);
          } else if (lateRatio >= 0.10) {
            // تأخر 10-25% → ينقص 0.5
            rating = (rawRating - 0.5).clamp(1.0, 5.0);
          }
          // تأخر < 10% → لا تأثير
        }

        totalRating += rating;
        totalWeight += 1.0;
      }

      final avgUnderstanding = totalWeight == 0
          ? (existing?.avgUnderstanding ?? 3.0)
          : totalRating / totalWeight;

      final updated = SubjectPerformance(
        subjectId: subjectId,
        subjectName: records.first.subjectName,
        difficulty: existing?.difficulty ?? 3,
        totalLectures: totalLectures,
        attendedCount: attendedCount,
        lateCount: lateCount,
        avgUnderstanding: avgUnderstanding.clamp(0.0, 5.0),
        studyHoursLogged: existing?.studyHoursLogged ?? 0.0,
        lastUpdated: DateTime.now(),
      );

      await _scheduleRepo.savePerformance(updated);
    } catch (e) {
      debugPrint('[AttendanceController] _recalculatePerformance error: $e');
    }
  }

  /// يُحدِّث studyHoursLogged و avgUnderstanding في SubjectPerformance
  /// عند إكمال جلسة مذاكرة.
  Future<void> _updateStudyPerformance({
    required String subjectId,
    required int durationMinutes,
    int? understandingRating,
  }) async {
    try {
      final existing = await _scheduleRepo.getPerformance(subjectId);
      if (existing == null) return;

      final addedHours = durationMinutes / 60.0;

      // إعادة حساب avgUnderstanding إذا قدّم الطالب تقييماً —
      // نحسب متوسطاً مرجَّحاً: نعطي تقييم الجلسة الحالية وزناً واحداً
      // مقابل المتوسط القديم لتجنب تأثير قيمة واحدة بشكل مبالغ فيه.
      final newAvg = (understandingRating != null)
          ? (existing.avgUnderstanding + understandingRating) / 2.0
          : existing.avgUnderstanding;

      final updated = SubjectPerformance(
        subjectId: existing.subjectId,
        subjectName: existing.subjectName,
        difficulty: existing.difficulty,
        totalLectures: existing.totalLectures,
        attendedCount: existing.attendedCount,
        lateCount: existing.lateCount,
        avgUnderstanding: newAvg.clamp(1.0, 5.0),
        studyHoursLogged: existing.studyHoursLogged + addedHours,
        lastUpdated: DateTime.now(),
      );

      await _scheduleRepo.savePerformance(updated);
      debugPrint(
        '[AttendanceController] Study performance updated: $subjectId '
        'hours=${updated.studyHoursLogged.toStringAsFixed(1)} '
        'avgUnderstanding=${updated.avgUnderstanding.toStringAsFixed(1)}',
      );
    } catch (e) {
      debugPrint('[AttendanceController] _updateStudyPerformance error: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
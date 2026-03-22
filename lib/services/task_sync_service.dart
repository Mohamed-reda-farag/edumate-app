import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart' hide TaskStatus;

import '../models/task_model.dart';
import '../models/study_session_model.dart';
import '../models/schedule_time_settings.dart';
import '../repositories/task_repository.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/global_learning_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Constants
// ══════════════════════════════════════════════════════════════════════════════

const String kDailyTaskSyncTask = 'dailyTaskSync';
const String kDailyTaskSyncTag  = 'daily_task_sync_tag';

// ══════════════════════════════════════════════════════════════════════════════
// TaskSyncService
// ══════════════════════════════════════════════════════════════════════════════

class TaskSyncService {
  TaskSyncService({
    required TaskRepository taskRepository,
    required ScheduleController scheduleController,
    required GlobalLearningState learningState,
    required String Function() getUserId,
  })  : _taskRepo = taskRepository,
        _scheduleController = scheduleController,
        _learningState = learningState,
        _getUserId = getUserId;

  final TaskRepository _taskRepo;
  final ScheduleController _scheduleController;
  final GlobalLearningState _learningState;
  final String Function() _getUserId;

  // ══════════════════════════════════════════════════════════════════════════
  //  Workmanager Registration
  // ══════════════════════════════════════════════════════════════════════════

  /// تسجيل مهمة الـ background sync اليومية (يُستدعى عند تسجيل الدخول)
  static Future<void> registerDailySync() async {
    try {
      await Workmanager().registerPeriodicTask(
        kDailyTaskSyncTask,
        kDailyTaskSyncTask,
        tag: kDailyTaskSyncTag,
        frequency: const Duration(hours: 24),
        // يبدأ بعد منتصف الليل بدقيقتين
        initialDelay: _timeUntilMidnight(),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
      debugPrint('[TaskSyncService] Daily sync registered');
    } catch (e) {
      debugPrint('[TaskSyncService] registerDailySync error (non-fatal): $e');
      // لا نُعيد الـ exception — التطبيق يعمل بدون background sync
    }
  }

  /// إلغاء تسجيل مهمة الـ background sync (عند تسجيل الخروج)
  static Future<void> cancelDailySync() async {
    await Workmanager().cancelByTag(kDailyTaskSyncTag);
    debugPrint('[TaskSyncService] Daily sync cancelled');
  }
  static Future<void> runBackgroundSync() async {
    try {
      // نقرأ userId المحفوظ — يُكتب في onLogin بعد المصادقة
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getString('bg_sync_user_id') ?? '';

      if (userId.isEmpty) {
        debugPrint('[TaskSyncService.bg] No saved userId — skipping');
        return;
      }

      // نجلب timeSlots المخصصة للمستخدم من SharedPreferences
      final timeSlots = await ScheduleTimeSettings.instance.load(userId);
      debugPrint(
        '[TaskSyncService.bg] userId=$userId, slots=${timeSlots.length}',
      );

      // المزامنة الكاملة تحتاج Firebase + ScheduleController — خارج نطاق
      // callbackDispatcher المحدود. هذا placeholder للمرحلة القادمة.
      // في الوقت الحالي: نُسجّل أن الـ sync طُلب ونتركه للـ foreground sync
      // التالي عند فتح التطبيق (TaskController.init يتحقق من lastSyncDate).
      await prefs.setString('bg_sync_requested_at', DateTime.now().toIso8601String());
      debugPrint('[TaskSyncService.bg] Sync request recorded for foreground pickup');
    } catch (e) {
      debugPrint('[TaskSyncService.bg] runBackgroundSync error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Core Sync Logic
  // ══════════════════════════════════════════════════════════════════════════

  /// المزامنة اليومية الرئيسية — يُستدعى عند:
  /// 1. تسجيل الدخول (من TaskController.init())
  /// 2. منتصف الليل من الـ background worker في main.dart
  /// 3. يدوياً من TaskController.forceDailySync()
  ///
  /// [forceRefresh] يتجاوز فحص lastSyncDate — يُستخدم عند:
  /// - sync يدوي صريح من المستخدم
  /// - تغيير الجدول الدراسي في نفس اليوم
  /// - استيعاب طلب bg_sync_requested_at من background worker
  Future<SyncResult> syncDailyTasks({bool forceRefresh = false}) async {
    final userId = _getUserId();
    if (userId.isEmpty) {
      return SyncResult(success: false, message: 'لا يوجد مستخدم مسجل');
    }

    try {
      debugPrint('[TaskSyncService] Starting daily sync (forceRefresh=$forceRefresh)...');

      if (!_scheduleController.isInitialized) {
        debugPrint('[TaskSyncService] ScheduleController not initialized yet — skipping');
        return SyncResult(success: false, message: 'الجدول لم يُحمَّل بعد');
      }

      final lastSync = await _taskRepo.getLastSyncDate();
      final now      = DateTime.now();
      final today    = DateTime(now.year, now.month, now.day);

      if (!forceRefresh && lastSync != null) {
        final lastSyncDay =
            DateTime(lastSync.year, lastSync.month, lastSync.day);
        if (lastSyncDay == today) {
          debugPrint('[TaskSyncService] Already synced today, skipping');
          return SyncResult(
            success: true,
            message: 'تم المزامنة مسبقاً اليوم',
            skipped: true,
          );
        }
      }

      final timeSlots = await ScheduleTimeSettings.instance.load(userId);

      final todayTasks = await _buildTodayTasks(userId, today, timeSlots);
      await _taskRepo.syncDailyTasks(todayTasks);
      await _taskRepo.saveLastSyncDate(now);

      debugPrint('[TaskSyncService] Sync complete: ${todayTasks.length} tasks');
      return SyncResult(
        success: true,
        message: 'تم تحديث ${todayTasks.length} مهمة',
        tasksCount: todayTasks.length,
      );
    } catch (e) {
      debugPrint('[TaskSyncService] Sync error: $e');
      return SyncResult(success: false, message: 'فشل المزامنة: $e');
    }
  }

  /// مزامنة مهام الكورسات النشطة.
  Future<void> syncCourseTasks() async {
    final userId = _getUserId();
    if (userId.isEmpty) return;

    if (_learningState.allFields.isEmpty) {
      debugPrint('[TaskSyncService] allFields not loaded yet — skipping course sync');
      return;
    }

    try {
      final activeCourses = _learningState.getActiveCourses();

      // [FIX] نقرأ المهام الموجودة في Firestore أولاً قبل البناء —
      // كانت syncCourseTasks تُنشئ مهاماً جديدة بـ fromSkillCourse دون مراعاة
      // أي تحديثات يدوية طرأت على المهمة في Firestore منذ آخر sync.
      // الآن: progress يأتي من GlobalLearningState (مصدر الحقيقة)،
      // لكن نحتفظ بباقي حقول المهمة الموجودة كـ createdAt.
      final existingTasksMap = <String, TaskModel>{
        for (final t in await _taskRepo.getCourseTasks()) t.id: t,
      };

      final tasks = <TaskModel>[];

      for (final courseProgress in activeCourses) {
        final courseData = _learningState.getCourseData(
          courseProgress.fieldId,
          courseProgress.skillId,
          courseProgress.courseId,
        );
        if (courseData == null) continue;

        final taskId =
            'course_${courseProgress.fieldId}_${courseProgress.skillId}_${courseProgress.courseId}';

        // progress يأتي دائماً من GlobalLearningState — هو مصدر الحقيقة
        final progress = courseProgress.totalLessons > 0
            ? (courseProgress.completedLessons.length /
                    courseProgress.totalLessons *
                    100)
                .roundToDouble()
            : 0.0;

        final existing = existingTasksMap[taskId];

        if (existing != null) {
          // [FIX] المهمة موجودة — نُحدِّث progress فقط ونحتفظ بباقي الحقول
          tasks.add(existing.copyWith(
            currentLesson: courseProgress.currentLessonIndex + 1,
            totalLessons: courseProgress.totalLessons,
            progressPercentage: progress,
            updatedAt: DateTime.now(),
          ));
        } else {
          // مهمة جديدة — ننشئها من الصفر
          tasks.add(TaskModel.fromSkillCourse(
            id: taskId,
            userId: userId,
            courseId: courseProgress.courseId,
            skillId: courseProgress.skillId,
            fieldId: courseProgress.fieldId,
            courseTitle: courseData.title,
            currentLesson: courseProgress.currentLessonIndex + 1,
            totalLessons: courseProgress.totalLessons,
            progressPercentage: progress,
          ));
        }
      }

      await _taskRepo.syncCourseTasks(tasks);
      debugPrint('[TaskSyncService] Course tasks synced: ${tasks.length}');
    } catch (e) {
      debugPrint('[TaskSyncService] syncCourseTasks error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Private Helpers
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<TaskModel>> _buildTodayTasks(
    String userId,
    DateTime today,
    List<ScheduleTimeSlot> timeSlots,
  ) async {
    final tasks   = <TaskModel>[];
    final schedule = _scheduleController.schedule;
    final todayCol = _todayColumnIndex(today);

    // ─ 1. محاضرات اليوم ────────────────────────────────────────────────────
    for (final entry in schedule) {
      if (entry.col != todayCol) continue;

      if (entry.row < 0 || entry.row >= timeSlots.length) {
        debugPrint(
          '[TaskSyncService] row ${entry.row} out of range '
          '(timeSlots.length=${timeSlots.length}) — skipping',
        );
        continue;
      }

      final slot   = timeSlots[entry.row];
      final taskId =
          'lec_${entry.id}_${today.toIso8601String().substring(0, 10)}';

      tasks.add(TaskModel.fromLecture(
        id: taskId,
        userId: userId,
        subjectId: entry.id,
        subjectName: entry.subjectName,
        sessionType: entry.sessionType,
        timeSlot: slot.label,
        durationMinutes: slot.durationMinutes,
        scheduledDate: today,
      ));
    }

    // ─ 2. جلسات المذاكرة ───────────────────────────────────────────────────
    // جلسات المذاكرة تحمل بالفعل timeSlot و durationMinutes الصحيحَين
    // لأن StudyPlanService يستخدم ScheduleTimeSettings في توليدها.
    // المدة تتفاوت حسب الأولوية — قد تكون 60 أو 210 دقيقة أو أي قيمة أخرى.
    final todaySessions = _scheduleController.todaySessions;

    for (final session in todaySessions) {
      final taskId = 'study_${session.id}';

      if (session.status == SessionStatus.skipped) {
        tasks.add(TaskModel.fromStudySession(
          id: taskId,
          userId: userId,
          studySessionId: session.id,
          subjectName: session.subjectName,
          timeSlot: session.timeSlot,
          durationMinutes: session.durationMinutes,
          scheduledDate: session.scheduledDate,
          priorityScore: session.priorityScore,
          sessionTypeName: session.sessionType.name,
        ).copyWith(status: TaskStatus.missed));
        continue;
      }

      tasks.add(TaskModel.fromStudySession(
        id: taskId,
        userId: userId,
        studySessionId: session.id,
        subjectName: session.subjectName,
        timeSlot: session.timeSlot,
        durationMinutes: session.durationMinutes,
        scheduledDate: session.scheduledDate,
        priorityScore: session.priorityScore,
        sessionTypeName: session.sessionType.name,
      ));
    }

    // ترتيب المهام حسب وقت البدء
    tasks.sort((a, b) {
      final aMin = _slotStartMin(a.timeSlot ?? '0-0');
      final bMin = _slotStartMin(b.timeSlot ?? '0-0');
      return aMin.compareTo(bMin);
    });

    return tasks;
  }

  /// اليوم الحالي → index العمود في الجدول (0=السبت ... 6=الجمعة)
  int _todayColumnIndex(DateTime date) {
    // DateTime.weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    // الجدول:            السبت=0, الأحد=1, الاثنين=2, ... الجمعة=6
    const weekdayToCol = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
    return weekdayToCol[date.weekday] ?? 0;
  }

  int _slotStartMin(String slot) {
    final parsed = TaskModel.parseTimeSlot(slot);
    return parsed?.startMin ?? 0;
  }

  /// حساب الوقت المتبقي حتى منتصف الليل + دقيقتان كـ buffer
  static Duration _timeUntilMidnight() {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now) + const Duration(minutes: 2);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SyncResult
// ══════════════════════════════════════════════════════════════════════════════

class SyncResult {
  final bool success;
  final String message;
  final int tasksCount;
  final bool skipped;

  const SyncResult({
    required this.success,
    required this.message,
    this.tasksCount = 0,
    this.skipped = false,
  });
}
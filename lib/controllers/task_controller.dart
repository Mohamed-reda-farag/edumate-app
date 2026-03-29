import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_session_model.dart';
import '../models/task_model.dart';
import '../models/attendance_record_model.dart';
import '../repositories/task_repository.dart';
import '../services/task_sync_service.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/notification_controller.dart';
import 'global_learning_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TaskController
// ══════════════════════════════════════════════════════════════════════════════

class TaskController extends ChangeNotifier {
  TaskController({
    required TaskRepository taskRepository,
    required TaskSyncService syncService,
    required AttendanceController attendanceController,
    required GlobalLearningState learningState,
    required String Function() getUserId,
    // [NOTIF] إضافة NotificationController — لا يؤثر على أي منطق قائم
    required NotificationController notificationController,
  })  : _taskRepo = taskRepository,
        _syncService = syncService,
        _attendanceController = attendanceController,
        _learningState = learningState,
        _getUserId = getUserId,
        _notifController = notificationController;

  final TaskRepository _taskRepo;
  final TaskSyncService _syncService;
  final AttendanceController _attendanceController;
  final GlobalLearningState _learningState;
  final String Function() _getUserId;
  // [NOTIF]
  final NotificationController _notifController;

  // ── State ─────────────────────────────────────────────────────────────────

  List<TaskModel> _dailyTasks = [];
  List<TaskModel> _courseTasks = [];
  List<TaskModel> _customTasks = [];

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  bool _initialized = false;

  StreamSubscription<List<TaskModel>>? _dailySub;
  StreamSubscription<List<TaskModel>>? _courseSub;
  StreamSubscription<List<TaskModel>>? _customSub;

  // Timer لتحديث حالات المهام الزمنية تلقائياً كل دقيقة
  Timer? _statusRefreshTimer;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<TaskModel> get dailyTasks  => List.unmodifiable(_dailyTasks);
  List<TaskModel> get courseTasks => List.unmodifiable(_courseTasks);
  List<TaskModel> get customTasks => List.unmodifiable(_customTasks);
  bool get isLoading  => _isLoading;
  bool get isSyncing  => _isSyncing;
  String? get error   => _error;

  /// عدد المهام النشطة لليوم (للـ Badge في الـ BottomNavigationBar).
  /// يعدّ upcoming و ongoing فقط — المهام الفائتة لا تُحسب كـ pending.
  int get pendingDailyCount => _dailyTasks
      .where((t) =>
          t.status == TaskStatus.upcoming || t.status == TaskStatus.ongoing)
      .length;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    // [FIX] _initialized يُعيَّن true بعد نجاح التهيئة فقط —
    // كان يُعيَّن قبل الـ try مما يمنع إعادة استدعاء init() عند الفشل.
    // الآن إذا رُمي استثناء في Future.wait، يبقى _initialized = false
    // ويمكن استدعاء init() مجدداً.

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // تحميل أولي متوازٍ من Firestore
      final results = await Future.wait([
        _taskRepo.getDailyTasks(),
        _taskRepo.getCourseTasks(),
        _taskRepo.getCustomTasks(),
      ]);

      _dailyTasks  = _sortByTime(results[0]);
      _courseTasks = results[1];
      _customTasks = results[2];

      // [FIX] نُعيِّن _initialized = true هنا فقط بعد نجاح التحميل
      _initialized = true;
    } catch (e) {
      _error = e.toString();
      // _initialized يبقى false — يمكن إعادة استدعاء init()
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // إذا فشل التحميل، لا نُكمل بقية init()
    if (!_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bgRequest = prefs.getString('bg_sync_requested_at');
      if (bgRequest != null) {
        debugPrint('[TaskController] bg_sync_requested_at found — forcing sync');
        await prefs.remove('bg_sync_requested_at');
        await _syncService.syncDailyTasks(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('[TaskController] bg_sync check error: $e');
    }

    await _runDailySync();
    await _syncService.syncCourseTasks();

    // فتح الـ Streams بعد اكتمال الـ Sync
    _dailySub = _taskRepo.watchDailyTasks().listen(
      (tasks) {
        _dailyTasks = _sortByTime(tasks);
        notifyListeners();

        // [NOTIF] جدولة إشعارات مهام اليوم بعد وصول القائمة المحدَّثة —
        // هنا _dailyTasks تحتوي البيانات الجديدة من الـ sync فعلاً.
        // fire-and-forget: لا تُوقف تحديث الـ UI إذا فشلت الإشعارات
        _notifController.scheduleTodayTasks(
          dailyTasks: _dailyTasks,
          courseTasks: _courseTasks,
        ).ignore();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    _courseSub = _taskRepo.watchCourseTasks().listen(
      (tasks) {
        _courseTasks = tasks;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    _customSub = _taskRepo.watchCustomTasks().listen(
      (tasks) {
        _customTasks = tasks;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    // تشغيل Timer لتحديث الحالات الزمنية كل دقيقة
    _startStatusRefreshTimer();
  }

  Future<void> reset() async {
    _initialized = false;
    _stopStatusRefreshTimer();
    await _cancelSubscriptions();

    _dailyTasks  = [];
    _courseTasks = [];
    _customTasks = [];
    _isLoading   = false;
    _isSyncing   = false;
    _error       = null;

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Status Refresh Timer
  // ══════════════════════════════════════════════════════════════════════════

  void _startStatusRefreshTimer() {
    _stopStatusRefreshTimer();
    _statusRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => refreshStatuses(),
    );
  }

  void _stopStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = null;
  }

  /// يُحدِّث حالات المهام الزمنية بناءً على الوقت الحالي.
  /// يُستدعى تلقائياً كل دقيقة، وعند الحاجة يدوياً.
  ///
  /// يتخطى المهام المكتملة (completed) ولا يمسّ Firestore —
  /// التحديث محلي فقط لتحسين سرعة الاستجابة في الـ UI.
  void refreshStatuses() {
    bool changed = false;

    final updated = _dailyTasks.map((task) {
      if (task.status == TaskStatus.completed)                    return task;
      if (task.scheduledDate == null || task.timeSlot == null)    return task;

      final newStatus = TaskModel.computeCurrentStatus(
        task.scheduledDate!,
        task.timeSlot!,
      );

      if (newStatus != task.status) {
        changed = true;
        return task.copyWith(status: newStatus, updatedAt: DateTime.now());
      }
      return task;
    }).toList();

    if (changed) {
      _dailyTasks = updated;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Daily Tasks Actions
  // ══════════════════════════════════════════════════════════════════════════

  /// تسجيل حضور محاضرة
  Future<void> recordLectureAttendance({
    required String taskId,
    required LectureAttendanceStatus attendanceStatus,
    required int understandingRating,
    int lateMinutes = 0,
    String? notes,
  }) async {
    final task = _dailyTasks.cast<TaskModel?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    if (task.status == TaskStatus.upcoming) {
      _error = 'لا يمكن تسجيل الحضور قبل موعد المحاضرة';
      notifyListeners();
      return;
    }

    // المهام المكتملة مسبقاً لا تُعاد
    if (task.status == TaskStatus.completed) return;

    _setLoading(true);
    try {
      final existingRecords =
          _attendanceController.getSubjectRecords(task.subjectId ?? '');
      // نحسب فقط المحاضرات (lec) — السيكشن والمعمل لا تُحسب في الترقيم
      final lectureNumber = existingRecords
              .where((r) => r.sessionType == 'lec')
              .length + 1;

      final recordId =
          '${task.subjectId}_${DateTime.now().millisecondsSinceEpoch}';

      final AttendanceStatus mappedStatus;
      switch (attendanceStatus) {
        case LectureAttendanceStatus.attended:
          mappedStatus = AttendanceStatus.attended;
          break;
        case LectureAttendanceStatus.absent:
          mappedStatus = AttendanceStatus.absent;
          break;
        case LectureAttendanceStatus.late:
          mappedStatus = AttendanceStatus.late;
          break;
      }

      await _attendanceController.addAttendanceRecord(
        AttendanceRecord(
          id: recordId,
          subjectId: task.subjectId ?? '',
          subjectName: task.subjectName ?? task.title,
          date: task.scheduledDate ?? DateTime.now(),
          status: mappedStatus,
          lateMinutes: lateMinutes,
          understandingRating:
              mappedStatus != AttendanceStatus.absent ? understandingRating : null,
          lectureNumber: lectureNumber,
          notes: notes,
          createdAt: DateTime.now(),
          sessionType: task.sessionType ?? 'lec',
          lectureDurationMinutes: task.durationMinutes,
        ),
      );

      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        attendanceStatus: attendanceStatus,
        updatedAt: DateTime.now(),
      );
      await _taskRepo.updateDailyTask(updatedTask);

      // [FIX] تحديث _dailyTasks محلياً فوراً بدون انتظار الـ Stream —
      // كان recordLectureAttendance لا يُحدِّث القائمة محلياً بعكس
      // updateStudySessionStatus، مما يُسبب تأخيراً مرئياً في الـ UI.
      _dailyTasks = _dailyTasks
          .map((t) => t.id == taskId ? updatedTask : t)
          .toList();
      notifyListeners();

      // [NOTIF] إلغاء إشعار "هل حضرت؟" — المستخدم سجّل الحضور فعلاً
      // fire-and-forget: لا نحتاج await لأنه غير حرج
      _notifController.onLectureAttended(taskId).ignore();

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TaskController] recordLectureAttendance error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث حالة جلسة مذاكرة (بدأت / أكملت)
  /// [understandingRating] و [notes] يُمرَّران فقط عند newStatus == completed
  Future<void> updateStudySessionStatus({
    required String taskId,
    required StudySessionTaskStatus newStatus,
    int? understandingRating,
    String? notes,
  }) async {
    final task = _dailyTasks.cast<TaskModel?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    if (newStatus == StudySessionTaskStatus.started) {
      // 1. الحالة ongoing (Timer حدّثها بالفعل) — الحالة الطبيعية
      // 2. الحالة upcoming لكن وقت الجلسة حلّ فعلاً (Timer لم ينقضِ بعد)
      final isTimeReached = task.scheduledDate != null && task.timeSlot != null
          ? TaskModel.computeCurrentStatus(task.scheduledDate!, task.timeSlot!) !=
              TaskStatus.upcoming
          : false;
    
      if (task.status != TaskStatus.ongoing && !isTimeReached) {
        _error = 'لا يمكن بدء الجلسة قبل حلول موعدها';
        notifyListeners();
        return;
      }
    }

    if (newStatus == StudySessionTaskStatus.completed &&
        task.status == TaskStatus.upcoming) {
      _error = 'لا يمكن إكمال الجلسة قبل حلول موعدها';
      notifyListeners();
      return;
    }

    // المهام المكتملة مسبقاً لا تُعاد
    if (task.status == TaskStatus.completed) return;

    _setLoading(true);
    try {
      final taskStatus = switch (newStatus) {
        StudySessionTaskStatus.completed  => TaskStatus.completed,
        StudySessionTaskStatus.started    => TaskStatus.ongoing,
        StudySessionTaskStatus.notStarted => TaskStatus.upcoming,
      };

      final updatedTask = task.copyWith(
        status: taskStatus,
        studySessionStatus: newStatus,
        updatedAt: DateTime.now(),
      );
      await _taskRepo.updateDailyTask(updatedTask);

      // تحديث _dailyTasks محلياً فوراً بدون انتظار الـ Stream
      _dailyTasks = _dailyTasks
          .map((t) => t.id == taskId ? updatedTask : t)
          .toList();
      notifyListeners();

      if (newStatus == StudySessionTaskStatus.completed &&
          task.studySessionId != null) {
        await _attendanceController.updateSessionStatus(
          task.studySessionId!,
          SessionStatus.completed,
          completionRate: 1.0,
          understandingRating: understandingRating,
          notes: notes,
        );

        // [NOTIF] إلغاء إشعار "لم تكمل الجلسة بعد"
        // fire-and-forget: غير حرج
        _notifController
            .onStudySessionCompleted(task.studySessionId!)
            .ignore();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TaskController] updateStudySessionStatus error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Skill Course Tasks Actions
  // ══════════════════════════════════════════════════════════════════════════

  /// تحديد الدرس الحالي كمكتمل وتحديث مهمة الكورس.
  Future<void> markCurrentLesson({required String taskId}) async {
    final task = _courseTasks.cast<TaskModel?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;
    if (task.fieldId == null || task.skillId == null || task.courseId == null) {
      _error = 'بيانات الكورس غير مكتملة';
      debugPrint('[TaskController] markCurrentLesson: missing fieldId/skillId/courseId for task $taskId');
      notifyListeners();
      return;
    }

    // نقرأ الـ progress الحالي قبل أي تغيير لنعرف الدرس الصحيح
    final currentProgress = _learningState.getCourseProgress(
      task.fieldId!,
      task.skillId!,
      task.courseId!,
    );
    if (currentProgress == null) return;

    final lessonIndex = currentProgress.currentLessonIndex;
    
    // ── فحص حدود التعلم ────────────────────────────────────────────────────
    final checkResult = _learningState.checkLessonAllowed(
      task.fieldId!,
      task.skillId!,
    );

    if (checkResult == LessonCheckResult.dailyBlocked ||
        checkResult == LessonCheckResult.weeklyBlocked) {
      _error = checkResult == LessonCheckResult.dailyBlocked
          ? 'أكملت حصتك اليومية — عُد غداً 💪'
          : 'أكملت أيام تعلمك هذا الأسبوع 🗓️';
      notifyListeners();
      return;
    }

    if (checkResult == LessonCheckResult.dailyWarning) {
      _learningState.markDailyWarningSent(task.fieldId!, task.skillId!);
    }
    if (checkResult == LessonCheckResult.weeklyWarning) {
      _learningState.markWeeklyWarningSent(task.fieldId!, task.skillId!);
    }

    _setLoading(true);
    try {
      await _learningState.markLessonAsCompleted(
        fieldId: task.fieldId!,
        skillId: task.skillId!,
        courseId: task.courseId!,
        lessonIndex: lessonIndex,
      );

      final updatedProgress = _learningState.getCourseProgress(
        task.fieldId!,
        task.skillId!,
        task.courseId!,
      );

      if (updatedProgress != null) {
        if (updatedProgress.isCompleted) {
          await _taskRepo.deleteCourseTask(taskId);
          // حذف المهمة محلياً فوراً قبل وصول حدث الـ Stream
          _courseTasks = _courseTasks.where((t) => t.id != taskId).toList();
          notifyListeners();

          // [NOTIF] إلغاء إشعار خمول الكورس + تحديث عداد الدروس المكتملة
          // نحسب pending من المهام الجارية + القادمة
          final pendingCount = _courseTasks
              .where((t) =>
                  t.status == TaskStatus.upcoming ||
                  t.status == TaskStatus.ongoing)
              .length;
          _notifController.onLessonCompleted(
            courseId: task.courseId!,
            completedCount: 1,
            pendingCount: pendingCount,
          ).ignore();
        } else {
          final updatedTask = task.copyWith(
            currentLesson: updatedProgress.currentLessonIndex + 1,
            progressPercentage: updatedProgress.totalLessons > 0
                ? updatedProgress.completedLessons.length /
                    updatedProgress.totalLessons *
                    100
                : 0,
            updatedAt: DateTime.now(),
          );
          await _taskRepo.saveCourseTask(updatedTask);
          // تحديث المهمة محلياً فوراً قبل وصول حدث الـ Stream
          _courseTasks = _courseTasks
              .map((t) => t.id == taskId ? updatedTask : t)
              .toList();
          notifyListeners();

          // [NOTIF] تحديث عداد الدروس
          final pendingCount = _courseTasks
              .where((t) =>
                  t.status == TaskStatus.upcoming ||
                  t.status == TaskStatus.ongoing)
              .length;
          _notifController.onLessonCompleted(
            courseId: task.courseId!,
            completedCount: 1,
            pendingCount: pendingCount,
          ).ignore();
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TaskController] markCurrentLesson error: $e');
      try {
        final tasks = await _taskRepo.getCourseTasks();
        _courseTasks = tasks;
        notifyListeners();
      } catch (_) {
        // إذا فشل الـ rollback أيضاً — Stream سيُصحح الحالة عند الاتصال
      }
    } finally {
      _setLoading(false);
    }
  }

  /// مزامنة كاملة لمهام الكورسات — تُستدعى عند:
  /// - تغيير المجال الأساسي أو الثانوي
  /// - بدء كورس جديد (يُستدعى من GlobalLearningState listener أو من الـ UI مباشرةً)
  /// - تسجيل الدخول (من init())
  ///
  /// تُحدِّث _courseTasks محلياً فوراً بعد كتابة Firestore
  /// حتى لا ينتظر المستخدم حدث Stream القادم من Firestore.
  Future<void> syncAllCourseTasks() async {
    try {
      await _syncService.syncCourseTasks();
      // اقرأ النتيجة من Firestore فوراً لتحديث الـ UI بدون انتظار Stream
      final tasks = await _taskRepo.getCourseTasks();
      _courseTasks = tasks;
      notifyListeners();
    } catch (e) {
      debugPrint('[TaskController] syncAllCourseTasks error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Custom Tasks Actions
  // ══════════════════════════════════════════════════════════════════════════

  /// إضافة مهمة مخصصة جديدة.
  Future<void> addCustomTask({
    required String title,
    String? description,
    DateTime? scheduledDate,
    String? timeSlot,
    int? durationMinutes,
    DateTime? dueDate,
    bool isRecurring = false,
    RecurrenceType? recurrenceType,
    int reminderMinutesBefore = 60,
    bool hasReminder = false,
  }) async {
    final userId = _getUserId();
    if (userId.isEmpty) return;

    _setLoading(true);
    try {
      final now    = DateTime.now();
      final userSuffix = userId.length >= 4 ? userId.substring(0, 4) : userId;
      final taskId = 'custom_${now.millisecondsSinceEpoch}_$userSuffix';

      final task = TaskModel(
        id: taskId,
        userId: userId,
        type: TaskType.custom,
        status: TaskStatus.upcoming,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        durationMinutes: durationMinutes,
        isRecurring: isRecurring,
        recurrenceType: recurrenceType,
        reminderMinutesBefore: reminderMinutesBefore,
        hasReminder: hasReminder,
        dueDate: dueDate,
        createdAt: now,
        updatedAt: now,
      );

      await _taskRepo.addCustomTask(task);

      // [NOTIF] جدولة تذكير المهمة المخصصة إذا طلب المستخدم تذكيراً
      // fire-and-forget: غير حرج لاكتمال العملية الرئيسية
      if (hasReminder) {
        _notifController.scheduleCustomTask(task).ignore();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TaskController] addCustomTask error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث مهمة مخصصة
  Future<void> updateCustomTask(TaskModel task) async {
    _setLoading(true);
    try {
      final updated = task.copyWith(updatedAt: DateTime.now());
      await _taskRepo.updateCustomTask(updated);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TaskController] updateCustomTask error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// إكمال مهمة مخصصة
  Future<void> completeCustomTask(String taskId) async {
    _setLoading(true);
    try {
      await _taskRepo.updateCustomTaskStatus(taskId, TaskStatus.completed);

      // [NOTIF] إلغاء تذكير المهمة المخصصة — اكتملت
      _notifController.onCustomTaskCompleted(taskId).ignore();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// إلغاء إكمال مهمة مخصصة
  Future<void> uncompleteCustomTask(String taskId) async {
    _setLoading(true);
    try {
      await _taskRepo.updateCustomTaskStatus(taskId, TaskStatus.upcoming);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// حذف مهمة مخصصة
  Future<void> deleteCustomTask(String taskId) async {
    _setLoading(true);
    try {
      // [FIX] نحفظ مرجع المهمة قبل الحذف —
      // كان البحث يتم بعد deleteCustomTask فإذا وصل حدث الـ Stream
      // قبله وجدنا task == null وأرسلنا isRecurring: false خطأً.
      final task = _customTasks.cast<TaskModel?>().firstWhere(
            (t) => t?.id == taskId,
            orElse: () => null,
          );

      await _taskRepo.deleteCustomTask(taskId);

      _notifController
          .onCustomTaskDeleted(
            taskId,
            isRecurring: task?.isRecurring ?? false,
          )
          .ignore();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Manual Sync
  // ══════════════════════════════════════════════════════════════════════════

  Future<SyncResult> forceDailySync() async {
    _isSyncing = true;
    notifyListeners();
    try {
      final result = await _syncService.syncDailyTasks(forceRefresh: true);
      return result;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Dispose
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _stopStatusRefreshTimer();
    _dailySub?.cancel();
    _courseSub?.cancel();
    _customSub?.cancel();
    super.dispose();
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _runDailySync({bool forceRefresh = false}) async {
    _isSyncing = true;
    notifyListeners();
    try {
      await _syncService.syncDailyTasks(forceRefresh: forceRefresh);
      // [NOTIF] scheduleTodayTasks يُستدعى من داخل _dailySub listener —
      // لأن الـ Stream يُحدِّث _dailyTasks بعد الـ sync ببرهة،
      // وهنا _dailyTasks لا تزال القائمة القديمة قبل وصول الـ snapshot الجديد.
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _dailySub?.cancel();
    await _courseSub?.cancel();
    await _customSub?.cancel();
    _dailySub  = null;
    _courseSub = null;
    _customSub = null;
  }

  List<TaskModel> _sortByTime(List<TaskModel> tasks) {
    final sorted = List<TaskModel>.from(tasks);
    sorted.sort((a, b) {
      final aMin = TaskModel.parseTimeSlot(a.timeSlot ?? '')?.startMin ?? 9999;
      final bMin = TaskModel.parseTimeSlot(b.timeSlot ?? '')?.startMin ?? 9999;
      return aMin.compareTo(bMin);
    });
    return sorted;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
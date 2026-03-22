import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_settings_model.dart';
import '../models/notification_history_model.dart';
import '../models/task_model.dart';
import '../models/gamification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_scheduler_service.dart';
import '../services/notification_background_bridge.dart';
import '../services/fcm_service.dart';
import '../controllers/global_learning_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationController
// ══════════════════════════════════════════════════════════════════════════════

class NotificationController extends ChangeNotifier {
  NotificationController({
    required NotificationRepository notificationRepository,
    required GlobalLearningState learningState,
    required String Function() getUserId,
  })  : _notifRepo = notificationRepository,
        _learningState = learningState,
        _getUserId = getUserId;

  final NotificationRepository _notifRepo;
  final GlobalLearningState _learningState;
  final String Function() _getUserId;

  // ── State ─────────────────────────────────────────────────────────────────

  NotificationSettings _settings = NotificationSettings.defaults();
  List<NotificationHistoryItem> _history = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _initialized = false;
  bool _permissionGranted = false;

  // حفظ آخر streak معروف لاستخدامه في _updateBridge
  int _lastKnownStreak = 0;

  StreamSubscription<NotificationSettings>? _settingsSub;

  // ── Getters ───────────────────────────────────────────────────────────────

  NotificationSettings get settings => _settings;
  List<NotificationHistoryItem> get history => List.unmodifiable(_history);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get permissionGranted => _permissionGranted;
  bool get isEnabled => _settings.isEnabled;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. تهيئة NotificationService
      await NotificationService.instance.initialize();

      // 2. طلب إذن الإشعارات
      _permissionGranted =
          await NotificationService.instance.requestPermission();

      // 3. جلب الإعدادات من Firestore
      _settings = await _notifRepo.getSettings();

      // 4. جلب سجل الإشعارات من Hive
      _history = await _notifRepo.getHistory();
      // حساب unreadCount محلياً بدل استدعاء Hive مرة ثانية
      _unreadCount = _history.where((h) => !h.wasRead).length;

      // 5. الاستماع للتغييرات من Firestore (مزامنة عبر الأجهزة)
      _settingsSub = _notifRepo.watchSettings().listen(
        (incoming) {
          if (incoming != _settings) {
            final oldSettings = _settings;
            _settings = incoming;
            notifyListeners();
            if (_shouldRescheduleOnSettingsChange(oldSettings, incoming)) {
              _rescheduleAfterSettingsChange(incoming);
            }
          }
        },
        onError: (e) {
          debugPrint('[NotifController] watchSettings error: $e');
        },
      );

      // 6. ربط callback الـ tap
      NotificationService.instance.onNotificationTapped = _handleTap;

      // [FIX #4] ربط callback الـ FCM history بعد اكتمال التهيئة
      // يضمن أن رسائل FCM الواردة في الـ foreground تُسجَّل في الـ history
      FcmService.instance.onMessageReceivedForHistory = ({
        required String title,
        required String body,
        required NotificationCategory category,
        String? payload,
      }) async {
        await _addToHistory(
          title: title,
          body: body,
          category: category,
          payload: payload,
        );
      };

      // [FIX #13 + #17] تحديث الـ bridge عند أول تحميل.
      // يحل مشكلتين:
      //   أ) bridge يُحفظ بـ activeCourseIds فارغة في main.dart لأن
      //      loadUserProfile() تعود قبل وصول أول Firestore snapshot.
      //   ب) bridge لم يكن يُحدَّث عند initialize() على الإطلاق.
      // نحاول التحديث هنا — إذا لم يُحمَّل الـ profile بعد، _updateBridge
      // ستُرجع مبكراً بأمان وستنتظر أول استدعاء لـ updateSettings أو updateStreak.
      await _updateBridge(_settings, debounce: false);

      // _initialized = true فقط عند النجاح الكامل
      _initialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _initialized = false;
      debugPrint('[NotifController] initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _initialized = false;
    await _settingsSub?.cancel();
    _settingsSub = null;

    // [FIX #4] مسح الـ callback عند reset
    FcmService.instance.onMessageReceivedForHistory = null;

    _settings = NotificationSettings.defaults();
    _history = [];
    _unreadCount = 0;
    _isLoading = false;
    _isSaving = false;
    _error = null;
    _permissionGranted = false;
    _lastKnownStreak = 0;

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Settings Actions
  // ══════════════════════════════════════════════════════════════════════════

  /// تحديث الإعدادات وإعادة الجدولة عند الحاجة
  Future<void> updateSettings(NotificationSettings newSettings) async {
    final oldSettings = _settings;
    _settings = newSettings; // Optimistic update
    notifyListeners();

    _isSaving = true;
    notifyListeners();

    try {
      await _notifRepo.saveSettings(newSettings);
      await _updateBridge(newSettings, debounce: true);

      if (_shouldRescheduleOnSettingsChange(oldSettings, newSettings)) {
        _rescheduleAfterSettingsChange(newSettings);
      }

      _error = null;
    } catch (e) {
      // Rollback عند الفشل
      _settings = oldSettings;
      _error = e.toString();
      debugPrint('[NotifController] updateSettings error: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// تفعيل/إيقاف كل الإشعارات دفعةً واحدة.
  ///
  /// [FIX #2] الترتيب الصحيح: cancelAll() يُستدعى أولاً عند الإيقاف
  /// قبل updateSettings() لمنع race condition حيث تُطلق _rescheduleAfterSettingsChange
  /// إشعارات جديدة في الـ background ثم يأتي cancelAll() ويمسحها،
  /// لكن reschedule قد تنتهي بعده وتُعيد الجدولة مجدداً.
  Future<void> toggleEnabled(bool value) async {
    if (!value) {
      // [FIX #2] أوقف الجدولة فوراً قبل updateSettings
      // هذا يضمن عدم وصول إشعارات للمستخدم بعد الإيقاف
      await NotificationService.instance.cancelAll();
    }
    await updateSettings(_settings.copyWith(isEnabled: value));
  }

  /// تحديث حقل واحد في الإعدادات
  Future<void> updateField(
      NotificationSettings Function(NotificationSettings) updater) async {
    await updateSettings(updater(_settings));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Streak Update — يُستدعى من GamificationController
  // ══════════════════════════════════════════════════════════════════════════

  /// تحديث الـ streak الحقيقي في الـ bridge
  Future<void> updateStreak(int streak) async {
    if (_lastKnownStreak == streak) return;
    _lastKnownStreak = streak;
    await _updateBridge(_settings, debounce: false);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Scheduling — يُستدعى من TaskController وScheduleController
  // ══════════════════════════════════════════════════════════════════════════

  /// جدولة إشعارات مهام اليوم (يُستدعى بعد syncDailyTasks)
  Future<void> scheduleTodayTasks({
    required List<TaskModel> dailyTasks,
    required List<TaskModel> courseTasks,
  }) async {
    if (!_settings.isEnabled || !_settings.taskReminders) return;

    try {
      await NotificationSchedulerService.scheduleTodayTaskNotifications(
        dailyTasks: dailyTasks,
        courseTasks: courseTasks,
        settings: _settings,
      );

      final lectureCount =
          dailyTasks.where((t) => t.type == TaskType.lecture).length;
      final studyCount =
          dailyTasks.where((t) => t.type == TaskType.studySession).length;
      final courseCount = courseTasks.length;

      await NotificationBackgroundBridge.saveTodayTasksSummary(
        lectureCount: lectureCount,
        studySessionCount: studyCount,
        courseTaskCount: courseCount,
      );
    } catch (e) {
      debugPrint('[NotifController] scheduleTodayTasks error: $e');
    }
  }

  /// جدولة إشعار مهمة مخصصة جديدة
  Future<void> scheduleCustomTask(TaskModel task) async {
    if (!_settings.isEnabled || !_settings.taskReminders) return;
    try {
      await NotificationSchedulerService.scheduleCustomTaskNotification(
        task: task,
        settings: _settings,
      );
    } catch (e) {
      debugPrint('[NotifController] scheduleCustomTask error: $e');
    }
  }

  /// إعادة جدولة كاملة (عند تغيير الجدول أو الإعدادات)
  Future<void> rescheduleAll({
    required List<TaskModel> dailyTasks,
    required List<TaskModel> courseTasks,
    int? currentStreak,
  }) async {
    if (!_settings.isEnabled) return;

    if (currentStreak != null) {
      _lastKnownStreak = currentStreak;
    }

    try {
      final List<String> activeCourseIds;
      final Map<String, DateTime> courseLastAccess;

      if (_learningState.hasUserProfile) {
        final activeCourses = _learningState.getActiveCourses();
        activeCourseIds = activeCourses.map((c) => c.courseId).toList();
        courseLastAccess = {
          for (final c in activeCourses) c.courseId: c.lastAccessedAt,
        };
      } else {
        activeCourseIds = const [];
        courseLastAccess = const {};
        debugPrint(
          '[NotifController] rescheduleAll: profile not loaded yet — '
          'skipping course data',
        );
      }

      await NotificationSchedulerService.rescheduleAll(
        dailyTasks: dailyTasks,
        courseTasks: courseTasks,
        settings: _settings,
        currentStreak: _lastKnownStreak,
        activeCourseIds: activeCourseIds,
        courseLastAccess: courseLastAccess,
      );
    } catch (e) {
      debugPrint('[NotifController] rescheduleAll error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Cancel Actions — يُستدعى من TaskController
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> onLectureAttended(String taskId) async {
    try {
      await NotificationSchedulerService.cancelLectureFollowup(taskId);
    } catch (e) {
      debugPrint('[NotifController] onLectureAttended error: $e');
    }
  }

  Future<void> onStudySessionCompleted(String sessionId) async {
    try {
      await NotificationSchedulerService.cancelStudySessionFollowup(sessionId);
    } catch (e) {
      debugPrint('[NotifController] onStudySessionCompleted error: $e');
    }
  }

  Future<void> onLessonCompleted({
    required String courseId,
    required int completedCount,
    required int pendingCount,
  }) async {
    try {
      await NotificationSchedulerService.cancelCourseInactive(courseId);

      final current = await NotificationBackgroundBridge.loadCompletedCount();
      await NotificationBackgroundBridge.updateCompletedCount(
        completedLectures: current.completedLectures,
        completedStudySessions: current.completedStudySessions,
        completedLessons: current.completedLessons + completedCount,
        pendingCount: pendingCount,
      );
    } catch (e) {
      debugPrint('[NotifController] onLessonCompleted error: $e');
    }
  }

  Future<void> onCustomTaskCompleted(String taskId) async {
    try {
      await NotificationSchedulerService.cancelCustomTaskReminder(taskId);
    } catch (e) {
      debugPrint('[NotifController] onCustomTaskCompleted error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Achievement & Milestone — يُستدعى من GamificationController
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> onAchievementUnlocked(Achievement achievement) async {
    if (!_settings.isEnabled || !_settings.achievements) return;

    try {
      await NotificationSchedulerService.sendAchievementNotification(
        achievement: achievement,
        settings: _settings,
      );

      await _addToHistory(
        title: '🎉 إنجاز جديد!',
        body:
            'فتحت إنجاز "${achievement.titleAr}" — +${achievement.pointsReward} نقطة',
        category: NotificationCategory.achievements,
      );
    } catch (e) {
      debugPrint('[NotifController] onAchievementUnlocked error: $e');
    }
  }

  /// إرسال إشعار تقدم مهارة عند بلوغ 50% أو 80%
  Future<void> onSkillMilestone({
    required String skillId,
    required String skillName,
    required int percentage,
  }) async {
    try {
      await NotificationSchedulerService.sendSkillMilestoneNotification(
        skillId: skillId,
        skillName: skillName,
        percentage: percentage,
        settings: _settings,
      );

      // [FIX #6] إضافة للـ history — كان مفقوداً بينما onAchievementUnlocked
      // و onLevelUp يُضيفان. التناسق ضروري لظهور هذه الإشعارات في السجل.
      if (_settings.isEnabled && _settings.motivational) {
        await _addToHistory(
          title: '⭐ تقدم رائع!',
          body: 'أكملت $percentage% من مهارة $skillName',
          category: NotificationCategory.motivational,
        );
      }
    } catch (e) {
      debugPrint('[NotifController] onSkillMilestone error: $e');
    }
  }

  Future<void> onPendingAssessment({
    required String skillId,
    required String skillName,
  }) async {
    try {
      await NotificationSchedulerService.sendPendingAssessmentNotification(
        skillId: skillId,
        skillName: skillName,
        settings: _settings,
      );
    } catch (e) {
      debugPrint('[NotifController] onPendingAssessment error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Level Up — يُستدعى من main.dart listener على GamificationController
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> onLevelUp(int newLevel) async {
    try {
      await NotificationSchedulerService.sendLevelUpNotification(
        newLevel: newLevel,
        settings: _settings,
      );
      await _addToHistory(
        title: '🏆 ترقية مستوى!',
        body: 'وصلت إلى المستوى $newLevel',
        category: NotificationCategory.achievements,
      );
    } catch (e) {
      debugPrint('[NotifController] onLevelUp error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Exam Notifications — يُستدعى من SemesterController
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> scheduleExamReminders({
    required String examId,
    required String subjectName,
    required String examTypeLabel,
    required DateTime examDate,
  }) async {
    if (!_settings.isEnabled || !_settings.taskReminders) return;
    try {
      await NotificationSchedulerService.scheduleExamReminders(
        examId: examId,
        subjectName: subjectName,
        examTypeLabel: examTypeLabel,
        examDate: examDate,
        settings: _settings,
      );
    } catch (e) {
      debugPrint('[NotifController] scheduleExamReminders error: $e');
    }
  }

  Future<void> scheduleAllExamReminders({
    required List<({
      String examId,
      String subjectName,
      String examTypeLabel,
      DateTime examDate,
      bool completed,
    })> exams,
  }) async {
    if (!_settings.isEnabled || !_settings.taskReminders) return;
    try {
      await NotificationSchedulerService.scheduleAllExamReminders(
        exams: exams,
        settings: _settings,
      );
    } catch (e) {
      debugPrint('[NotifController] scheduleAllExamReminders error: $e');
    }
  }

  Future<void> cancelExamReminders(String examId) async {
    try {
      await NotificationSchedulerService.cancelExamReminders(examId);
    } catch (e) {
      debugPrint('[NotifController] cancelExamReminders error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Semester End — يُستدعى من SemesterController
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> onSemesterEnd({
    required String semesterLabel,
    required bool endNotified,
  }) async {
    if (!_settings.isEnabled) return;
    if (endNotified) return;

    try {
      await NotificationSchedulerService.sendSemesterEndNotification(
        semesterLabel: semesterLabel,
        settings: _settings,
      );
      await _addToHistory(
        title: '🎓 انتهى الفصل الدراسي',
        body: 'انتهى $semesterLabel — احفظ بياناتك',
        category: NotificationCategory.summaries,
      );
    } catch (e) {
      debugPrint('[NotifController] onSemesterEnd error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Summary Notifications
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> sendMorningDigest() async {
    try {
      final summary =
          await NotificationBackgroundBridge.loadTodayTasksSummary();
      await NotificationSchedulerService.sendMorningDigest(
        lectureCount: summary.lectureCount,
        studySessionCount: summary.studySessionCount,
        courseTaskCount: summary.courseTaskCount,
        settings: _settings,
      );

      await _addToHistory(
        title: '☀️ ملخص الصباح',
        body: 'لديك ${summary.totalCount} مهمة اليوم',
        category: NotificationCategory.summaries,
      );
    } catch (e) {
      debugPrint('[NotifController] sendMorningDigest error: $e');
    }
  }

  Future<void> sendEveningDigest() async {
    try {
      final completed =
          await NotificationBackgroundBridge.loadCompletedCount();
      await NotificationSchedulerService.sendEveningDigest(
        completedLectures: completed.completedLectures,
        completedStudySessions: completed.completedStudySessions,
        completedLessons: completed.completedLessons,
        pendingCount: completed.pendingCount,
        settings: _settings,
      );

      await _addToHistory(
        title: '🌙 ملخص المساء',
        body:
            'أكملت ${completed.completedLectures + completed.completedStudySessions + completed.completedLessons} مهمة',
        category: NotificationCategory.summaries,
      );
    } catch (e) {
      debugPrint('[NotifController] sendEveningDigest error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  History Actions
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> markAsRead(String itemId) async {
    try {
      await _notifRepo.markAsRead(itemId);
      final idx = _history.indexWhere((h) => h.id == itemId);
      if (idx != -1 && !_history[idx].wasRead) {
        _history = [
          for (var i = 0; i < _history.length; i++)
            i == idx ? _history[idx].copyWith(wasRead: true) : _history[i],
        ];
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotifController] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notifRepo.markAllAsRead();
      _history = [
        for (final item in _history)
          item.wasRead ? item : item.copyWith(wasRead: true),
      ];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotifController] markAllAsRead error: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _notifRepo.clearHistory();
      _history = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotifController] clearHistory error: $e');
    }
  }

  Future<void> refreshHistory() async {
    try {
      _history = await _notifRepo.getHistory();
      _unreadCount = _history.where((h) => !h.wasRead).length;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotifController] refreshHistory error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Dispose
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _settingsSub?.cancel();
    super.dispose();
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _addToHistory({
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
  }) async {
    // id فريد يجمع timestamp + category لمنع التكرار
    final id = '${category.name}_${DateTime.now().microsecondsSinceEpoch}';

    final item = NotificationHistoryItem(
      id: id,
      title: title,
      body: body,
      categoryName: category.name,
      sentAt: DateTime.now(),
      wasRead: false,
      payload: payload,
    );

    await _notifRepo.addToHistory(item);
    _history = [item, ..._history];
    _unreadCount++;
    notifyListeners();
  }

  /// [FIX #13 + #17] تحديث الـ bridge بأحدث بيانات المستخدم.
  ///
  /// يُستدعى الآن من initialize() (جديد) بالإضافة إلى updateSettings()
  /// و updateStreak() (قديم). هذا يحل مشكلة حفظ bridge بـ activeCourseIds
  /// فارغة عند login بسبب async stream في GlobalLearningState.
  ///
  /// إذا لم يُحمَّل الـ profile بعد عند initialize()، يُرجع مبكراً بأمان —
  /// سيُحدَّث عند أول updateStreak() التالي الذي يأتي من onLogin في main.dart.
  Future<void> _updateBridge(
    NotificationSettings newSettings, {
    bool debounce = false,
  }) async {
    try {
      final userId = _getUserId();
      if (userId.isEmpty) return;

      final List<String> activeCourseIds;
      final Map<String, DateTime> courseLastAccess;

      if (_learningState.hasUserProfile) {
        final activeCourses = _learningState.getActiveCourses();
        activeCourseIds = activeCourses.map((c) => c.courseId).toList();
        courseLastAccess = {
          for (final c in activeCourses) c.courseId: c.lastAccessedAt,
        };
      } else {
        // profile لم يكتمل بعد — لا نكتب بيانات فارغة فوق بيانات صحيحة
        debugPrint(
          '[NotifController] _updateBridge: profile not loaded yet — '
          'skipping bridge update',
        );
        return;
      }

      await NotificationBackgroundBridge.saveUserData(
        userId: userId,
        settings: newSettings,
        activeCourseIds: activeCourseIds,
        courseLastAccess: courseLastAccess,
        currentStreak: _lastKnownStreak,
        preferredTimes: newSettings.toPreferredTimesMap(),
        debounce: debounce,
      );
    } catch (e) {
      debugPrint('[NotifController] _updateBridge error: $e');
    }
  }

  /// هل يستوجب الفرق بين إعدادين إعادة جدولة الإشعارات؟
  bool _shouldRescheduleOnSettingsChange(
    NotificationSettings old,
    NotificationSettings next,
  ) {
    return old.isEnabled != next.isEnabled ||
        old.taskReminders != next.taskReminders ||
        old.summaries != next.summaries ||
        old.motivational != next.motivational ||
        old.preferMorning != next.preferMorning ||
        old.preferAfternoon != next.preferAfternoon ||
        old.preferEvening != next.preferEvening ||
        old.preferNight != next.preferNight ||
        old.morningDigestTime != next.morningDigestTime ||
        old.eveningDigestTime != next.eveningDigestTime ||
        old.weeklyDigestDay != next.weeklyDigestDay ||
        old.weeklyDigestTime != next.weeklyDigestTime ||
        old.lectureReminderMinutes != next.lectureReminderMinutes ||
        !_listEquals(old.preferredDays, next.preferredDays);
  }

  /// إعادة الجدولة في background بدون انتظار (fire-and-forget مقصود)
  void _rescheduleAfterSettingsChange(NotificationSettings newSettings) {
    NotificationSchedulerService.rescheduleSmartNotifications(
      settings: newSettings,
      currentStreak: _lastKnownStreak,
    ).catchError((e) {
      debugPrint(
          '[NotifController] _rescheduleAfterSettingsChange error: $e');
    });
  }

  void _handleTap(String? payload) {
    if (payload == null) return;
    debugPrint('[NotifController] Notification tapped: $payload');
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
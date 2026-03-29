import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:workmanager/workmanager.dart';

import '../models/task_model.dart';
import '../models/notification_settings_model.dart';
import '../models/notification_history_model.dart';
import '../models/gamification_model.dart';
import 'notification_service.dart';
import 'notification_background_bridge.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Constants — Workmanager task names (مختلفة تماماً عن task_sync_service)
// ══════════════════════════════════════════════════════════════════════════════

const String kNotificationDailySyncTask = 'notificationDailySync';
const String kNotificationDailySyncTag = 'notification_daily_sync_tag';

// ══════════════════════════════════════════════════════════════════════════════
// Workmanager callback — يُضاف في main.dart إلى callbackDispatcher الموجود
// ══════════════════════════════════════════════════════════════════════════════

class NotificationSchedulerService {
  NotificationSchedulerService._();

  // ── Workmanager Registration ───────────────────────────────────────────────

  /// تسجيل مهمة الـ background sync اليومية عند منتصف الليل
  static Future<void> registerDailySync() async {
    await Workmanager().registerPeriodicTask(
      kNotificationDailySyncTask,
      kNotificationDailySyncTask,
      tag: kNotificationDailySyncTag,
      frequency: const Duration(hours: 24),
      initialDelay: _timeUntilMidnight(),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    debugPrint('[NotifScheduler] Daily sync registered');
  }

  static Future<void> cancelDailySync() async {
    await Workmanager().cancelByTag(kNotificationDailySyncTag);
    debugPrint('[NotifScheduler] Daily sync cancelled');
  }

  // ── Background Sync (يُستدعى من callbackDispatcher) ──────────────────────

  static Future<void> runBackgroundSync() async {
    debugPrint('[NotifScheduler] Running background sync...');
    try {
      final bridge = await NotificationBackgroundBridge.loadUserData();
      if (bridge == null || !bridge.settings.isEnabled) {
        debugPrint('[NotifScheduler] No user data or notifications disabled');
        return;
      }

      await NotificationService.instance.initialize();

      // مسح scheduledIds القديمة وإعادة البناء من الصفر.
      // ملاحظة: إشعارات course_inactive لا تُجدَّل هنا بل من الـ foreground
      // عبر scheduleCourseInactiveNotification() لضمان deduplication صحيح.
      await _clearScheduledIds();
      await NotificationService.instance.cancelAll();

      await scheduleSmartNotifications(
        settings: bridge.settings,
        currentStreak: bridge.currentStreak,
        preferredTimes: bridge.preferredTimes,
        activeCourseIds: bridge.activeCourseIds,
        courseLastAccess: bridge.courseLastAccess.map((k, v) {
          DateTime parsed;
          try {
            parsed = DateTime.parse(v);
          } catch (_) {
            parsed = DateTime.now();
          }
          return MapEntry(k, parsed);
        }),
      );

      await scheduleSummaryNotifications(settings: bridge.settings);

      debugPrint('[NotifScheduler] Background sync complete');
    } catch (e) {
      debugPrint('[NotifScheduler] runBackgroundSync error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. إشعارات المهام اليومية
  // ══════════════════════════════════════════════════════════════════════════

  /// جدولة إشعارات كل مهام اليوم (يُستدعى بعد syncDailyTasks)
  static Future<void> scheduleTodayTaskNotifications({
    required List<TaskModel> dailyTasks,
    required List<TaskModel> courseTasks,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;

    // فتح box مرة واحدة + Set مشترك لحل Race Condition:
    // بدل N قراءة/كتابة منفصلة داخل كل loop iteration
    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledIds = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    for (final task in dailyTasks) {
      if (task.type == TaskType.lecture) {
        await _scheduleLectureNotifications(task, settings, scheduledIds);
      } else if (task.type == TaskType.studySession) {
        await _scheduleStudySessionNotifications(task, settings, scheduledIds);
      }
    }

    for (final task in courseTasks) {
      if (task.type == TaskType.skillCourse) {
        await _scheduleCourseReminderNotification(task, settings, scheduledIds);
      }
    }

    // كتابة واحدة بعد كل الجدولة بدل N كتابة داخل الـ loop
    await box.put('scheduledIds', scheduledIds.toList());
  }

  /// جدولة إشعارات مهمة مخصصة جديدة
  static Future<void> scheduleCustomTaskNotification({
    required TaskModel task,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;
    if (!task.hasReminder) return;
    if (task.scheduledDate == null) return;

    final now           = DateTime.now();
    final taskTime      = task.scheduledDate!; // دائماً DateTime كامل عند hasReminder
    final taskDateOnly  = DateTime(taskTime.year, taskTime.month, taskTime.day);
    final todayOnly     = DateTime(now.year, now.month, now.day);
    final daysUntilTask = taskDateOnly.difference(todayOnly).inDays;

    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledSet = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    // ── إشعار 1: قبل يوم كامل ────────────────────────────────────────────
    // يُجدَّل فقط إذا كان الموعد بعد أكثر من يوم
    if (daysUntilTask >= 1) {
      final dayBefore = DateTime(
        taskDateOnly.year,
        taskDateOnly.month,
        taskDateOnly.day - 1,
        taskTime.hour,
        taskTime.minute,
      );
      final dayBeforeId = 'custom_${task.id}_day_before';

      if (!scheduledSet.contains(dayBeforeId) && dayBefore.isAfter(now)) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(dayBeforeId),
          title: '📌 تذكير — غداً',
          body: '${task.title} غداً الساعة ${_timeLabel(taskTime)}',
          scheduledTime: dayBefore,
          category: NotificationCategory.tasks,
          payload: jsonEncode({'type': 'custom_day_before', 'taskId': task.id}),
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
        scheduledSet.add(dayBeforeId);
      }
    }

    // ── إشعار 2: قبل ساعة من الموعد ─────────────────────────────────────
    final oneHourBefore = taskTime.subtract(const Duration(hours: 1));
    final oneHourId     = 'custom_${task.id}_one_hour';

    if (!scheduledSet.contains(oneHourId) && oneHourBefore.isAfter(now)) {
      await NotificationService.instance.scheduleAt(
        id: NotificationIdHelper.toInt(oneHourId),
        title: '📌 تذكير — باقي ساعة',
        body: '${task.title} الساعة ${_timeLabel(taskTime)}',
        scheduledTime: oneHourBefore,
        category: NotificationCategory.tasks,
        payload: jsonEncode({'type': 'custom_one_hour', 'taskId': task.id}),
        vibrate: settings.vibrate,
        sound: settings.sound,
      );
      scheduledSet.add(oneHourId);
    }

    // ── إشعار 3: في وقت المهمة نفسه ─────────────────────────────────────
    final atTimeId = 'custom_${task.id}_at_time';

    if (!scheduledSet.contains(atTimeId) && taskTime.isAfter(now)) {
      await NotificationService.instance.scheduleAt(
        id: NotificationIdHelper.toInt(atTimeId),
        title: '📌 حان وقت مهمتك',
        body: task.title,
        scheduledTime: taskTime,
        category: NotificationCategory.tasks,
        payload: jsonEncode({'type': 'custom_at_time', 'taskId': task.id}),
        vibrate: settings.vibrate,
        sound: settings.sound,
      );
      scheduledSet.add(atTimeId);
    }

    await box.put('scheduledIds', scheduledSet.toList());
    debugPrint('[NotifScheduler] Custom task reminders scheduled: ${task.id}');
  }

  /// جدولة إشعارات مهمة مخصصة دورية (يومية أو أسبوعية)
  ///
  /// المنطق:
  /// - يومية: إشعار قبل المهمة بـ [reminderMinutesBefore] كل يوم
  /// - أسبوعية: إشعار قبل يوم (نفس الوقت) + إشعار قبل [reminderMinutesBefore]
  ///
  /// يُستدعى من:
  /// - [NotificationController.scheduleCustomTask] عند إنشاء المهمة
  /// - [NotificationSchedulerService.runBackgroundSync] كل منتصف ليل
  static Future<void> scheduleRecurringTaskNotifications({
    required TaskModel task,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;
    if (!task.isRecurring) return;
    if (task.scheduledDate == null || task.recurrenceType == null) return;

    final now      = DateTime.now();
    final taskTime = task.scheduledDate!;

    // حساب التاريخ الصحيح للتكرار القادم
    final nextOccurrence = _nextRecurringDate(
      original: taskTime,
      recurrenceType: task.recurrenceType!,
      now: now,
    );

    if (nextOccurrence == null) return;

    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledSet = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    // ── إشعار 1: قبل يوم كامل (للمهام الأسبوعية فقط) ────────────────────
    if (task.recurrenceType == RecurrenceType.weekly) {
      final dayBefore = nextOccurrence.subtract(const Duration(days: 1));
      final dayBeforeId =
          'recurring_${task.id}_day_before_${_dateKey(nextOccurrence)}';

      if (!scheduledSet.contains(dayBeforeId) && dayBefore.isAfter(now)) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(dayBeforeId),
          title: '📌 تذكير — غداً',
          body: '${task.title} غداً الساعة ${_timeLabel(nextOccurrence)}',
          scheduledTime: dayBefore,
          category: NotificationCategory.tasks,
          payload: jsonEncode({
            'type': 'recurring_day_before',
            'taskId': task.id,
          }),
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
        scheduledSet.add(dayBeforeId);
      }
    }

    // ── إشعار 2: قبل المهمة بـ reminderMinutesBefore ─────────────────────
    if (task.reminderMinutesBefore > 0) {
      final reminderTime = nextOccurrence.subtract(
        Duration(minutes: task.reminderMinutesBefore),
      );
      final reminderId =
          'recurring_${task.id}_reminder_${_dateKey(nextOccurrence)}';

      if (!scheduledSet.contains(reminderId) && reminderTime.isAfter(now)) {
        final minutesLabel = task.reminderMinutesBefore < 60
            ? '${task.reminderMinutesBefore} دقيقة'
            : task.reminderMinutesBefore == 60
                ? 'ساعة'
                : '${task.reminderMinutesBefore ~/ 60} ساعة'
                    '${task.reminderMinutesBefore % 60 > 0 ? ' و${task.reminderMinutesBefore % 60} دقيقة' : ''}';

        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(reminderId),
          title: '📌 تذكير — بعد $minutesLabel',
          body: '${task.title} الساعة ${_timeLabel(nextOccurrence)}',
          scheduledTime: reminderTime,
          category: NotificationCategory.tasks,
          payload: jsonEncode({
            'type': 'recurring_reminder',
            'taskId': task.id,
          }),
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
        scheduledSet.add(reminderId);
      }
    }

    // ── إشعار 3: في وقت المهمة نفسه ─────────────────────────────────────
    final atTimeId =
        'recurring_${task.id}_at_time_${_dateKey(nextOccurrence)}';

    if (!scheduledSet.contains(atTimeId) && nextOccurrence.isAfter(now)) {
      await NotificationService.instance.scheduleAt(
        id: NotificationIdHelper.toInt(atTimeId),
        title: '📌 حان وقت مهمتك',
        body: task.title,
        scheduledTime: nextOccurrence,
        category: NotificationCategory.tasks,
        payload: jsonEncode({
          'type': 'recurring_at_time',
          'taskId': task.id,
        }),
        vibrate: settings.vibrate,
        sound: settings.sound,
      );
      scheduledSet.add(atTimeId);
    }

    await box.put('scheduledIds', scheduledSet.toList());
    debugPrint(
      '[NotifScheduler] Recurring task scheduled: ${task.id} '
      '(${task.recurrenceType!.name}) next: $nextOccurrence',
    );
  }

  /// إلغاء إشعارات مهمة دورية
  static Future<void> cancelRecurringTaskNotifications(String taskId) async {
    try {
      final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
      final ids = Set<String>.from(
        box.get('scheduledIds', defaultValue: <String>[]) as List,
      );

      // إلغاء كل الإشعارات المرتبطة بهذه المهمة الدورية
      final toCancel =
          ids.where((id) => id.startsWith('recurring_${taskId}_')).toSet();

      for (final id in toCancel) {
        await NotificationService.instance.cancel(
          NotificationIdHelper.toInt(id),
        );
      }

      await _removeMultipleFromScheduledIds(toCancel);
      debugPrint(
          '[NotifScheduler] Recurring task cancelled: $taskId (${toCancel.length} notifications)');
    } catch (e) {
      debugPrint(
          '[NotifScheduler] cancelRecurringTaskNotifications error: $e');
    }
  }

  // ── Lecture ───────────────────────────────────────────────────────────────

  static Future<void> _scheduleLectureNotifications(
    TaskModel task,
    NotificationSettings settings,
    Set<String> scheduledIds,
  ) async {
    if (task.scheduledDate == null || task.timeSlot == null) return;

    final slot = TaskModel.parseTimeSlot(task.timeSlot!);
    if (slot == null) return;

    final startTime = DateTime(
      task.scheduledDate!.year,
      task.scheduledDate!.month,
      task.scheduledDate!.day,
      slot.startMin ~/ 60,
      slot.startMin % 60,
    );

    // 1. قبل N دقيقة (من إعدادات المستخدم)
    final beforeId = 'lec_${task.id}_before';
    if (!scheduledIds.contains(beforeId)) {
      final beforeTime = startTime.subtract(
        Duration(minutes: settings.lectureReminderMinutes),
      );
      if (beforeTime.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(beforeId),
          title: '🎓 تذكير محاضرة',
          body:
              '${task.subjectName ?? task.title} تبدأ الساعة ${_timeLabel(startTime)} (بعد ${settings.lectureReminderMinutes} دقيقة)',
          scheduledTime: beforeTime,
          category: NotificationCategory.tasks,
          payload: jsonEncode({'type': 'lecture_before', 'taskId': task.id}),
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
        scheduledIds.add(beforeId);
      }
    }

    // 2. عند البداية
    final startId = 'lec_${task.id}_start';
    if (!scheduledIds.contains(startId) && startTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleAt(
        id: NotificationIdHelper.toInt(startId),
        title: '▶️ محاضرة الآن',
        body: 'محاضرة ${task.subjectName ?? task.title} بدأت الآن!',
        scheduledTime: startTime,
        category: NotificationCategory.tasks,
        payload: jsonEncode({'type': 'lecture_start', 'taskId': task.id}),
        vibrate: settings.vibrate,
        sound: settings.sound,
      );
      scheduledIds.add(startId);
    }

    // 3. متابعة بعد انتهاء المحاضرة (فقط إذا لم يُسجَّل حضور بعد)
    if (task.attendanceStatus == null) {
      final followupId = 'lec_${task.id}_followup';
      if (!scheduledIds.contains(followupId)) {
        final slotDuration = (slot.endMin - slot.startMin).abs();
        final actualDurationMinutes =
            task.durationMinutes ?? (slotDuration > 0 ? slotDuration : 60);

        final followupTime = startTime.add(
          Duration(minutes: actualDurationMinutes + 10),
        );
        if (followupTime.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleAt(
            id: NotificationIdHelper.toInt(followupId),
            title: '📝 هل حضرت؟',
            body: 'هل حضرت محاضرة ${task.subjectName ?? task.title}؟',
            scheduledTime: followupTime,
            category: NotificationCategory.tasks,
            payload: jsonEncode({
              'type': 'lecture_followup',
              'taskId': task.id,
            }),
            vibrate: false,
            sound: false,
          );
          scheduledIds.add(followupId);
        }
      }
    }
  }

  // ── Study Session ─────────────────────────────────────────────────────────

  static Future<void> _scheduleStudySessionNotifications(
    TaskModel task,
    NotificationSettings settings,
    Set<String> scheduledIds,
  ) async {
    if (task.scheduledDate == null || task.timeSlot == null) return;

    final sessionId = task.studySessionId ?? task.id;

    final slot = TaskModel.parseTimeSlot(task.timeSlot!);
    if (slot == null) return;

    final startTime = DateTime(
      task.scheduledDate!.year,
      task.scheduledDate!.month,
      task.scheduledDate!.day,
      slot.startMin ~/ 60,
      slot.startMin % 60,
    );

    // 1. قبل 15 دقيقة
    final beforeId = 'study_${sessionId}_before';
    if (!scheduledIds.contains(beforeId)) {
      final beforeTime = startTime.subtract(const Duration(minutes: 15));
      if (beforeTime.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(beforeId),
          title: '📚 جلسة مذاكرة قريباً',
          body: 'جلسة مذاكرة ${task.subjectName ?? task.title} بعد 15 دقيقة',
          scheduledTime: beforeTime,
          category: NotificationCategory.tasks,
          payload: jsonEncode({'type': 'study_before', 'sessionId': sessionId}),
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
        scheduledIds.add(beforeId);
      }
    }

    // 2. عند البداية
    final startId = 'study_${sessionId}_start';
    if (!scheduledIds.contains(startId) && startTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleAt(
        id: NotificationIdHelper.toInt(startId),
        title: '🔥 ابدأ المذاكرة الآن!',
        body: 'ابدأ جلسة مذاكرة ${task.subjectName ?? task.title}',
        scheduledTime: startTime,
        category: NotificationCategory.tasks,
        payload: jsonEncode({'type': 'study_start', 'sessionId': sessionId}),
        vibrate: settings.vibrate,
        sound: settings.sound,
      );
      scheduledIds.add(startId);
    }

    // 3. متابعة بعد انتهاء الجلسة (فقط إذا لم تُكتمل بعد)
    if (task.studySessionStatus != StudySessionTaskStatus.completed) {
      final followupId = 'study_${sessionId}_followup';
      if (!scheduledIds.contains(followupId)) {
        final slotDuration = (slot.endMin - slot.startMin).abs();
        final actualDurationMinutes =
            task.durationMinutes ?? (slotDuration > 0 ? slotDuration : 60);

        final followupTime = startTime.add(
          Duration(minutes: actualDurationMinutes + 10),
        );
        if (followupTime.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleAt(
            id: NotificationIdHelper.toInt(followupId),
            title: '⏱️ لم تكمل الجلسة بعد',
            body: 'لم تكمل جلسة مذاكرة ${task.subjectName ?? task.title} بعد',
            scheduledTime: followupTime,
            category: NotificationCategory.tasks,
            payload: jsonEncode({
              'type': 'study_followup',
              'sessionId': sessionId,
            }),
            vibrate: false,
            sound: false,
          );
          scheduledIds.add(followupId);
        }
      }
    }
  }

  static Future<void> sendStudyPlanReminderNotification({
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;

    const notifId = 'study_plan_weekly_reminder';

    // مفتاح الأسبوع الحالي — يضمن إرسال التذكير مرة واحدة فقط في كل أسبوع
    final weekSuffix = _currentWeekKey();
    final weeklyNotifId = '${notifId}_$weekSuffix';

    // deduplication — لا نُرسل أكثر من مرة في نفس الأسبوع
    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledIds = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );
    if (scheduledIds.contains(weeklyNotifId)) return;

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt(notifId),
      title: '📚 لم تُولَّد خطة المذاكرة بعد',
      body: 'ابدأ أسبوعك بخطة ذكية — افتح الجدول الذكي الآن',
      category: NotificationCategory.tasks,
      payload: jsonEncode({'type': 'study_plan_reminder'}),
      vibrate: settings.vibrate,
      sound: settings.sound,
    );

    scheduledIds.add(weeklyNotifId);
    await box.put('scheduledIds', scheduledIds.toList());
    debugPrint('[NotifScheduler] Study plan reminder sent');
  }

  // ── Course Reminder ───────────────────────────────────────────────────────

  static Future<void> _scheduleCourseReminderNotification(
    TaskModel task,
    NotificationSettings settings,
    Set<String> scheduledIds,
  ) async {
    if (task.courseId == null) return;

    final courseId = task.courseId!;
    final reminderId = 'course_${courseId}_reminder';
    if (scheduledIds.contains(reminderId)) return;

    final reminderTime = _nextPreferredTime(settings);
    if (reminderTime == null) return;

    final courseLabel = task.courseTitle ?? task.title;
    await NotificationService.instance.scheduleAt(
      id: NotificationIdHelper.toInt(reminderId),
      title: '🎯 لديك درس جديد',
      body: 'لديك درس جديد في $courseLabel',
      scheduledTime: reminderTime,
      category: NotificationCategory.tasks,
      payload: jsonEncode({'type': 'course_reminder', 'courseId': courseId}),
      vibrate: false,
      sound: false,
    );

    scheduledIds.add(reminderId);
  }

  static Future<void> scheduleCourseInactiveNotification({
    required String courseId,
    required String courseTitle,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;

    final inactiveId = 'course_${courseId}_inactive';

    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledSet = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );
    if (scheduledSet.contains(inactiveId)) return;

    final reminderTime = DateTime.now().add(const Duration(days: 3));

    await NotificationService.instance.scheduleAt(
      id: NotificationIdHelper.toInt(inactiveId),
      title: '⚠️ غياب عن الكورس',
      body: 'لم تشاهد أي درس في $courseTitle منذ 3 أيام!',
      scheduledTime: reminderTime,
      category: NotificationCategory.tasks,
      payload: jsonEncode({'type': 'course_inactive', 'courseId': courseId}),
      vibrate: false,
      sound: false,
    );

    scheduledSet.add(inactiveId);
    await box.put('scheduledIds', scheduledSet.toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. إشعارات التحفيز
  // ══════════════════════════════════════════════════════════════════════════

  /// جدولة الإشعارات الذكية اليومية (streak + تذكير الهدف)
  static Future<void> scheduleSmartNotifications({
    required NotificationSettings settings,
    required int currentStreak,
    required Map<String, bool> preferredTimes,
    required List<String> activeCourseIds,
    required Map<String, DateTime> courseLastAccess,
  }) async {
    if (!settings.isEnabled || !settings.motivational) return;

    final today = DateTime.now();
    final todayAppDay = NotificationSettings.dateTimeWeekdayToAppDay(
      today.weekday,
    );

    // فتح box مرة واحدة وSet مشترك لكل الإشعارات
    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledIds = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    // ─ Streak ────────────────────────────────────────────────────────────────
    if (currentStreak >= 3) {
      final streakId = 'streak_daily';
      if (!scheduledIds.contains(streakId)) {
        final streakTime = _nextPreferredTime(settings);
        if (streakTime != null) {
          await NotificationService.instance.scheduleAt(
            id: NotificationIdHelper.toInt(streakId),
            title: '🔥 Streak مستمر!',
            body:
                'لديك streak مستمر منذ $currentStreak ${currentStreak == 1 ? "يوم" : "أيام"}! لا تفقده',
            scheduledTime: streakTime,
            category: NotificationCategory.motivational,
            vibrate: false,
            sound: false,
          );
          scheduledIds.add(streakId);
        }
      }
    }

    // ─ تذكير أيام التعلم المفضلة ─────────────────────────────────────────
    if (settings.preferredDays.contains(todayAppDay) &&
        settings.taskReminders) {
      final dayReminderId = 'preferred_day_$todayAppDay';
      if (!scheduledIds.contains(dayReminderId)) {
        final dayTime = _nextPreferredTime(settings);
        if (dayTime != null) {
          await NotificationService.instance.scheduleAt(
            id: NotificationIdHelper.toInt(dayReminderId),
            title: '📚 يوم تعلم!',
            body: 'اليوم يوم تعلم! ماذا ستتعلم اليوم؟',
            scheduledTime: dayTime,
            category: NotificationCategory.motivational,
            vibrate: false,
            sound: false,
          );
          scheduledIds.add(dayReminderId);
        }
      }
    }

    // ─ تذكير نهاية اليوم (11:00 PM) ─────────────────────────────────────
    final endOfDayId = 'end_of_day_reminder';
    if (!scheduledIds.contains(endOfDayId)) {
      // الجدولة الساعة 11:00 PM — الـ title يعكس الوقت الفعلي
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 0);
      if (endOfDay.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(endOfDayId),
          title: '⚠️ تذكير نهاية اليوم',
          body: 'اليوم يوشك على الانتهاء، هل أكملت مهامك؟',
          scheduledTime: endOfDay,
          category: NotificationCategory.motivational,
          vibrate: false,
          sound: false,
        );
        scheduledIds.add(endOfDayId);
      }
    }

    // كتابة واحدة بعد كل الجدولة
    await box.put('scheduledIds', scheduledIds.toList());
  }

  /// إرسال إشعار إنجاز فوري
  static Future<void> sendAchievementNotification({
    required Achievement achievement,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.achievements) return;

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt('achievement_${achievement.id}'),
      title: '🎉 إنجاز جديد!',
      body:
          'تهانينا! فتحت إنجاز "${achievement.titleAr}" — +${achievement.pointsReward} نقطة',
      category: NotificationCategory.achievements,
      payload: jsonEncode({
        'type': 'achievement',
        'achievementId': achievement.id,
      }),
      vibrate: settings.vibrate,
      sound: settings.sound,
    );
  }

  /// إرسال إشعار تقدم المهارة (50% أو 80%) — مرة واحدة فقط
  static Future<void> sendSkillMilestoneNotification({
    required String skillId,
    required String skillName,
    required int percentage,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.motivational) return;
    if (percentage != 50 && percentage != 80) return;

    final milestoneId = 'skill_milestone_${skillId}_$percentage';

    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledSet = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );
    if (scheduledSet.contains(milestoneId)) return;

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt(milestoneId),
      title: '⭐ تقدم رائع!',
      body: 'أكملت $percentage% من مهارة $skillName، استمر!',
      category: NotificationCategory.motivational,
      vibrate: false,
      sound: false,
    );

    scheduledSet.add(milestoneId);
    await box.put('scheduledIds', scheduledSet.toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. إشعارات الملخصات
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> scheduleSummaryNotifications({
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.summaries) return;

    final today = DateTime.now();

    // فتح box مرة واحدة وSet مشترك
    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledIds = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    // ─ الملخص الصباحي ────────────────────────────────────────────────────
    final morningId = 'summary_morning';
    if (!scheduledIds.contains(morningId)) {
      final morningTime = DateTime(
        today.year,
        today.month,
        today.day,
        settings.morningDigestTime.hour,
        settings.morningDigestTime.minute,
      );
      if (morningTime.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(morningId),
          title: '📋 ملخص الصباح',
          body: 'اضغط لرؤية مهام اليوم',
          scheduledTime: morningTime,
          category: NotificationCategory.summaries,
          payload: jsonEncode({'type': 'summary_morning'}),
          vibrate: false,
          sound: false,
        );
        scheduledIds.add(morningId);
      }
    }

    // ─ الملخص المسائي ────────────────────────────────────────────────────
    final eveningId = 'summary_evening';
    if (!scheduledIds.contains(eveningId)) {
      final eveningTime = DateTime(
        today.year,
        today.month,
        today.day,
        settings.eveningDigestTime.hour,
        settings.eveningDigestTime.minute,
      );
      if (eveningTime.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(eveningId),
          title: '✨ ملخص المساء',
          body: 'اضغط لرؤية إنجازات اليوم',
          scheduledTime: eveningTime,
          category: NotificationCategory.summaries,
          payload: jsonEncode({'type': 'summary_evening'}),
          vibrate: false,
          sound: false,
        );
        scheduledIds.add(eveningId);
      }
    }

    // ─ الملخص الأسبوعي ───────────────────────────────────────────────────
    final weeklyId = 'summary_weekly';
    if (!scheduledIds.contains(weeklyId)) {
      final nextWeeklyTime = _nextWeeklyTime(
        targetWeekdayIndex: settings.weeklyDigestDay,
        targetTime: settings.weeklyDigestTime,
      );
      if (nextWeeklyTime != null && nextWeeklyTime.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(weeklyId),
          title: '📊 ملخص الأسبوع',
          body: 'اضغط لرؤية ملخص أسبوعك',
          scheduledTime: nextWeeklyTime,
          category: NotificationCategory.summaries,
          payload: jsonEncode({'type': 'summary_weekly'}),
          vibrate: false,
          sound: false,
        );
        scheduledIds.add(weeklyId);
      }
    }

    // كتابة واحدة
    await box.put('scheduledIds', scheduledIds.toList());
  }

  /// إرسال الملخص الصباحي الفعلي
  static Future<void> sendMorningDigest({
    required int lectureCount,
    required int studySessionCount,
    required int courseTaskCount,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.summaries) return;

    final String body;
    if (lectureCount == 0 && studySessionCount == 0 && courseTaskCount == 0) {
      body = '🎉 لا مهام اليوم! يوم مثالي للراحة أو التقدم في الكورسات';
    } else {
      final parts = <String>[];
      if (lectureCount > 0) parts.add('• $lectureCount محاضرة');
      if (studySessionCount > 0) parts.add('• $studySessionCount جلسة مذاكرة');
      if (courseTaskCount > 0) parts.add('• $courseTaskCount دروس كورسات');
      body = '📋 لديك اليوم:\n${parts.join('\n')}\nجاهز للبدء؟';
    }

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt('summary_morning_content'),
      title: '☀️ صباح الخير!',
      body: body,
      category: NotificationCategory.summaries,
      payload: jsonEncode({'type': 'summary_morning'}),
      vibrate: false,
      sound: false,
    );
  }

  /// إرسال الملخص المسائي الفعلي
  static Future<void> sendEveningDigest({
    required int completedLectures,
    required int completedStudySessions,
    required int completedLessons,
    required int pendingCount,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.summaries) return;

    final String body;
    if (pendingCount == 0) {
      body = '🏆 أكملت جميع مهام اليوم! عمل رائع';
    } else {
      final parts = <String>[];
      if (completedLectures > 0) {
        parts.add('✅ حضرت $completedLectures محاضرة');
      }
      if (completedStudySessions > 0) {
        parts.add('✅ أكملت $completedStudySessions جلسة مذاكرة');
      }
      if (completedLessons > 0) {
        parts.add('✅ أكملت $completedLessons درس');
      }
      if (pendingCount > 0) parts.add('⏳ باقي $pendingCount مهمة');
      body = '✨ إنجازات اليوم:\n${parts.join('\n')}';
    }

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt('summary_evening_content'),
      title: '🌙 ملخص المساء',
      body: body,
      category: NotificationCategory.summaries,
      payload: jsonEncode({'type': 'summary_evening'}),
      vibrate: false,
      sound: false,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Cancel Helpers (يُستدعى من TaskController عند إكمال المهام)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> cancelLectureFollowup(String taskId) async {
    final id = 'lec_${taskId}_followup';
    await NotificationService.instance.cancel(NotificationIdHelper.toInt(id));
    await _removeFromScheduledIds(id);
    debugPrint('[NotifScheduler] Cancelled lecture followup: $id');
  }

  static Future<void> cancelStudySessionFollowup(String sessionId) async {
    final id = 'study_${sessionId}_followup';
    await NotificationService.instance.cancel(NotificationIdHelper.toInt(id));
    await _removeFromScheduledIds(id);
    debugPrint('[NotifScheduler] Cancelled study followup: $id');
  }

  static Future<void> cancelCourseInactive(String courseId) async {
    final id = 'course_${courseId}_inactive';
    await NotificationService.instance.cancel(NotificationIdHelper.toInt(id));
    await _removeFromScheduledIds(id);
    debugPrint('[NotifScheduler] Cancelled course inactive: $id');
  }

  static Future<void> cancelCustomTaskReminder(String taskId) async {
    try {
      // إلغاء الإشعارات الثلاثة
      final ids = {
        'custom_${taskId}_day_before',
        'custom_${taskId}_one_hour',
        'custom_${taskId}_at_time',
      };

      for (final id in ids) {
        await NotificationService.instance.cancel(
          NotificationIdHelper.toInt(id),
        );
      }

      await _removeMultipleFromScheduledIds(ids);
      debugPrint('[NotifScheduler] Custom task reminders cancelled: $taskId');
    } catch (e) {
      debugPrint('[NotifScheduler] cancelCustomTaskReminder error: $e');
    }
  }

  /// إعادة جدولة كاملة (عند تغيير الإعدادات أو الجدول)
  static Future<void> rescheduleAll({
    required List<TaskModel> dailyTasks,
    required List<TaskModel> courseTasks,
    required NotificationSettings settings,
    required int currentStreak,
    required List<String> activeCourseIds,
    required Map<String, DateTime> courseLastAccess,
  }) async {
    await NotificationService.instance.cancelAll();
    await _clearScheduledIds();

    await scheduleTodayTaskNotifications(
      dailyTasks: dailyTasks,
      courseTasks: courseTasks,
      settings: settings,
    );

    await scheduleSmartNotifications(
      settings: settings,
      currentStreak: currentStreak,
      preferredTimes: settings.toPreferredTimesMap(),
      activeCourseIds: activeCourseIds,
      courseLastAccess: courseLastAccess,
    );

    await scheduleSummaryNotifications(settings: settings);
  }

  /// إعادة جدولة الإشعارات الذكية والملخصات فقط (بدون مهام)
  static Future<void> rescheduleSmartNotifications({
    required NotificationSettings settings,
    required int currentStreak,
  }) async {
    final pendingNotifications =
        await NotificationService.instance.getPendingNotifications();
    final courseInactiveIds =
        pendingNotifications
            .where((n) {
              try {
                final payload =
                    jsonDecode(n.payload ?? '{}') as Map<String, dynamic>;
                return payload['type'] == 'course_inactive';
              } catch (_) {
                return false;
              }
            })
            .map((n) => n.id)
            .toList();

    for (final id in courseInactiveIds) {
      await NotificationService.instance.cancel(id);
    }

    final smartIds = [
      'streak_daily',
      'end_of_day_reminder',
      'summary_morning',
      'summary_evening',
      'summary_weekly',
      for (var i = 0; i <= 6; i++) 'preferred_day_$i',
    ];

    for (final id in smartIds) {
      await NotificationService.instance.cancel(NotificationIdHelper.toInt(id));
    }

    await _removeSmartAndCourseInactiveIds(smartIds.toSet());

    await scheduleSmartNotifications(
      settings: settings,
      currentStreak: currentStreak,
      preferredTimes: settings.toPreferredTimesMap(),
      activeCourseIds: const [],
      courseLastAccess: const {},
    );

    await scheduleSummaryNotifications(settings: settings);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. إشعارات الامتحانات
  // ══════════════════════════════════════════════════════════════════════════

  /// جدولة تذكيرات امتحان واحد على المراحل: 14 يوم / 7 أيام / يوم واحد.
  static Future<void> scheduleExamReminders({
    required String examId,
    required String subjectName,
    required String examTypeLabel,
    required DateTime examDate,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;
    if (examDate.isBefore(DateTime.now())) return;

    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledIds = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    const reminders = [
      (days: 14, label: 'بعد أسبوعين'),
      (days: 7, label: 'بعد أسبوع'),
      (days: 1, label: 'غداً'),
    ];

    for (final r in reminders) {
      final notifId = 'exam_${examId}_${r.days}d';
      final notifTime = examDate.subtract(Duration(days: r.days));

      if (scheduledIds.contains(notifId)) continue;
      if (notifTime.isBefore(DateTime.now())) continue;

      await NotificationService.instance.scheduleAt(
        id: NotificationIdHelper.toInt(notifId),
        title: '📝 تذكير امتحان — $subjectName',
        body:
            'امتحان $examTypeLabel في $subjectName ${r.label}! '
            'الموعد: ${_timeLabel(examDate)} بتاريخ '
            '${examDate.day}/${examDate.month}',
        scheduledTime: notifTime,
        category: NotificationCategory.tasks,
        payload: jsonEncode({'type': 'exam_reminder', 'examId': examId}),
        vibrate: settings.vibrate,
        sound: settings.sound,
      );
      scheduledIds.add(notifId);
      debugPrint(
        '[NotifScheduler] Exam reminder scheduled: $notifId at $notifTime',
      );
    }

    await box.put('scheduledIds', scheduledIds.toList());
  }

  /// إلغاء كل تذكيرات امتحان معين
  static Future<void> cancelExamReminders(String examId) async {
    final remindersToCancel = [
      'exam_${examId}_14d',
      'exam_${examId}_7d',
      'exam_${examId}_1d',
    ];

    for (final id in remindersToCancel) {
      await NotificationService.instance.cancel(NotificationIdHelper.toInt(id));
    }
    await _removeMultipleFromScheduledIds(remindersToCancel.toSet());
    debugPrint('[NotifScheduler] Exam reminders cancelled for: $examId');
  }

  /// جدولة تذكيرات كل امتحانات الفصل دفعةً واحدة.
  ///
  /// [FIX #7] كانت تستدعي scheduleExamReminders لكل امتحان منفردةً،
  /// مما يعني N فتح + N قراءة + N كتابة لـ Hive box.
  /// الآن: فتح واحد → تحديث Set في الذاكرة → كتابة واحدة في النهاية.
  static Future<void> scheduleAllExamReminders({
    required List<
      ({
        String examId,
        String subjectName,
        String examTypeLabel,
        DateTime examDate,
        bool completed,
      })
    >
    exams,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.taskReminders) return;
    if (exams.isEmpty) return;

    // [FIX #7] فتح Hive مرة واحدة لكل الامتحانات
    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledIds = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );

    const reminders = [
      (days: 14, label: 'بعد أسبوعين'),
      (days: 7, label: 'بعد أسبوع'),
      (days: 1, label: 'غداً'),
    ];

    for (final exam in exams) {
      if (exam.completed) continue;
      if (exam.examDate.isBefore(DateTime.now())) continue;

      for (final r in reminders) {
        final notifId = 'exam_${exam.examId}_${r.days}d';
        final notifTime = exam.examDate.subtract(Duration(days: r.days));

        if (scheduledIds.contains(notifId)) continue;
        if (notifTime.isBefore(DateTime.now())) continue;

        await NotificationService.instance.scheduleAt(
          id: NotificationIdHelper.toInt(notifId),
          title: '📝 تذكير امتحان — ${exam.subjectName}',
          body:
              'امتحان ${exam.examTypeLabel} في ${exam.subjectName} ${r.label}! '
              'الموعد: ${_timeLabel(exam.examDate)} بتاريخ '
              '${exam.examDate.day}/${exam.examDate.month}',
          scheduledTime: notifTime,
          category: NotificationCategory.tasks,
          payload: jsonEncode({'type': 'exam_reminder', 'examId': exam.examId}),
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
        scheduledIds.add(notifId);
        debugPrint(
          '[NotifScheduler] Exam reminder scheduled: $notifId at $notifTime',
        );
      }
    }

    // [FIX #7] كتابة واحدة بعد كل الامتحانات
    await box.put('scheduledIds', scheduledIds.toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. إشعار انتهاء الفصل الدراسي
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> sendSemesterEndNotification({
    required String semesterLabel,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled) return;

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt('semester_end_notification'),
      title: '🎓 انتهى $semesterLabel',
      body: 'انتهى الفصل الدراسي! احفظ بياناتك وابدأ فصلاً جديداً.',
      category: NotificationCategory.summaries,
      payload: jsonEncode({'type': 'semester_end'}),
      vibrate: settings.vibrate,
      sound: settings.sound,
    );
    debugPrint(
      '[NotifScheduler] Semester end notification sent: $semesterLabel',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. إشعار ترقية المستوى (Level Up)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> sendLevelUpNotification({
    required int newLevel,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.achievements) return;

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt('level_up_$newLevel'),
      title: '🏆 ترقية مستوى!',
      body: 'تهانينا! وصلت إلى المستوى $newLevel. استمر في التقدم! 🚀',
      category: NotificationCategory.achievements,
      payload: jsonEncode({'type': 'level_up', 'level': newLevel}),
      vibrate: settings.vibrate,
      sound: settings.sound,
    );
    debugPrint('[NotifScheduler] Level up notification sent: level $newLevel');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 7. إشعار الاختبار المعلق
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> sendPendingAssessmentNotification({
    required String skillId,
    required String skillName,
    required NotificationSettings settings,
  }) async {
    if (!settings.isEnabled || !settings.motivational) return;

    final notifId = 'pending_assessment_$skillId';

    final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
    final scheduledSet = Set<String>.from(
      box.get('scheduledIds', defaultValue: <String>[]) as List,
    );
    if (scheduledSet.contains(notifId)) return;

    await NotificationService.instance.showNow(
      id: NotificationIdHelper.toInt(notifId),
      title: '📋 اختبار معلق',
      body: 'أكملت كورس $skillName! لا تنسَ أداء اختبار المهارة لتأكيد تقدمك.',
      category: NotificationCategory.motivational,
      payload: jsonEncode({'type': 'pending_assessment', 'skillId': skillId}),
      vibrate: false,
      sound: false,
    );

    scheduledSet.add(notifId);
    await box.put('scheduledIds', scheduledSet.toList());
    debugPrint(
      '[NotifScheduler] Pending assessment notification sent: $skillId',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private — Hive Deduplication Store
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> _removeFromScheduledIds(String notifId) async {
    try {
      final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
      final ids = Set<String>.from(
        box.get('scheduledIds', defaultValue: <String>[]) as List,
      );
      ids.remove(notifId);
      await box.put('scheduledIds', ids.toList());
    } catch (e) {
      debugPrint('[NotifScheduler] _removeFromScheduledIds error: $e');
    }
  }

  static Future<void> _removeMultipleFromScheduledIds(
    Set<String> toRemove,
  ) async {
    try {
      final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
      final ids = Set<String>.from(
        box.get('scheduledIds', defaultValue: <String>[]) as List,
      );
      ids.removeAll(toRemove);
      await box.put('scheduledIds', ids.toList());
    } catch (e) {
      debugPrint('[NotifScheduler] _removeMultipleFromScheduledIds error: $e');
    }
  }

  static Future<void> _removeSmartAndCourseInactiveIds(
    Set<String> smartIds,
  ) async {
    try {
      final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
      final ids = Set<String>.from(
        box.get('scheduledIds', defaultValue: <String>[]) as List,
      );
      // إزالة smart IDs المعروفة
      ids.removeAll(smartIds);
      // [FIX #8] إزالة course_inactive IDs بـ pattern آمن:
      // يشترط البداية بـ 'course_' والنهاية بـ '_inactive' معاً
      // لمنع حذف خاطئ لـ courseId يحتوي على '_inactive' في اسمه
      ids.removeWhere(
        (id) => id.startsWith('course_') && id.endsWith('_inactive'),
      );
      await box.put('scheduledIds', ids.toList());
    } catch (e) {
      debugPrint('[NotifScheduler] _removeSmartAndCourseInactiveIds error: $e');
    }
  }

  static Future<void> _clearScheduledIds() async {
    try {
      final box = await Hive.openBox<dynamic>(kScheduledNotificationsBox);
      await box.put('scheduledIds', <String>[]);
    } catch (e) {
      debugPrint('[NotifScheduler] _clearScheduledIds error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private — Time Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// الوقت المفضل التالي بناءً على الإعدادات
  static DateTime? _nextPreferredTime(NotificationSettings settings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final candidates = <DateTime>[];

    if (settings.preferMorning) {
      candidates.add(today.add(const Duration(hours: 9)));
    }
    if (settings.preferAfternoon) {
      candidates.add(today.add(const Duration(hours: 13)));
    }
    if (settings.preferEvening) {
      candidates.add(today.add(const Duration(hours: 19)));
    }
    if (settings.preferNight) {
      candidates.add(today.add(const Duration(hours: 22)));
    }

    final future = candidates.where((t) => t.isAfter(now)).toList()..sort();
    return future.isEmpty ? null : future.first;
  }

  /// الوقت التالي للملخص الأسبوعي
  static DateTime? _nextWeeklyTime({
    required int targetWeekdayIndex, // 0=السبت...6=الجمعة (نظام التطبيق)
    required TimeOfDay targetTime,
  }) {
    final now = DateTime.now();
    for (var i = 0; i <= 7; i++) {
      final candidate = now.add(Duration(days: i));
      final appDay = NotificationSettings.dateTimeWeekdayToAppDay(
        candidate.weekday,
      );
      if (appDay == targetWeekdayIndex) {
        final dt = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          targetTime.hour,
          targetTime.minute,
        );
        if (dt.isAfter(now)) return dt;
      }
    }
    return null;
  }

  /// حساب الوقت حتى منتصف الليل
  static Duration _timeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return midnight.difference(now) + const Duration(minutes: 2);
  }

  /// تسمية وقت بشكل مقروء
  static String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// حساب تاريخ التكرار القادم بناءً على النوع والوقت الحالي
  static DateTime? _nextRecurringDate({
    required DateTime original,
    required RecurrenceType recurrenceType,
    required DateTime now,
  }) {
    final timeOfDay = TimeOfDay(
      hour: original.hour,
      minute: original.minute,
    );

    switch (recurrenceType) {
      case RecurrenceType.daily:
        // اليوم في نفس الوقت — إذا فات نأخذ الغد
        final todayOccurrence = DateTime(
          now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute,
        );
        if (todayOccurrence.isAfter(now)) return todayOccurrence;
        return todayOccurrence.add(const Duration(days: 1));

      case RecurrenceType.weekly:
        // نفس اليوم من الأسبوع القادم
        final targetWeekday = original.weekday;
        for (var i = 0; i <= 7; i++) {
          final candidate = DateTime(
            now.year, now.month, now.day + i,
            timeOfDay.hour, timeOfDay.minute,
          );
          if (candidate.weekday == targetWeekday &&
              candidate.isAfter(now)) {
            return candidate;
          }
        }
        return null;
    }
  }

  /// مفتاح التاريخ بصيغة 'yyyyMMdd' — لتمييز إشعارات نفس المهمة في أيام مختلفة
  static String _dateKey(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  /// مفتاح الأسبوع الحالي بصيغة 'yyyy-Www' — يتغير تلقائياً كل أسبوع
  static String _currentWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final weekNumber =
        ((now.difference(startOfYear).inDays + startOfYear.weekday) / 7)
            .ceil();
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}

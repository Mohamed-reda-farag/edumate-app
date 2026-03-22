import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/notification_history_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Channel IDs & Names
// ══════════════════════════════════════════════════════════════════════════════

const String kChannelTasks        = 'tasks';
const String kChannelMotivational = 'motivational';
const String kChannelAchievements = 'achievements';
const String kChannelSummaries    = 'summaries';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationService
// ══════════════════════════════════════════════════════════════════════════════

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback يُستدعى عند ضغط المستخدم على إشعار
  void Function(String? payload)? onNotificationTapped;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة timezone
    tz.initializeTimeZones();

    try {
      final String timezoneName = DateTime.now().timeZoneName;
      // timeZoneName قد يُرجع اختصاراً (مثل "EET") بدل الاسم الكامل
      // نحاول أولاً بالاسم المباشر، ثم نبحث في الـ database
      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
        debugPrint('[NotifService] Timezone set to: $timezoneName');
      } catch (_) {
        // timeZoneName اختصار غير معروف → نجرب تحديد الـ offset
        final offset      = DateTime.now().timeZoneOffset;
        final offsetHours = offset.inHours;
        // Egypt Standard Time = UTC+2 → Africa/Cairo
        // fallback مبني على الـ offset إذا فشل الاسم
        final fallbackByOffset = _timezoneByOffset(offsetHours);
        tz.setLocalLocation(tz.getLocation(fallbackByOffset));
        debugPrint('[NotifService] Timezone fallback by offset UTC+$offsetHours: $fallbackByOffset');
      }
    } catch (e) {
      // الـ fallback النهائي
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
        debugPrint('[NotifService] Timezone final fallback to Africa/Cairo');
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
        debugPrint('[NotifService] Timezone final fallback to UTC');
      }
    }

    // إعدادات Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // نطلبها يدوياً لاحقاً
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[NotifService] Tapped: ${details.payload}');
        onNotificationTapped?.call(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundNotifHandler,
    );

    // إنشاء channels على Android
    if (Platform.isAndroid) {
      await _createChannels();
    }

    _initialized = true;
    debugPrint('[NotifService] Initialized');
  }

  // ── Permission Request ─────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await plugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await plugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  // ── Android Channels ──────────────────────────────────────────────────────

  Future<void> _createChannels() async {
    final plugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) return;

    const channels = [
      AndroidNotificationChannel(
        kChannelTasks,
        'تذكير المهام',
        description: 'إشعارات تذكير المحاضرات وجلسات المذاكرة والكورسات',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        kChannelMotivational,
        'تحفيزية',
        description: 'إشعارات تحفيزية وتذكير الـ streak',
        importance: Importance.defaultImportance,
        enableVibration: false,
        playSound: false,
      ),
      AndroidNotificationChannel(
        kChannelAchievements,
        'الإنجازات',
        description: 'إشعارات فتح الإنجازات الجديدة',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        kChannelSummaries,
        'الملخصات',
        description: 'ملخصات يومية وأسبوعية',
        importance: Importance.defaultImportance,
        enableVibration: false,
        playSound: false,
      ),
    ];

    for (final channel in channels) {
      await plugin.createNotificationChannel(channel);
    }

    debugPrint('[NotifService] Android channels created');
  }

  // ── Show Immediate Notification ────────────────────────────────────────────

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
    bool vibrate = true,
    bool sound = true,
  }) async {
    if (!_initialized) await initialize();

    final details = _buildDetails(
      category: category,
      body: body,
      vibrate: vibrate,
      sound: sound,
    );

    await _plugin.show(id, title, body, details, payload: payload);
    debugPrint('[NotifService] Shown immediately: id=$id, title=$title');
  }

  // ── Schedule Notification ─────────────────────────────────────────────────

  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationCategory category,
    String? payload,
    bool vibrate = true,
    bool sound = true,
  }) async {
    if (!_initialized) await initialize();

    // لا نجدول إشعارات في الماضي
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('[NotifService] Skipped past notification: id=$id at $scheduledTime');
      return;
    }

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final details = _buildDetails(
      category: category,
      body: body,
      vibrate: vibrate,
      sound: sound,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('[NotifService] Scheduled: id=$id at $scheduledTime');
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    debugPrint('[NotifService] Cancelled: id=$id');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotifService] All notifications cancelled');
  }

  // ── Pending Notifications ─────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  // ── NotificationDetails Builder ───────────────────────────────────────────

  NotificationDetails _buildDetails({
    required NotificationCategory category,
    required String body,
    bool vibrate = true,
    bool sound = true,
  }) {
    final channelId = _categoryToChannelId(category);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelName(channelId),
      importance: _channelImportance(channelId),
      priority: Priority.high,
      enableVibration: vibrate,
      playSound: sound,
      styleInformation: BigTextStyleInformation(body),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _categoryToChannelId(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.tasks:
        return kChannelTasks;
      case NotificationCategory.motivational:
        return kChannelMotivational;
      case NotificationCategory.achievements:
        return kChannelAchievements;
      case NotificationCategory.summaries:
        return kChannelSummaries;
    }
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case kChannelTasks:
        return 'تذكير المهام';
      case kChannelMotivational:
        return 'تحفيزية';
      case kChannelAchievements:
        return 'الإنجازات';
      case kChannelSummaries:
        return 'الملخصات';
      default:
        return 'إشعارات';
    }
  }

  Importance _channelImportance(String channelId) {
    switch (channelId) {
      case kChannelTasks:
      case kChannelAchievements:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Timezone offset fallback helper
// ══════════════════════════════════════════════════════════════════════════════

/// يُرجع اسم timezone IANA شائع بناءً على UTC offset
/// يُستخدم كـ fallback عندما يُرجع timeZoneName اختصاراً غير معروف
String _timezoneByOffset(int offsetHours) {
  switch (offsetHours) {
    case -12: return 'Etc/GMT+12';
    case -11: return 'Pacific/Pago_Pago';
    case -10: return 'Pacific/Honolulu';
    case -9:  return 'America/Anchorage';
    case -8:  return 'America/Los_Angeles';
    case -7:  return 'America/Denver';
    case -6:  return 'America/Chicago';
    case -5:  return 'America/New_York';
    case -4:  return 'America/Halifax';
    case -3:  return 'America/Sao_Paulo';
    case -2:  return 'Etc/GMT+2';
    case -1:  return 'Atlantic/Azores';
    case 0:   return 'Europe/London';
    case 1:   return 'Europe/Paris';
    case 2:   return 'Africa/Cairo';
    case 3:   return 'Asia/Riyadh';
    case 4:   return 'Asia/Dubai';
    case 5:   return 'Asia/Karachi';
    case 6:   return 'Asia/Dhaka';
    case 7:   return 'Asia/Bangkok';
    case 8:   return 'Asia/Shanghai';
    case 9:   return 'Asia/Tokyo';
    case 10:  return 'Australia/Sydney';
    case 11:  return 'Pacific/Noumea';
    case 12:  return 'Pacific/Auckland';
    default:  return 'Africa/Cairo';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Background handler (top-level function — مطلوب لـ Flutter Local Notifications)
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
void _backgroundNotifHandler(NotificationResponse details) {
  // يمكن معالجة tap في الـ background هنا إذا لزم
  debugPrint('[NotifService] Background tap: ${details.payload}');
}

// ══════════════════════════════════════════════════════════════════════════════
// NotificationIdHelper — تحويل String ID → int ID بشكل ثابت عبر الجلسات
// ══════════════════════════════════════════════════════════════════════════════

/// كل إشعار له String ID منطقي (مثل 'lec_abc_before')
/// يُحوَّل إلى int باستخدام Jenkins hash ثابت بين جلسات التطبيق
///
/// سبب تغيير hashCode → Jenkins:
/// String.hashCode في Dart غير مضمون الثبات عبر جلسات مختلفة (في release mode
/// تُطبَّق hash randomization) مما يجعل cancel(id) يُلغي إشعاراً خاطئاً
/// أو لا يُلغي شيئاً إطلاقاً بعد إعادة تشغيل التطبيق.
class NotificationIdHelper {
  NotificationIdHelper._();

  /// Jenkins one-at-a-time hash — ثابت عبر كل الجلسات والمنصات
  static int toInt(String notificationId) {
    var hash = 0;
    for (final unit in notificationId.codeUnits) {
      hash = (hash + unit) & 0xFFFFFFFF;
      hash = (hash + (hash << 10)) & 0xFFFFFFFF;
      hash ^= (hash >> 6);
    }
    hash = (hash + (hash << 3)) & 0xFFFFFFFF;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & 0xFFFFFFFF;
    // نضمن أن النتيجة موجبة وداخل حدود int المسموح لـ Android notification id
    return hash.abs() % 2147483647;
  }
}
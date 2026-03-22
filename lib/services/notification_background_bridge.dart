import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Keys
// ══════════════════════════════════════════════════════════════════════════════

const String _kUserDataKey       = 'notif_bridge_user_data';
const String _kTodaySummaryKey   = 'notif_bridge_today_summary';
const String _kCompletedCountKey = 'notif_bridge_completed_count';

// ══════════════════════════════════════════════════════════════════════════════
// Schema Version
// ══════════════════════════════════════════════════════════════════════════════

// versioning: أي تغيير في schema يستوجب رفع هذا الرقم.
// عند التحميل، إذا كان version في البيانات أقل من القيمة الحالية
// → تُتجاهل البيانات القديمة وتُعاد الكتابة من الـ foreground.
// هذا يمنع crash المستخدمين القدامى بعد أي app update يغيّر البنية.
const int _kCurrentSchemaVersion = 1;

// ══════════════════════════════════════════════════════════════════════════════
// Debounce helper (للـ saveUserData عند كل تغيير في الإعدادات)
// ══════════════════════════════════════════════════════════════════════════════

// debounce: يمنع كتابة SharedPreferences عند كل keystroke في الإعدادات.
// مثال: المستخدم يضغط على 5 أيام بسرعة → 5 كتابات متتالية بدون debounce.
// مع debounce: ينتظر 500ms بعد آخر ضغطة ثم يكتب مرة واحدة.
Timer? _saveDebounceTimer;

// ══════════════════════════════════════════════════════════════════════════════
// NotificationBridgeData — البيانات المحفوظة للـ background
// ══════════════════════════════════════════════════════════════════════════════

class NotificationBridgeData {
  final String userId;
  final NotificationSettings settings;
  final List<String> activeCourseIds;

  /// courseId → lastAccessedAt (ISO string)
  final Map<String, String> courseLastAccess;

  final int currentStreak;

  /// 'morning' | 'afternoon' | 'evening' | 'night' → bool
  final Map<String, bool> preferredTimes;

  // schemaVersion: يُحفظ مع البيانات لاكتشاف schema قديم عند التحميل
  final int schemaVersion;

  const NotificationBridgeData({
    required this.userId,
    required this.settings,
    required this.activeCourseIds,
    required this.courseLastAccess,
    required this.currentStreak,
    required this.preferredTimes,
    this.schemaVersion = _kCurrentSchemaVersion,
  });

  Map<String, dynamic> toJson() => {
        'version': schemaVersion,
        'userId': userId,
        'settings': settings.toJson(),
        'activeCourseIds': activeCourseIds,
        'courseLastAccess': courseLastAccess,
        'currentStreak': currentStreak,
        'preferredTimes': preferredTimes,
      };

  // fromJson: تغليف كل cast خطير بـ safe helpers مع fallback آمن
  // بدل crash في background عند بيانات تالفة أو schema قديم
  factory NotificationBridgeData.fromJson(Map<String, dynamic> json) {
    List<String> safeStringList(dynamic raw) {
      if (raw is List) return raw.whereType<String>().toList();
      return [];
    }

    Map<String, String> safeStringStringMap(dynamic raw) {
      if (raw is Map) {
        return Map.fromEntries(
          raw.entries
              .where((e) => e.key is String && e.value is String)
              .map((e) => MapEntry(e.key as String, e.value as String)),
        );
      }
      return {};
    }

    Map<String, bool> safeStringBoolMap(dynamic raw) {
      if (raw is Map) {
        return Map.fromEntries(
          raw.entries
              .where((e) => e.key is String && e.value is bool)
              .map((e) => MapEntry(e.key as String, e.value as bool)),
        );
      }
      return {};
    }

    NotificationSettings safeSettings(dynamic raw) {
      try {
        if (raw is Map<String, dynamic>) {
          return NotificationSettings.fromJson(raw);
        }
      } catch (_) {}
      return NotificationSettings.defaults();
    }

    return NotificationBridgeData(
      schemaVersion:    json['version']      as int?    ?? 0,
      userId:           json['userId']        as String? ?? '',
      settings:         safeSettings(json['settings']),
      activeCourseIds:  safeStringList(json['activeCourseIds']),
      courseLastAccess: safeStringStringMap(json['courseLastAccess']),
      currentStreak:    json['currentStreak'] as int?    ?? 0,
      preferredTimes:   safeStringBoolMap(json['preferredTimes']),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TodayTasksSummary — ملخص مهام اليوم
// ══════════════════════════════════════════════════════════════════════════════

class TodayTasksSummary {
  final int lectureCount;
  final int studySessionCount;
  final int courseTaskCount;

  const TodayTasksSummary({
    this.lectureCount = 0,
    this.studySessionCount = 0,
    this.courseTaskCount = 0,
  });

  int get totalCount => lectureCount + studySessionCount + courseTaskCount;

  bool get isEmpty => totalCount == 0;

  Map<String, dynamic> toJson() => {
        'lectureCount': lectureCount,
        'studySessionCount': studySessionCount,
        'courseTaskCount': courseTaskCount,
      };

  factory TodayTasksSummary.fromJson(Map<String, dynamic> json) {
    return TodayTasksSummary(
      lectureCount:      json['lectureCount']      as int? ?? 0,
      studySessionCount: json['studySessionCount'] as int? ?? 0,
      courseTaskCount:   json['courseTaskCount']   as int? ?? 0,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CompletedCountData — عداد المهام المكتملة (للملخص المسائي)
// ══════════════════════════════════════════════════════════════════════════════

class CompletedCountData {
  final int completedLectures;
  final int completedStudySessions;
  final int completedLessons;
  final int pendingCount;

  const CompletedCountData({
    this.completedLectures = 0,
    this.completedStudySessions = 0,
    this.completedLessons = 0,
    this.pendingCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'completedLectures': completedLectures,
        'completedStudySessions': completedStudySessions,
        'completedLessons': completedLessons,
        'pendingCount': pendingCount,
      };

  factory CompletedCountData.fromJson(Map<String, dynamic> json) {
    return CompletedCountData(
      completedLectures:      json['completedLectures']      as int? ?? 0,
      completedStudySessions: json['completedStudySessions'] as int? ?? 0,
      completedLessons:       json['completedLessons']       as int? ?? 0,
      pendingCount:           json['pendingCount']           as int? ?? 0,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NotificationBackgroundBridge
// ══════════════════════════════════════════════════════════════════════════════

class NotificationBackgroundBridge {
  NotificationBackgroundBridge._();

  // ── Save user data ─────────────────────────────────────────────────────────

  static Future<void> saveUserData({
    required String userId,
    required NotificationSettings settings,
    required List<String> activeCourseIds,
    required Map<String, DateTime> courseLastAccess,
    required int currentStreak,
    required Map<String, bool> preferredTimes,
    bool debounce = false,
  }) async {
    if (debounce) {
      _saveDebounceTimer?.cancel();
      _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _doSaveUserData(
          userId: userId,
          settings: settings,
          activeCourseIds: activeCourseIds,
          courseLastAccess: courseLastAccess,
          currentStreak: currentStreak,
          preferredTimes: preferredTimes,
        );
        // لا نحتاج await هنا — _doSaveUserData تتعامل مع الأخطاء داخلياً
      });
      return; // عودة فورية — الكتابة ستحدث بعد 500ms
    }

    // كتابة فورية (onLogin أو أي استدعاء حرج)
    // نلغي أي debounce معلق لضمان عدم الكتابة مرتين
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    await _doSaveUserData(
      userId: userId,
      settings: settings,
      activeCourseIds: activeCourseIds,
      courseLastAccess: courseLastAccess,
      currentStreak: currentStreak,
      preferredTimes: preferredTimes,
    );
  }

  static Future<void> _doSaveUserData({
    required String userId,
    required NotificationSettings settings,
    required List<String> activeCourseIds,
    required Map<String, DateTime> courseLastAccess,
    required int currentStreak,
    required Map<String, bool> preferredTimes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = NotificationBridgeData(
        userId: userId,
        settings: settings,
        activeCourseIds: activeCourseIds,
        courseLastAccess: courseLastAccess.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        currentStreak: currentStreak,
        preferredTimes: preferredTimes,
        schemaVersion: _kCurrentSchemaVersion,
      );

      await prefs.setString(_kUserDataKey, jsonEncode(data.toJson()));
      debugPrint(
        '[NotifBridge] User data saved for $userId '
        '(v$_kCurrentSchemaVersion, '
        '${activeCourseIds.length} courses, '
        'streak=$currentStreak)',
      );
    } catch (e) {
      debugPrint('[NotifBridge] _doSaveUserData error: $e');
    }
  }

  /// يُستدعى من callbackDispatcher في الـ background.
  /// يرفض البيانات من schema قديم ويُرجع null — يتعامل معها الـ scheduler
  /// كـ "لا بيانات" ويتخطى الإشعارات بأمان بدل crash.
  static Future<NotificationBridgeData?> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUserDataKey);
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;

      // رفض بيانات schema قديمة بدل crash أو سلوك غير متوقع
      final version = json['version'] as int? ?? 0;
      if (version < _kCurrentSchemaVersion) {
        debugPrint(
          '[NotifBridge] loadUserData: stale schema v$version '
          '(current: $_kCurrentSchemaVersion) — ignoring',
        );
        return null;
      }

      return NotificationBridgeData.fromJson(json);
    } catch (e) {
      debugPrint('[NotifBridge] loadUserData error: $e');
      return null;
    }
  }

  // ── Today Tasks Summary ────────────────────────────────────────────────────

  /// يُستدعى عند كل sync لتحديث ملخص مهام اليوم (للملخص الصباحي)
  static Future<void> saveTodayTasksSummary({
    required int lectureCount,
    required int studySessionCount,
    required int courseTaskCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summary = TodayTasksSummary(
        lectureCount: lectureCount,
        studySessionCount: studySessionCount,
        courseTaskCount: courseTaskCount,
      );
      await prefs.setString(_kTodaySummaryKey, jsonEncode(summary.toJson()));
      debugPrint('[NotifBridge] Today summary saved: ${summary.totalCount} tasks');
    } catch (e) {
      debugPrint('[NotifBridge] saveTodayTasksSummary error: $e');
    }
  }

  static Future<TodayTasksSummary> loadTodayTasksSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kTodaySummaryKey);
      if (raw == null) return const TodayTasksSummary();
      return TodayTasksSummary.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[NotifBridge] loadTodayTasksSummary error: $e');
      return const TodayTasksSummary();
    }
  }

  // ── Completed Count ────────────────────────────────────────────────────────

  /// يُستدعى عند إكمال أي مهمة لتحديث عداد الإنجازات (للملخص المسائي)
  static Future<void> updateCompletedCount({
    required int completedLectures,
    required int completedStudySessions,
    required int completedLessons,
    required int pendingCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = CompletedCountData(
        completedLectures: completedLectures,
        completedStudySessions: completedStudySessions,
        completedLessons: completedLessons,
        pendingCount: pendingCount,
      );
      await prefs.setString(_kCompletedCountKey, jsonEncode(data.toJson()));
      debugPrint('[NotifBridge] Completed count updated');
    } catch (e) {
      debugPrint('[NotifBridge] updateCompletedCount error: $e');
    }
  }

  static Future<CompletedCountData> loadCompletedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCompletedCountKey);
      if (raw == null) return const CompletedCountData();
      return CompletedCountData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[NotifBridge] loadCompletedCount error: $e');
      return const CompletedCountData();
    }
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  /// يُستدعى عند تسجيل الخروج.
  /// يُلغي أي debounce معلق أولاً لمنع كتابة بيانات المستخدم القديم
  /// بعد مسح الـ bridge.
  static Future<void> clear() async {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_kUserDataKey),
        prefs.remove(_kTodaySummaryKey),
        prefs.remove(_kCompletedCountKey),
      ]);
      debugPrint('[NotifBridge] Bridge data cleared');
    } catch (e) {
      debugPrint('[NotifBridge] clear error: $e');
    }
  }
}
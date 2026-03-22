import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/notification_settings_model.dart';
import '../models/notification_history_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationRepository
// ══════════════════════════════════════════════════════════════════════════════

class NotificationRepository {
  NotificationRepository({
    required FirebaseFirestore firestore,
    required String Function() getUserId,
  })  : _firestore = firestore,
        _getUserId = getUserId;

  final FirebaseFirestore _firestore;
  final String Function() _getUserId;

  // ── userId ──────────────────────────────────────────────────────────────────

  String get _userId {
    final id = _getUserId();
    if (id.isEmpty) {
      throw StateError(
          '[NotificationRepository] userId is empty — user not signed in.');
    }
    return id;
  }

  // ── Firestore refs ──────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.doc('users/$_userId/notification_meta/settings');

  // ══════════════════════════════════════════════════════════════════════════
  //  Settings — Firestore (persist across devices)
  // ══════════════════════════════════════════════════════════════════════════

  /// جلب إعدادات الإشعارات من Firestore
  Future<NotificationSettings> getSettings() async {
    try {
      final snap = await _settingsDoc.get();
      if (snap.exists && snap.data() != null) {
        return NotificationSettings.fromJson(snap.data()!);
      }
      return NotificationSettings.defaults();
    } catch (e) {
      debugPrint('[NotifRepo] getSettings error: $e');
      return NotificationSettings.defaults();
    }
  }

  /// حفظ إعدادات الإشعارات في Firestore
  /// SetOptions(merge: true) يمنع حذف حقول مستقبلية غير موجودة في النموذج الحالي
  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      await _settingsDoc.set(settings.toJson(), SetOptions(merge: true));
      debugPrint('[NotifRepo] Settings saved');
    } catch (e) {
      debugPrint('[NotifRepo] saveSettings error: $e');
      rethrow;
    }
  }

  /// Stream مباشر للإعدادات (يُستخدم لمزامنة عبر الأجهزة)
  Stream<NotificationSettings> watchSettings() {
    return _settingsDoc.snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return NotificationSettings.fromJson(snap.data()!);
      }
      return NotificationSettings.defaults();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  History — Hive (local only, max 50 items FIFO)
  // ══════════════════════════════════════════════════════════════════════════

  Future<Box<NotificationHistoryItem>> _openHistoryBox() async {
    if (Hive.isBoxOpen(kNotificationHistoryBox)) {
      return Hive.box<NotificationHistoryItem>(kNotificationHistoryBox);
    }
    return Hive.openBox<NotificationHistoryItem>(kNotificationHistoryBox);
  }

  /// جلب كل سجل الإشعارات (مرتب من الأحدث للأقدم)
  Future<List<NotificationHistoryItem>> getHistory() async {
    try {
      final box = await _openHistoryBox();
      final items = box.values.toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return items;
    } catch (e) {
      debugPrint('[NotifRepo] getHistory error: $e');
      return [];
    }
  }

  /// إضافة إشعار للسجل (FIFO — يحذف الأقدم إذا تجاوز الحد الأقصى)
  Future<void> addToHistory(NotificationHistoryItem item) async {
    try {
      final box = await _openHistoryBox();

      if (box.length >= kMaxHistoryItems) {
        // رتّب مرة واحدة من الأقدم للأحدث
        final sorted = box.values.toList()
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

        // احذف كل الزائد دفعةً واحدة بدل loop متسلسل
        final deleteCount = box.length - kMaxHistoryItems + 1;
        final toDelete = sorted.take(deleteCount).toList();
        await Future.wait(toDelete.map((e) => e.delete()));
      }

      await box.put(item.id, item);
      debugPrint('[NotifRepo] Added to history: ${item.title}');
    } catch (e) {
      debugPrint('[NotifRepo] addToHistory error: $e');
    }
  }

  /// تحديد إشعار كمقروء في Hive
  /// ملاحظة: mutation مباشرة على كائن Hive هنا مقصودة — هذه طبقة البيانات.
  /// الـ Controller هو المسؤول عن بناء كائن جديد للـ UI عبر copyWith.
  Future<void> markAsRead(String itemId) async {
    try {
      final box = await _openHistoryBox();
      final item = box.get(itemId);
      if (item != null && !item.wasRead) {
        item.wasRead = true;
        await item.save();
      }
    } catch (e) {
      debugPrint('[NotifRepo] markAsRead error: $e');
    }
  }

  /// تحديد كل الإشعارات كمقروءة
  /// Future.wait: N writes متوازية بدل N writes متسلسلة
  Future<void> markAllAsRead() async {
    try {
      final box = await _openHistoryBox();
      final unread = box.values.where((item) => !item.wasRead).toList();
      if (unread.isEmpty) return;

      for (final item in unread) {
        item.wasRead = true;
      }
      await Future.wait(unread.map((item) => item.save()));

      debugPrint(
          '[NotifRepo] All notifications marked as read (${unread.length})');
    } catch (e) {
      debugPrint('[NotifRepo] markAllAsRead error: $e');
    }
  }

  /// عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    try {
      final box = await _openHistoryBox();
      return box.values.where((item) => !item.wasRead).length;
    } catch (e) {
      debugPrint('[NotifRepo] getUnreadCount error: $e');
      return 0;
    }
  }

  /// مسح كل السجل
  Future<void> clearHistory() async {
    try {
      final box = await _openHistoryBox();
      await box.clear();
      debugPrint('[NotifRepo] History cleared');
    } catch (e) {
      debugPrint('[NotifRepo] clearHistory error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Weekly Summary — Firestore (يُحسب مرة أسبوعياً)
  // ══════════════════════════════════════════════════════════════════════════

  DocumentReference<Map<String, dynamic>> get _weeklyStatsDoc =>
      _firestore.doc('users/$_userId/notification_meta/weekly_stats');

  /// جلب إحصائيات الأسبوع للملخص الأسبوعي
  Future<WeeklySummaryData?> getWeeklySummary() async {
    try {
      final snap = await _weeklyStatsDoc.get();
      if (snap.exists && snap.data() != null) {
        return WeeklySummaryData.fromJson(snap.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('[NotifRepo] getWeeklySummary error: $e');
      return null;
    }
  }

  /// حفظ ملخص الأسبوع
  /// SetOptions(merge: true) لمنع حذف حقول مستقبلية
  Future<void> saveWeeklySummary(WeeklySummaryData data) async {
    try {
      await _weeklyStatsDoc.set(data.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[NotifRepo] saveWeeklySummary error: $e');
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WeeklySummaryData
// ══════════════════════════════════════════════════════════════════════════════

class WeeklySummaryData {
  final int completedTasks;
  final int totalTasks;
  final double studyHours;
  final int streakDays;
  final DateTime weekStart;

  const WeeklySummaryData({
    required this.completedTasks,
    required this.totalTasks,
    required this.studyHours,
    required this.streakDays,
    required this.weekStart,
  });

  Map<String, dynamic> toJson() => {
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
        'studyHours': studyHours,
        'streakDays': streakDays,
        'weekStart': Timestamp.fromDate(weekStart),
      };

  factory WeeklySummaryData.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryData(
      completedTasks: json['completedTasks'] as int? ?? 0,
      totalTasks:     json['totalTasks']     as int? ?? 0,
      studyHours:     (json['studyHours'] as num?)?.toDouble() ?? 0.0,
      streakDays:     json['streakDays']     as int? ?? 0,
      weekStart: json['weekStart'] is Timestamp
          ? (json['weekStart'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
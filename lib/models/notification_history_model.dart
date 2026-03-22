import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationCategory enum
// ══════════════════════════════════════════════════════════════════════════════

enum NotificationCategory {
  tasks,        // مهام
  motivational, // تحفيزية
  achievements, // إنجازات
  summaries,    // ملخصات
}

extension NotificationCategoryX on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.tasks:
        return 'مهام';
      case NotificationCategory.motivational:
        return 'تحفيزية';
      case NotificationCategory.achievements:
        return 'إنجازات';
      case NotificationCategory.summaries:
        return 'ملخصات';
    }
  }

  String get icon {
    switch (this) {
      case NotificationCategory.tasks:
        return '📋';
      case NotificationCategory.motivational:
        return '🔥';
      case NotificationCategory.achievements:
        return '🏆';
      case NotificationCategory.summaries:
        return '📊';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NotificationHistoryItem — Hive Model
// ══════════════════════════════════════════════════════════════════════════════

/// يُحفظ في Hive box: 'notification_history'
/// آخر 50 إشعار فقط (FIFO — الأقدم يُحذف أولاً)
@HiveType(typeId: 10)
class NotificationHistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final String categoryName; // اسم NotificationCategory.name

  @HiveField(4)
  final DateTime sentAt;

  @HiveField(5)
  bool wasRead;

  @HiveField(6)
  final String? payload; // JSON string للـ navigation

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.categoryName,
    required this.sentAt,
    this.wasRead = false,
    this.payload,
  });

  NotificationCategory get category {
    return NotificationCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => NotificationCategory.tasks,
    );
  }

  // ── copyWith ───────────────────────────────────────────────────────────────
  NotificationHistoryItem copyWith({bool? wasRead}) {
    return NotificationHistoryItem(
      id: id,
      title: title,
      body: body,
      categoryName: categoryName,
      sentAt: sentAt,
      wasRead: wasRead ?? this.wasRead,
      payload: payload,
    );
  }

  /// وقت نسبي بالعربية (منذ كم؟)
  ///
  /// [FIX #11] تصحيح صياغة الساعات — كانت "منذ 5 ساعة" بدل "منذ 5 ساعات"
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(sentAt);

    if (diff.isNegative) return 'الآن';
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      // 1 دقيقة / 2-10 دقائق / 11+ دقيقة
      final word = m == 1 ? 'دقيقة' : (m <= 10 ? 'دقائق' : 'دقيقة');
      return 'منذ $m $word';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      // 1 ساعة / 2-10 ساعات / 11+ ساعة
      final word = h == 1 ? 'ساعة' : (h <= 10 ? 'ساعات' : 'ساعة');
      return 'منذ $h $word';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      final word = d == 1 ? 'يوم' : (d <= 10 ? 'أيام' : 'يوم');
      return 'منذ $d $word';
    }
    return _formatDate(sentAt);
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'categoryName': categoryName,
        'sentAt': sentAt.toIso8601String(),
        'wasRead': wasRead,
        'payload': payload,
      };

  // fromJson: تغليف DateTime.parse بـ try-catch لمنع crash عند بيانات تالفة
  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedSentAt;
    try {
      parsedSentAt = DateTime.parse(json['sentAt'] as String? ?? '');
    } catch (_) {
      parsedSentAt = DateTime.now();
      debugPrint(
        '[NotificationHistoryItem.fromJson] failed to parse sentAt: '
        '${json['sentAt']} — using now()',
      );
    }

    return NotificationHistoryItem(
      id:           json['id']           as String? ?? '',
      title:        json['title']        as String? ?? '',
      body:         json['body']         as String? ?? '',
      categoryName: json['categoryName'] as String? ?? NotificationCategory.tasks.name,
      sentAt:       parsedSentAt,
      wasRead:      json['wasRead']      as bool?   ?? false,
      payload:      json['payload']      as String?,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Hive Adapter — يجب تسجيله في main.dart
// ══════════════════════════════════════════════════════════════════════════════

/// ⚠️ ملاحظة للمطور — تغيير تخزين sentAt (field[4]):
///
/// القديم: sentAt يُخزَّن كـ String (ISO 8601) ويُقرأ بـ DateTime.parse()
/// الجديد: sentAt يُخزَّن كـ DateTime مباشرة — Hive يدعم DateTime natively
///         بدون overhead التحويل ودون الحاجة لـ try-catch.
///
/// هذا التغيير يكسر التوافق مع البيانات المخزنة بالصيغة القديمة (String).
///
/// إذا كان التطبيق في مرحلة التطوير (لا بيانات مستخدمين حقيقيين) →
///   طبّق التغيير مباشرة، لا حاجة لأي migration.
///
/// إذا كان التطبيق في production (بيانات مستخدمين موجودة) →
///   الـ read() يتعامل مع كلا الصيغتين تلقائياً (DateTime أو String)
///   للتوافق مع البيانات القديمة. الـ write() يكتب DateTime فقط.
///   بعد أول قراءة/كتابة لكل item، تصبح بياناته بالصيغة الجديدة تلقائياً.
class NotificationHistoryItemAdapter
    extends TypeAdapter<NotificationHistoryItem> {
  @override
  final int typeId = 10;

  @override
  NotificationHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawSentAt = fields[4];
    DateTime parsedSentAt;
    if (rawSentAt is DateTime) {
      parsedSentAt = rawSentAt;
    } else {
      try {
        parsedSentAt = DateTime.parse(rawSentAt as String? ?? '');
      } catch (_) {
        parsedSentAt = DateTime.now();
        debugPrint(
          '[NotificationHistoryItemAdapter.read] failed to parse sentAt '
          'field[4]: $rawSentAt — using now()',
        );
      }
    }

    return NotificationHistoryItem(
      id:           fields[0] as String? ?? '',
      title:        fields[1] as String? ?? '',
      body:         fields[2] as String? ?? '',
      categoryName: fields[3] as String? ?? NotificationCategory.tasks.name,
      sentAt:       parsedSentAt,
      wasRead:      fields[5] as bool?   ?? false,
      payload:      fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationHistoryItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.categoryName)
      ..writeByte(4)
      ..write(obj.sentAt)
      ..writeByte(5)
      ..write(obj.wasRead)
      ..writeByte(6)
      ..write(obj.payload);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Constants
// ══════════════════════════════════════════════════════════════════════════════

const String kNotificationHistoryBox    = 'notification_history';
const String kScheduledNotificationsBox = 'scheduled_notifications';
const int    kMaxHistoryItems           = 50;
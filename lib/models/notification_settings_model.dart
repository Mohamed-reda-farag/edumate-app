import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationSettings — نموذج إعدادات الإشعارات الكاملة
// ══════════════════════════════════════════════════════════════════════════════

class NotificationSettings {
  // ── تفعيل عام ──────────────────────────────────────────────────────────────
  final bool isEnabled;

  // ── أنواع الإشعارات ────────────────────────────────────────────────────────
  final bool taskReminders;  // تذكير بالمهام (محاضرات + مذاكرة + كورسات + مخصصة)
  final bool motivational;   // تحفيزية (streak + تقدم المهارة + هدف اليوم)
  final bool achievements;   // إنجازات
  final bool summaries;      // ملخصات (صباحي + مسائي + أسبوعي)

  // ── التوقيت المفضل (للإشعارات الذكية) ────────────────────────────────────
  final bool preferMorning;   // صباحاً  → 9:00 AM
  final bool preferAfternoon; // ظهراً   → 1:00 PM
  final bool preferEvening;   // مساءً   → 7:00 PM
  final bool preferNight;     // ليلاً   → 10:00 PM

  // ── أيام التعلم المفضلة ───────────────────────────────────────────────────
  final List<int> preferredDays;

  // ── إعدادات تذكير المحاضرات ────────────────────────────────────────────────
  final int lectureReminderMinutes; // 15-60 دقيقة، افتراضي 30

  // ── توقيت الملخصات ────────────────────────────────────────────────────────
  final TimeOfDay morningDigestTime; // افتراضي 8:00 AM
  final TimeOfDay eveningDigestTime; // افتراضي 9:00 PM
  final int weeklyDigestDay;         // 0-6، افتراضي 0 (السبت)
  final TimeOfDay weeklyDigestTime;  // افتراضي 6:00 PM

  // ── الصوت والاهتزاز ───────────────────────────────────────────────────────
  final bool vibrate;
  final bool sound;

  const NotificationSettings({
    this.isEnabled = true,
    this.taskReminders = true,
    this.motivational = true,
    this.achievements = true,
    this.summaries = true,
    this.preferMorning = true,
    this.preferAfternoon = false,
    this.preferEvening = false,
    this.preferNight = false,
    this.preferredDays = const [0, 1, 2, 3, 4, 5, 6],
    this.lectureReminderMinutes = 30,
    this.morningDigestTime = const TimeOfDay(hour: 8, minute: 0),
    this.eveningDigestTime = const TimeOfDay(hour: 21, minute: 0),
    this.weeklyDigestDay = 0,
    this.weeklyDigestTime = const TimeOfDay(hour: 18, minute: 0),
    this.vibrate = true,
    this.sound = true,
  });

  // ── Defaults factory ──────────────────────────────────────────────────────
  factory NotificationSettings.defaults() => const NotificationSettings();

  // ── Serialization ─────────────────────────────────────────────────────────

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final rawMinutes = json['lectureReminderMinutes'] as int? ?? 30;
    final clampedMinutes = rawMinutes.clamp(15, 60);

    final rawWeeklyDay = json['weeklyDigestDay'] as int? ?? 0;
    final validWeeklyDay =
        (rawWeeklyDay >= 0 && rawWeeklyDay <= 6) ? rawWeeklyDay : 0;

    final rawDays = (json['preferredDays'] as List<dynamic>?)
            ?.map((e) => e as int)
            .where((d) => d >= 0 && d <= 6)
            .toList() ??
        const [0, 1, 2, 3, 4, 5, 6];
    final validDays =
        rawDays.isNotEmpty ? rawDays : const [0, 1, 2, 3, 4, 5, 6];

    return NotificationSettings(
      isEnabled:      json['isEnabled']      as bool? ?? true,
      taskReminders:  json['taskReminders']  as bool? ?? true,
      motivational:   json['motivational']   as bool? ?? true,
      achievements:   json['achievements']   as bool? ?? true,
      summaries:      json['summaries']      as bool? ?? true,
      preferMorning:  json['preferMorning']  as bool? ?? true,
      preferAfternoon: json['preferAfternoon'] as bool? ?? false,
      preferEvening:  json['preferEvening']  as bool? ?? false,
      preferNight:    json['preferNight']    as bool? ?? false,
      preferredDays:  validDays,
      lectureReminderMinutes: clampedMinutes,
      morningDigestTime: _timeFromJson(json['morningDigestTime']) ??
          const TimeOfDay(hour: 8, minute: 0),
      eveningDigestTime: _timeFromJson(json['eveningDigestTime']) ??
          const TimeOfDay(hour: 21, minute: 0),
      weeklyDigestDay:  validWeeklyDay,
      weeklyDigestTime: _timeFromJson(json['weeklyDigestTime']) ??
          const TimeOfDay(hour: 18, minute: 0),
      vibrate: json['vibrate'] as bool? ?? true,
      sound:   json['sound']   as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled':      isEnabled,
        'taskReminders':  taskReminders,
        'motivational':   motivational,
        'achievements':   achievements,
        'summaries':      summaries,
        'preferMorning':  preferMorning,
        'preferAfternoon': preferAfternoon,
        'preferEvening':  preferEvening,
        'preferNight':    preferNight,
        'preferredDays':  preferredDays,
        'lectureReminderMinutes': lectureReminderMinutes,
        'morningDigestTime': _timeToJson(morningDigestTime),
        'eveningDigestTime': _timeToJson(eveningDigestTime),
        'weeklyDigestDay':  weeklyDigestDay,
        'weeklyDigestTime': _timeToJson(weeklyDigestTime),
        'vibrate': vibrate,
        'sound':   sound,
      };

  // ── copyWith ───────────────────────────────────────────────────────────────

  NotificationSettings copyWith({
    bool? isEnabled,
    bool? taskReminders,
    bool? motivational,
    bool? achievements,
    bool? summaries,
    bool? preferMorning,
    bool? preferAfternoon,
    bool? preferEvening,
    bool? preferNight,
    List<int>? preferredDays,
    int? lectureReminderMinutes,
    TimeOfDay? morningDigestTime,
    TimeOfDay? eveningDigestTime,
    int? weeklyDigestDay,
    TimeOfDay? weeklyDigestTime,
    bool? vibrate,
    bool? sound,
  }) {
    return NotificationSettings(
      isEnabled:      isEnabled      ?? this.isEnabled,
      taskReminders:  taskReminders  ?? this.taskReminders,
      motivational:   motivational   ?? this.motivational,
      achievements:   achievements   ?? this.achievements,
      summaries:      summaries      ?? this.summaries,
      preferMorning:  preferMorning  ?? this.preferMorning,
      preferAfternoon: preferAfternoon ?? this.preferAfternoon,
      preferEvening:  preferEvening  ?? this.preferEvening,
      preferNight:    preferNight    ?? this.preferNight,
      preferredDays:  preferredDays  ?? this.preferredDays,
      lectureReminderMinutes:
          lectureReminderMinutes ?? this.lectureReminderMinutes,
      morningDigestTime: morningDigestTime ?? this.morningDigestTime,
      eveningDigestTime: eveningDigestTime ?? this.eveningDigestTime,
      weeklyDigestDay:  weeklyDigestDay  ?? this.weeklyDigestDay,
      weeklyDigestTime: weeklyDigestTime ?? this.weeklyDigestTime,
      vibrate: vibrate ?? this.vibrate,
      sound:   sound   ?? this.sound,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, bool> toPreferredTimesMap() => {
        'morning':   preferMorning,
        'afternoon': preferAfternoon,
        'evening':   preferEvening,
        'night':     preferNight,
      };

  /// هل يوجد وقت مفضل محدد على الأقل؟
  bool get hasAnyPreferredTime =>
      preferMorning || preferAfternoon || preferEvening || preferNight;

  /// [FIX #12] هل يوجد يوم تعلم مفضل محدد على الأقل؟
  ///
  /// يُستخدم في الـ scheduler للتحقق قبل جدولة تذكير أيام التعلم،
  /// ويوازي hasAnyPreferredTime في الاستخدام.
  bool get hasAnyPreferredDay => preferredDays.isNotEmpty;

  /// تحويل يوم التطبيق (0=السبت) إلى DateTime.weekday (1=الاثنين..7=الأحد)
  /// الجدول:
  ///   0=السبت   → DateTime.saturday  = 6
  ///   1=الأحد   → DateTime.sunday    = 7
  ///   2=الاثنين → DateTime.monday    = 1
  ///   3=الثلاثاء → DateTime.tuesday  = 2
  ///   4=الأربعاء → DateTime.wednesday = 3
  ///   5=الخميس  → DateTime.thursday  = 4
  ///   6=الجمعة  → DateTime.friday    = 5
  static int appDayToDateTimeWeekday(int appDay) {
    const mapping = [6, 7, 1, 2, 3, 4, 5]; // index = appDay
    if (appDay >= 0 && appDay < mapping.length) return mapping[appDay];
    return -1; // قيمة غير صالحة
  }

  /// تحويل DateTime.weekday إلى يوم التطبيق (0=السبت)
  static int dateTimeWeekdayToAppDay(int weekday) {
    // weekday: 1=Mon,2=Tue,3=Wed,4=Thu,5=Fri,6=Sat,7=Sun
    const mapping = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
    return mapping[weekday] ?? -1;
  }

  /// هل اليوم المعطى (DateTime) موجود في preferredDays؟
  bool isDayPreferred(DateTime date) {
    final appDay = dateTimeWeekdayToAppDay(date.weekday);
    return preferredDays.contains(appDay);
  }

  /// اسم يوم الأسبوع بالعربية بناءً على index (0=السبت)
  static String dayName(int index) {
    const days = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء',
      'الأربعاء', 'الخميس', 'الجمعة',
    ];
    if (index >= 0 && index < days.length) return days[index];
    return '';
  }

  /// اختصار يوم الأسبوع بالعربية
  static String dayShortName(int index) {
    const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    if (index >= 0 && index < days.length) return days[index];
    return '';
  }

  /// اسم يوم الملخص الأسبوعي
  String get weeklyDigestDayName => dayName(weeklyDigestDay);

  /// [FIX #12 — مساعد] DateTime.weekday المقابل لـ weeklyDigestDay.
  ///
  /// استخدم هذا دائماً عند المقارنة مع DateTime.weekday بدلاً من
  /// weeklyDigestDay مباشرةً لتجنب الخلط بين نظامَي الترقيم.
  int get weeklyDigestDateTimeWeekday =>
      NotificationSettings.appDayToDateTimeWeekday(weeklyDigestDay);

  // ── JSON helpers for TimeOfDay ────────────────────────────────────────────

  static Map<String, int> _timeToJson(TimeOfDay t) => {
        'hour': t.hour,
        'minute': t.minute,
      };

  static TimeOfDay? _timeFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map) {
      final hour   = (json['hour']   as num?)?.toInt() ?? 8;
      final minute = (json['minute'] as num?)?.toInt() ?? 0;
      return TimeOfDay(
        hour:   hour.clamp(0, 23),
        minute: minute.clamp(0, 59),
      );
    }
    return null;
  }

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettings &&
          isEnabled      == other.isEnabled      &&
          taskReminders  == other.taskReminders  &&
          motivational   == other.motivational   &&
          achievements   == other.achievements   &&
          summaries      == other.summaries      &&
          preferMorning  == other.preferMorning  &&
          preferAfternoon == other.preferAfternoon &&
          preferEvening  == other.preferEvening  &&
          preferNight    == other.preferNight    &&
          listEquals(preferredDays, other.preferredDays) &&
          lectureReminderMinutes == other.lectureReminderMinutes &&
          morningDigestTime == other.morningDigestTime &&
          eveningDigestTime == other.eveningDigestTime &&
          weeklyDigestDay   == other.weeklyDigestDay   &&
          weeklyDigestTime  == other.weeklyDigestTime  &&
          vibrate == other.vibrate &&
          sound   == other.sound;

  @override
  int get hashCode => Object.hash(
        isEnabled,
        taskReminders,
        motivational,
        achievements,
        summaries,
        preferMorning,
        preferAfternoon,
        preferEvening,
        preferNight,
        Object.hashAll(preferredDays),
        lectureReminderMinutes,
        morningDigestTime,
        eveningDigestTime,
        weeklyDigestDay,
        weeklyDigestTime,
        vibrate,
        sound,
      );
}
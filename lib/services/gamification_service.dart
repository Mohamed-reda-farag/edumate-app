import '../models/attendance_record_model.dart';
import '../models/gamification_model.dart';
import '../models/study_session_model.dart';

// ─── GamificationService ──────────────────────────────────────────────────────

/// Pure business-logic service. No Firebase, no I/O.
/// Every method receives immutable state and returns a new [GamificationData].
class GamificationService {
  const GamificationService();

  // ══════════════════════════════════════════════════════════════════════════
  //  1. Attendance Points
  // ══════════════════════════════════════════════════════════════════════════

  /// Points table:
  /// - attended  → +10  (+5 bonus if understandingRating == 5)
  /// - late      → +5
  /// - absent    → +0
  GamificationData addAttendancePoints(
    GamificationData current,
    AttendanceRecord record,
  ) {
    int earned = 0;

    switch (record.status) {
      case AttendanceStatus.attended:
        earned = 10;
        if (record.understandingRating == 5) earned += 5;
        break;
      case AttendanceStatus.late:
        earned = 5;
        break;
      case AttendanceStatus.absent:
        earned = 0;
        break;
    }

    final withStreak = _updateStreak(current, record.date);

    return withStreak.copyWith(
      totalPoints: withStreak.totalPoints + earned,
      weeklyPoints: withStreak.weeklyPoints + earned,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  2. Study Session Points
  // ══════════════════════════════════════════════════════════════════════════

  /// Points table:
  /// - completed, completionRate >= 0.8  → +15
  /// - completed, completionRate >= 0.5  → +8
  /// - completed, completionRate == null → +0 (لم يُسجَّل نسبة)
  /// - skipped                           → -5 (floor at 0)
  GamificationData addStudySessionPoints(
    GamificationData current,
    StudySession session,
  ) {
    int delta = 0;

    switch (session.status) {
      case SessionStatus.completed:
        final rate = session.completionRate ?? 0.0;
        // completionRate == null تعني "أُكملت بدون تسجيل نسبة" → 0 نقاط
        // هذا قرار متعمد لتشجيع تسجيل النسبة الفعلية
        if (rate >= 0.8) {
          delta = 15;
        } else if (rate >= 0.5) {
          delta = 8;
        }
        break;

      case SessionStatus.skipped:
        delta = -5;
        break;

      case SessionStatus.planned:
        break;
    }

    const int kMaxPoints = 999999999;
    final newTotal  = (current.totalPoints  + delta).clamp(0, kMaxPoints);
    final newWeekly = (current.weeklyPoints + delta).clamp(0, kMaxPoints);

    return current.copyWith(
      totalPoints:  newTotal,
      weeklyPoints: newWeekly,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  3. Achievement Unlocking
  // ══════════════════════════════════════════════════════════════════════════

  GamificationData checkAndUnlockAchievements(
    GamificationData current,
    List<AttendanceRecord> allRecords,
    List<StudySession> allSessions,
  ) {
    final alreadyUnlocked = Set<String>.from(current.unlockedAchievements);
    final newlyUnlocked   = <String>[];
    int bonusPoints = 0;

    final stats = _StudentStats.from(
      current:  current,
      records:  allRecords,
      sessions: allSessions,
    );

    for (final achievement in Achievement.all) {
      if (alreadyUnlocked.contains(achievement.id)) continue;
      if (_isAchievementEarned(achievement, stats)) {
        newlyUnlocked.add(achievement.id);
        bonusPoints += achievement.pointsReward;
      }
    }

    if (newlyUnlocked.isEmpty) return current;

    return current.copyWith(
      unlockedAchievements: [...current.unlockedAchievements, ...newlyUnlocked],
      totalPoints:  current.totalPoints  + bonusPoints,
      weeklyPoints: current.weeklyPoints + bonusPoints,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  4. Streak Management
  // ══════════════════════════════════════════════════════════════════════════

  GamificationData _updateStreak(GamificationData current, DateTime today) {
    final todayDate = _dateOnly(today);
    final lastDate  = _dateOnly(current.lastActiveDate);

    if (lastDate == todayDate) return current;

    final yesterday = todayDate.subtract(const Duration(days: 1));

    final newStreak = (lastDate == yesterday)
        ? current.currentStreak + 1
        : 1;

    final newLongest = newStreak > current.longestStreak
        ? newStreak
        : current.longestStreak;

    return current.copyWith(
      currentStreak:  newStreak,
      longestStreak:  newLongest,
      lastActiveDate: todayDate,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Private helpers
  // ══════════════════════════════════════════════════════════════════════════

  bool _isAchievementEarned(Achievement achievement, _StudentStats stats) {
    switch (achievement.type) {
      case AchievementType.attendance:
        return _checkAttendanceAchievement(achievement, stats);
      case AchievementType.study:
        return _checkStudyAchievement(achievement, stats);
      case AchievementType.streak:
        return stats.longestStreak >= achievement.requiredValue;
      case AchievementType.performance:
        return _checkPerformanceAchievement(achievement, stats);
    }
  }

  bool _checkAttendanceAchievement(Achievement a, _StudentStats stats) {
    switch (a.id) {
      case 'first_attendance':
        return stats.totalAttended >= 1;
      case 'attendance_10':
        return stats.maxConsecutiveAttended >= a.requiredValue;
      case 'attendance_50':
        return stats.totalAttended >= a.requiredValue;
      case 'perfect_week':
        return stats.hasPerfectWeekWithMin(a.requiredValue);
      default:
        return stats.totalAttended >= a.requiredValue;
    }
  }

  bool _checkStudyAchievement(Achievement a, _StudentStats stats) {
    switch (a.id) {
      case 'study_5h':
      case 'study_20h':
        return stats.totalStudyHours >= a.requiredValue;
      default:
        return stats.completedSessions >= a.requiredValue;
    }
  }

  bool _checkPerformanceAchievement(Achievement a, _StudentStats stats) {
    switch (a.id) {
      case 'understanding_5':
        return stats.perfectUnderstandingCount >= a.requiredValue;
      case 'all_subjects_studied':
        return stats.studiedAllSubjectsThisWeek;
      default:
        return false;
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

// ─── _StudentStats ────────────────────────────────────────────────────────────

class _StudentStats {
  const _StudentStats({
    required this.totalAttended,
    required this.maxConsecutiveAttended,
    required this.perfectWeekMinAttended,
    required this.perfectUnderstandingCount,
    required this.totalStudyHours,
    required this.completedSessions,
    required this.longestStreak,
    required this.studiedAllSubjectsThisWeek,
  });

  final int    totalAttended;
  final int    maxConsecutiveAttended;
  final int    perfectWeekMinAttended;
  final int    perfectUnderstandingCount;
  final double totalStudyHours;
  final int    completedSessions;
  final int    longestStreak;
  final bool   studiedAllSubjectsThisWeek;

  bool hasPerfectWeekWithMin(int minAttended) =>
      perfectWeekMinAttended >= minAttended;

  factory _StudentStats.from({
    required GamificationData current,
    required List<AttendanceRecord> records,
    required List<StudySession> sessions,
  }) {
    // [FIX] الإنجازات المبنية على عدد المحاضرات تعتمد على lec فقط
    // لأن attendance_50 و perfect_week يجب أن يعكسا حضور المحاضرات فقط
    final lectureRecords = records
        .where((r) => r.sessionType == 'lec')
        .toList();

    final attended = lectureRecords
        .where((r) =>
            r.status == AttendanceStatus.attended ||
            r.status == AttendanceStatus.late)
        .toList();

    final totalAttended = attended.length;

    // perfectUnderstanding من كل الأنواع — الفهم يشمل lec + sec + lab
    final perfectUnderstanding = records
        .where((r) =>
            r.status == AttendanceStatus.attended &&
            r.understandingRating == 5)
        .length;

    final attendedDays = attended
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet()
        .toList()
      ..sort();

    int maxConsecutive = 0;
    int streak = 0;
    DateTime? prev;

    for (final d in attendedDays) {
      if (prev == null) {
        streak = 1;
      } else {
        final diff = d.difference(prev).inDays;
        streak = diff == 1 ? streak + 1 : 1;
      }
      if (streak > maxConsecutive) maxConsecutive = streak;
      prev = d;
    }

    // perfect_week يُحسب من المحاضرات فقط
    final perfectWeekMax = _maxAttendedInPerfectWeek(lectureRecords);

    // باقي الكود بدون تغيير
    final completed = sessions
        .where((s) => s.status == SessionStatus.completed)
        .toList();
    final completedCount = completed.length;
    final totalStudyMinutes = completed.fold<int>(
      0,
      (sum, s) => sum + (s.actualDurationMinutes ?? s.durationMinutes),
    );
    final totalStudyHours = totalStudyMinutes / 60.0;
    final studiedAllSubjects = _checkStudiedAllSubjectsThisWeek(sessions);

    return _StudentStats(
      totalAttended:              totalAttended,
      maxConsecutiveAttended:     maxConsecutive,
      perfectWeekMinAttended:     perfectWeekMax,
      perfectUnderstandingCount:  perfectUnderstanding,
      totalStudyHours:            totalStudyHours,
      completedSessions:          completedCount,
      longestStreak:              current.longestStreak,
      studiedAllSubjectsThisWeek: studiedAllSubjects,
    );
  }

  static int _maxAttendedInPerfectWeek(List<AttendanceRecord> records) {
    if (records.isEmpty) return 0;

    final Map<String, List<AttendanceRecord>> byWeek = {};
    for (final r in records) {
      final key = _isoWeekKey(r.date);
      byWeek.putIfAbsent(key, () => []).add(r);
    }

    int maxAttended = 0;
    for (final weekRecords in byWeek.values) {
      final hasAbsence =
          weekRecords.any((r) => r.status == AttendanceStatus.absent);
      if (hasAbsence) continue;

      final attendedCount = weekRecords
          .where((r) =>
              r.status == AttendanceStatus.attended ||
              r.status == AttendanceStatus.late)
          .length;
      if (attendedCount > maxAttended) maxAttended = attendedCount;
    }
    return maxAttended;
  }

  static bool _checkStudiedAllSubjectsThisWeek(List<StudySession> sessions) {
    final now     = DateTime.now();
    final weekKey = _isoWeekKey(now);

    final weekSessions =
        sessions.where((s) => _isoWeekKey(s.scheduledDate) == weekKey).toList();

    if (weekSessions.isEmpty) return false;

    final allSubjects = weekSessions.map((s) => s.subjectId).toSet();
    final completedSubjects = weekSessions
        .where((s) => s.status == SessionStatus.completed)
        .map((s) => s.subjectId)
        .toSet();

    return allSubjects.isNotEmpty && completedSubjects.containsAll(allSubjects);
  }

  static String _isoWeekKey(DateTime dt) {
    final date = DateTime(dt.year, dt.month, dt.day);
    final daysSinceSaturday = switch (date.weekday) {
      6 => 0,
      7 => 1,
      _ => date.weekday + 1,
    };
    final weekStart = date.subtract(Duration(days: daysSinceSaturday));
    return '${weekStart.year}-'
        '${weekStart.month.toString().padLeft(2, '0')}-'
        '${weekStart.day.toString().padLeft(2, '0')}';
  }
}
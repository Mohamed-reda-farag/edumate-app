import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum AchievementType { attendance, study, streak, performance }

// ─── Achievement ─────────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String titleAr;
  final String descriptionAr;
  final int pointsReward;
  final AchievementType type;
  final int requiredValue;
  final String iconName;

  const Achievement({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.pointsReward,
    required this.type,
    required this.requiredValue,
    required this.iconName,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      descriptionAr: json['descriptionAr'] as String,
      pointsReward: json['pointsReward'] as int,
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () =>
            throw ArgumentError('Invalid achievement type: ${json['type']}'),
      ),
      requiredValue: json['requiredValue'] as int,
      iconName: json['iconName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleAr': titleAr,
        'descriptionAr': descriptionAr,
        'pointsReward': pointsReward,
        'type': type.name,
        'requiredValue': requiredValue,
        'iconName': iconName,
      };

  Achievement copyWith({
    String? id,
    String? titleAr,
    String? descriptionAr,
    int? pointsReward,
    AchievementType? type,
    int? requiredValue,
    String? iconName,
  }) {
    return Achievement(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      pointsReward: pointsReward ?? this.pointsReward,
      type: type ?? this.type,
      requiredValue: requiredValue ?? this.requiredValue,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          titleAr == other.titleAr &&
          descriptionAr == other.descriptionAr &&
          pointsReward == other.pointsReward &&
          type == other.type &&
          requiredValue == other.requiredValue &&
          iconName == other.iconName;

  @override
  int get hashCode => Object.hash(
        id,
        titleAr,
        descriptionAr,
        pointsReward,
        type,
        requiredValue,
        iconName,
      );

  // ─── Static Achievements List ───────────────────────────────────────────

  /// Master list of all achievements in the app (at least 8)
  static const List<Achievement> all = [
    Achievement(
      id: 'first_attendance',
      titleAr: 'الخطوة الأولى',
      descriptionAr: 'سجّل حضورك في أول محاضرة',
      pointsReward: 50,
      type: AchievementType.attendance,
      requiredValue: 1,
      iconName: 'school',
    ),
    Achievement(
      id: 'attendance_10',
      titleAr: 'طالب منتظم',
      descriptionAr: 'احضر 10 أيام متتالية',
      pointsReward: 100,
      type: AchievementType.attendance,
      requiredValue: 10,
      iconName: 'event_available',
    ),
    Achievement(
      id: 'attendance_50',
      titleAr: 'حاضر دائماً',
      descriptionAr: 'احضر 50 محاضرة',
      pointsReward: 300,
      type: AchievementType.attendance,
      requiredValue: 50,
      iconName: 'military_tech',
    ),
    Achievement(
      id: 'perfect_week',
      titleAr: 'أسبوع مثالي',
      descriptionAr: 'احضر جميع محاضرات أسبوع كامل دون غياب',
      pointsReward: 150,
      type: AchievementType.attendance,
      requiredValue: 5,
      iconName: 'stars',
    ),
    Achievement(
      id: 'study_5h',
      titleAr: 'مبتدئ المذاكرة',
      descriptionAr: 'سجّل 5 ساعات دراسة',
      pointsReward: 75,
      type: AchievementType.study,
      requiredValue: 5,
      iconName: 'menu_book',
    ),
    Achievement(
      id: 'study_20h',
      titleAr: 'مجتهد',
      descriptionAr: 'سجّل 20 ساعة دراسة',
      pointsReward: 200,
      type: AchievementType.study,
      requiredValue: 20,
      iconName: 'auto_stories',
    ),
    Achievement(
      id: 'streak_3',
      titleAr: 'ثلاثة أيام متواصلة',
      descriptionAr: 'استخدم التطبيق 3 أيام متتالية',
      pointsReward: 60,
      type: AchievementType.streak,
      requiredValue: 3,
      iconName: 'local_fire_department',
    ),
    Achievement(
      id: 'streak_7',
      titleAr: 'أسبوع من الالتزام',
      descriptionAr: 'استخدم التطبيق 7 أيام متتالية',
      pointsReward: 150,
      type: AchievementType.streak,
      requiredValue: 7,
      iconName: 'whatshot',
    ),
    Achievement(
      id: 'streak_30',
      titleAr: 'شهر من الإصرار',
      descriptionAr: 'استخدم التطبيق 30 يوماً متتالياً',
      pointsReward: 500,
      type: AchievementType.streak,
      requiredValue: 30,
      iconName: 'emoji_events',
    ),
    Achievement(
      id: 'understanding_5',
      titleAr: 'فاهم ومستوعب',
      descriptionAr: 'سجّل تقييم فهم 5/5 في 5 محاضرات',
      pointsReward: 120,
      type: AchievementType.performance,
      requiredValue: 5,
      iconName: 'psychology',
    ),
    Achievement(
      id: 'all_subjects_studied',
      titleAr: 'الطالب الشامل',
      descriptionAr: 'ذاكر جميع المواد في نفس الأسبوع',
      pointsReward: 200,
      type: AchievementType.performance,
      requiredValue: 1,
      iconName: 'balance',
    ),
  ];

  /// Helper: find an achievement by id
  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── GamificationData ─────────────────────────────────────────────────────────

const int _pointsPerLevel = 500;

class GamificationData {
  final String userId;
  final int totalPoints;
  final int level; // derived: totalPoints ~/ _pointsPerLevel + 1
  final int currentStreak;
  final int longestStreak;
  final List<String> unlockedAchievements; // Achievement IDs
  final DateTime lastActiveDate;
  final int weeklyPoints;
  final DateTime weeklyPointsResetDate;

  const GamificationData._({
    required this.userId,
    required this.totalPoints,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.unlockedAchievements,
    required this.lastActiveDate,
    required this.weeklyPoints,
    required this.weeklyPointsResetDate,
  });

  factory GamificationData({
    required String userId,
    required int totalPoints,
    required int currentStreak,
    required int longestStreak,
    required List<String> unlockedAchievements,
    required DateTime lastActiveDate,
    required int weeklyPoints,
    DateTime? weeklyPointsResetDate,
  }) {
    if (userId.isEmpty) throw ArgumentError('userId cannot be empty');
    if (totalPoints < 0) throw ArgumentError('totalPoints must be >= 0');
    if (currentStreak < 0) throw ArgumentError('currentStreak must be >= 0');
    if (longestStreak < 0) throw ArgumentError('longestStreak must be >= 0');
    if (weeklyPoints < 0) throw ArgumentError('weeklyPoints must be >= 0');

    final safeLongest = longestStreak < currentStreak ? currentStreak : longestStreak;

    final resolvedResetDate = weeklyPointsResetDate ?? DateTime.now();
    final computedLevel = (totalPoints ~/ _pointsPerLevel) + 1;

    return GamificationData._(
      userId: userId,
      totalPoints: totalPoints,
      level: computedLevel,
      currentStreak: currentStreak,
      longestStreak: safeLongest,
      unlockedAchievements: List.unmodifiable(unlockedAchievements),
      lastActiveDate: lastActiveDate,
      weeklyPoints: weeklyPoints,
      weeklyPointsResetDate: resolvedResetDate,
    );
  }

  // ─── Computed Getters ──────────────────────────────────────────────────────

  /// Progress toward the next level (0.0–1.0)
  double get levelProgress {
    final pointsInCurrentLevel = totalPoints % _pointsPerLevel;
    return pointsInCurrentLevel / _pointsPerLevel;
  }

  /// How many points are needed to reach the next level
  int get pointsToNextLevel {
    final pointsInCurrentLevel = totalPoints % _pointsPerLevel;
    return _pointsPerLevel - pointsInCurrentLevel;
  }

  // ─── Serialization ─────────────────────────────────────────────────────────

  factory GamificationData.fromJson(Map<String, dynamic> json) {
    return GamificationData(
      userId: json['userId'] as String,
      totalPoints: json['totalPoints'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      unlockedAchievements:
          List<String>.from(json['unlockedAchievements'] as List),
      lastActiveDate: (json['lastActiveDate'] as Timestamp).toDate(),
      weeklyPoints: json['weeklyPoints'] as int,
      weeklyPointsResetDate: json['weeklyPointsResetDate'] != null
          ? (json['weeklyPointsResetDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalPoints': totalPoints,
        // level is computed — no need to persist it
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'unlockedAchievements': unlockedAchievements.toList(),
        'lastActiveDate': Timestamp.fromDate(lastActiveDate),
        'weeklyPoints': weeklyPoints,
        'weeklyPointsResetDate': Timestamp.fromDate(weeklyPointsResetDate),
      };

  GamificationData copyWith({
    String? userId,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    List<String>? unlockedAchievements,
    DateTime? lastActiveDate,
    int? weeklyPoints,
    DateTime? weeklyPointsResetDate,
  }) {
    return GamificationData(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      weeklyPointsResetDate: weeklyPointsResetDate ?? this.weeklyPointsResetDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamificationData &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          totalPoints == other.totalPoints &&
          level == other.level &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          _listEquals(unlockedAchievements, other.unlockedAchievements) &&
          lastActiveDate == other.lastActiveDate &&
          weeklyPoints == other.weeklyPoints &&
          weeklyPointsResetDate == other.weeklyPointsResetDate;

  @override
  int get hashCode => Object.hash(
        userId,
        totalPoints,
        level,
        currentStreak,
        longestStreak,
        Object.hashAll(unlockedAchievements),
        lastActiveDate,
        weeklyPoints,
        weeklyPointsResetDate,
      );

  @override
  String toString() =>
      'GamificationData(userId: $userId, level: $level, points: $totalPoints, streak: $currentStreak)';
}

// ─── Utils ────────────────────────────────────────────────────────────────────

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
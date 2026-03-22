import 'package:flutter/material.dart';

/// أدوات مشتركة لعرض بيانات المهارات والمجالات
class SkillUtils {

  // ─────────────────────────────────────────────────────────────────────────
  // المستويات
  // ─────────────────────────────────────────────────────────────────────────

  /// تحويل مفتاح المستوى لنص عربي
  /// مثال: 'foundation' → 'الأساسيات'
  static String levelLabel(String level) {
    const map = {
      'foundation': 'الأساسيات',
      'intermediate': 'المتوسط',
      'advanced': 'المتقدم',
      'expert': 'الخبير',
    };
    return map[level] ?? level;
  }

  /// نفس levelLabel لكن بصيغة مختصرة تُستخدم في الـ chips
  /// مثال: 'foundation' → 'مبتدئ'
  static String levelShortLabel(String level) {
    const map = {
      'foundation': 'مبتدئ',
      'intermediate': 'متوسط',
      'advanced': 'متقدم',
      'expert': 'خبير',
    };
    return map[level] ?? level;
  }

  /// لون المستوى الأساسي
  static Color levelColor(String level) {
    const colors = {
      'foundation': Color(0xFF4ECDC4),
      'intermediate': Color(0xFF6C63FF),
      'advanced': Color(0xFFFF6B6B),
      'expert': Color(0xFFFFB347),
    };
    return colors[level] ?? const Color(0xFF6C63FF);
  }

  /// ألوان badge المستوى (خلفية + نص) تدعم Dark/Light mode
  static ({Color background, Color text}) levelBadgeColors(
    String level,
    bool isDark,
  ) {
    switch (level) {
      case 'foundation':
        return (
          background: isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9),
          text: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        );
      case 'intermediate':
        return (
          background: isDark ? const Color(0xFF0D47A1) : const Color(0xFFE3F2FD),
          text: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
        );
      case 'advanced':
        return (
          background: isDark ? const Color(0xFFE65100) : const Color(0xFFFFF3E0),
          text: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
        );
      case 'expert':
        return (
          background: isDark ? const Color(0xFFB71C1C) : const Color(0xFFFFEBEE),
          text: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
        );
      default:
        return (
          background: isDark ? const Color(0xFF424242) : const Color(0xFFF5F5F5),
          text: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF616161),
        );
    }
  }

  /// ترتيب المستويات رقمياً (للمقارنة والترتيب)
  static int levelIndex(String level) {
    const order = ['foundation', 'intermediate', 'advanced', 'expert'];
    final index = order.indexOf(level);
    return index == -1 ? 0 : index;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // الصعوبة
  // ─────────────────────────────────────────────────────────────────────────

  /// تحويل مفتاح الصعوبة لنص عربي
  static String difficultyLabel(String difficulty) {
    const map = {'easy': 'سهل', 'medium': 'متوسط', 'hard': 'صعب'};
    return map[difficulty] ?? difficulty;
  }

  /// لون الصعوبة
  static Color difficultyColor(String difficulty) {
    return switch (difficulty) {
      'easy' => const Color(0xFF2ECC71),
      'hard' => const Color(0xFFFF6B6B),
      _ => const Color(0xFFFFB347),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // الأهمية
  // ─────────────────────────────────────────────────────────────────────────

  /// تحويل قيمة الأهمية (0-100) لنص وصفي
  static String importanceLabel(int importance) {
    if (importance >= 80) return 'أهمية عالية ($importance%)';
    if (importance >= 50) return 'أهمية متوسطة ($importance%)';
    return 'اختياري ($importance%)';
  }

  /// لون الأهمية
  static Color importanceColor(int importance) {
    if (importance >= 80) return const Color(0xFFFF6B6B);
    if (importance >= 50) return const Color(0xFFFFB347);
    return const Color(0xFF4ECDC4);
  }

  /// تحويل الأهمية (0-100) لعدد نجوم (0-5)
  static int importanceStars(int importance) {
    return (importance / 20).round().clamp(0, 5);
  }
}
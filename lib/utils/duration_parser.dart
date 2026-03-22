/// مساعد لتحليل وتحويل مدد الكورسات
class DurationParser {
  /// تحويل نص المدة إلى عدد الساعات
  /// يدعم الصيغ الطويلة:  "18 hours", "2 days", "3 weeks"
  /// يدعم الصيغ المختصرة: "1.5h", "3hrs", "20mins", "45m"
  /// يدعم العربية:         "18 ساعة", "يومان", "دقيقة"
  static double parseToHours(String duration) {
    if (duration.isEmpty) return 0.0;

    final text = duration.toLowerCase().trim();

    // ── صيغ مختصرة أولاً (h, hr, hrs, min, mins, m) ─────────────────────
    final shortHoursMatch =
        RegExp(r'(\d+\.?\d*)\s*(hrs?|h\b)').firstMatch(text);
    if (shortHoursMatch != null) {
      return double.parse(shortHoursMatch.group(1)!);
    }

    final shortMinsMatch =
        RegExp(r'(\d+)\s*(mins?|m\b)').firstMatch(text);
    if (shortMinsMatch != null) {
      return int.parse(shortMinsMatch.group(1)!) / 60.0;
    }

    // ── استخراج الرقم للصيغ الطويلة ──────────────────────────────────────
    final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(text);
    if (numberMatch == null) return 0.0;

    final number = double.tryParse(numberMatch.group(1) ?? '0') ?? 0.0;

    // ── صيغ طويلة ─────────────────────────────────────────────────────────
    if (text.contains('hour') || text.contains('ساعة')) {
      return number;
    } else if (text.contains('day') || text.contains('يوم')) {
      return number * 24;
    } else if (text.contains('week') || text.contains('أسبوع')) {
      return number * 24 * 7;
    } else if (text.contains('month') || text.contains('شهر')) {
      return number * 24 * 30;
    } else if (text.contains('min') || text.contains('دقيقة')) {
      return number / 60;
    }

    // افتراضياً نعتبرها ساعات
    return number;
  }

  /// تحويل الساعات إلى نص مقروء
  /// مثال: 18.0 → "18 ساعة"
  /// مثال: 48.0 → "يومان"
  static String hoursToText(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes دقيقة';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(0)} ساعة';
    } else if (hours < 168) {
      final days = (hours / 24).round();
      if (days == 1) return 'يوم واحد';
      if (days == 2) return 'يومان';
      return '$days أيام';
    } else if (hours < 720) {
      final weeks = (hours / 168).round();
      if (weeks == 1) return 'أسبوع واحد';
      if (weeks == 2) return 'أسبوعان';
      return '$weeks أسابيع';
    } else {
      final months = (hours / 720).round();
      if (months == 1) return 'شهر واحد';
      if (months == 2) return 'شهران';
      return '$months أشهر';
    }
  }
}
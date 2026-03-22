

class _GradeEntry {
  final String letter;
  final double point4;        // القيمة على نظام 4.0
  final double point5;        // القيمة على نظام 5.0
  final bool usedInP2L;       // هل يُستخدم في gradePointToLetter？

  const _GradeEntry(this.letter, this.point4, this.point5,
      {this.usedInP2L = true});
}

const List<_GradeEntry> _kGradeTable = [
  _GradeEntry('A+', 4.0,  5.00, usedInP2L: false),
  _GradeEntry('A',  4.0,  5.00),
  _GradeEntry('A-', 3.7,  4.75),
  _GradeEntry('B+', 3.3,  4.50),
  _GradeEntry('B',  3.0,  4.00),
  _GradeEntry('B-', 2.7,  3.75),
  _GradeEntry('C+', 2.3,  3.50),
  _GradeEntry('C',  2.0,  3.00),
  _GradeEntry('C-', 1.7,  2.75),
  _GradeEntry('D+', 1.3,  2.50),
  _GradeEntry('D',  1.0,  2.00),
  _GradeEntry('F',  0.0,  0.00),
];

// ── GPASubject ────────────────────────────────────────────────────────────────

class GPASubject {
  final String name;
  final double gradePoint;
  final int creditHours;
  final String? gradeLevel;
  final String? semester;
  final DateTime? dateAdded;
  final Map<String, dynamic>? metadata;

  GPASubject({
    required this.name,
    required this.gradePoint,
    required this.creditHours,
    this.gradeLevel,
    this.semester,
    this.dateAdded,
    this.metadata,
  })  : assert(_validateGradePoint(gradePoint),
            'Grade point must be between 0 and 5.0'),
        assert(_validateCreditHours(creditHours),
            'Credit hours must be between 1 and 6'),
        assert(_validateName(name), 'Subject name cannot be empty');

  /// Factory مع validation — يقبل gradePoint حتى 5.0 (نظام 4.0 و5.0)
  factory GPASubject.create({
    required String name,
    required double gradePoint,
    required int creditHours,
    String? semester,
    Map<String, dynamic>? metadata,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Subject name cannot be empty');
    }
    if (gradePoint < 0 || gradePoint > 5.0) {
      throw ArgumentError('Grade point must be between 0.0 and 5.0');
    }
    if (creditHours <= 0 || creditHours > 6) {
      throw ArgumentError('Credit hours must be between 1 and 6');
    }
    return GPASubject(
      name: name.trim(),
      gradePoint: gradePoint,
      creditHours: creditHours,
      gradeLevel: _calculateGradeLevel(gradePoint),
      semester: semester,
      dateAdded: DateTime.now(),
      metadata: metadata,
    );
  }

  /// إنشاء من حرف التقدير — يستخدم الجدول المرجعي الموحَّد
  factory GPASubject.fromGradeLetter({
    required String name,
    required String gradeLetter,
    required int creditHours,
    String? semester,
    Map<String, dynamic>? metadata,
  }) {
    final gradePoint = gradeLetterToPoint(gradeLetter);
    return GPASubject.create(
      name: name,
      gradePoint: gradePoint,
      creditHours: creditHours,
      semester: semester,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    try {
      final json = <String, dynamic>{
        'name': name,
        'gradePoint': gradePoint,
        'creditHours': creditHours,
        'gradeLevel': gradeLevel ?? _calculateGradeLevel(gradePoint),
        'dateAdded':
            dateAdded?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
      if (semester != null) json['semester'] = semester;
      if (metadata != null && metadata!.isNotEmpty) json['metadata'] = metadata;
      return json;
    } catch (e) {
      throw FormatException('Failed to serialize GPASubject to JSON: $e');
    }
  }

  factory GPASubject.fromJson(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('name') ||
          !json.containsKey('gradePoint') ||
          !json.containsKey('creditHours')) {
        throw ArgumentError('Missing required fields in JSON data');
      }

      final name = json['name']?.toString().trim() ?? '';
      if (name.isEmpty) throw ArgumentError('Subject name cannot be empty');

      final gradePoint = (json['gradePoint'] as num?)?.toDouble();
      if (gradePoint == null || gradePoint < 0 || gradePoint > 5.0) {
        throw ArgumentError('Invalid grade point: $gradePoint');
      }

      final creditHours = json['creditHours'] as int?;
      if (creditHours == null || creditHours <= 0 || creditHours > 6) {
        throw ArgumentError('Invalid credit hours: $creditHours');
      }

      final semester = json['semester']?.toString();

      DateTime? dateAdded;
      if (json['dateAdded'] != null) {
        try {
          dateAdded = DateTime.parse(json['dateAdded'] as String);
        } catch (_) {
          dateAdded = DateTime.now();
        }
      }

      Map<String, dynamic>? metadata;
      if (json['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(json['metadata'] as Map);
      }

      return GPASubject(
        name: name,
        gradePoint: gradePoint,
        creditHours: creditHours,
        gradeLevel: json['gradeLevel']?.toString() ??
            _calculateGradeLevel(gradePoint),
        semester: semester,
        dateAdded: dateAdded,
        metadata: metadata,
      );
    } catch (e) {
      throw FormatException('Failed to parse GPASubject from JSON: $e');
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  String getGradeLetter() => gradePointToLetter(gradePoint);

  bool isPassing() => gradePoint >= 1.0;
  bool isHighPerformance() => gradePoint >= 3.5;
  bool needsAttention() => gradePoint < 2.0;

  PerformanceLevel getPerformanceLevel() {
    if (gradePoint >= 3.7) return PerformanceLevel.excellent;
    if (gradePoint >= 3.0) return PerformanceLevel.veryGood;
    if (gradePoint >= 2.0) return PerformanceLevel.good;
    if (gradePoint >= 1.0) return PerformanceLevel.acceptable;
    return PerformanceLevel.failing;
  }

  double getGPAContribution(double totalCredits) {
    if (totalCredits <= 0) return 0.0;
    return (gradePoint * creditHours) / totalCredits;
  }

  String getStudyRecommendation() {
    if (gradePoint >= 3.5) return 'أداء ممتاز! حافظ على مستواك الحالي';
    if (gradePoint >= 3.0) return 'أداء جيد جداً. يمكنك تحسينه قليلاً للوصول للامتياز';
    if (gradePoint >= 2.0) return 'أداء مقبول. ركز على تحسين فهمك للمادة';
    if (gradePoint >= 1.0) return 'يحتاج إلى تحسين كبير. اطلب المساعدة من الأستاذ أو زملائك';
    return 'وضع حرج. يجب إعادة النظر في استراتيجية الدراسة';
  }

  Map<String, dynamic> getAnalytics() {
    return {
      'name': name,
      'gradePoint': gradePoint,
      'gradeLetter': getGradeLetter(),
      'gradeLevel': gradeLevel,
      'creditHours': creditHours,
      'weightedPoints': gradePoint * creditHours,
      'isPassing': isPassing(),
      'isHighPerformance': isHighPerformance(),
      'needsAttention': needsAttention(),
      'performanceLevel': getPerformanceLevel().toString().split('.').last,
      'studyRecommendation': getStudyRecommendation(),
      'semester': semester,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  GPASubject copyWith({
    String? name,
    double? gradePoint,
    int? creditHours,
    String? gradeLevel,
    String? semester,
    DateTime? dateAdded,
    Map<String, dynamic>? metadata,
  }) {
    return GPASubject(
      name: name ?? this.name,
      gradePoint: gradePoint ?? this.gradePoint,
      creditHours: creditHours ?? this.creditHours,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      semester: semester ?? this.semester,
      dateAdded: dateAdded ?? this.dateAdded,
      metadata: metadata ?? this.metadata,
    );
  }

  // ── Static validation ────────────────────────────────────────────────────

  static bool _validateName(String name) =>
      name.trim().isNotEmpty && name.length <= 100;

  static bool _validateGradePoint(double gradePoint) =>
      gradePoint >= 0.0 && gradePoint <= 5.0;

  static bool _validateCreditHours(int creditHours) =>
      creditHours > 0 && creditHours <= 6;

  static String _calculateGradeLevel(double gradePoint) {
    if (gradePoint >= 3.7) return 'ممتاز';
    if (gradePoint >= 3.0) return 'جيد جداً';
    if (gradePoint >= 2.0) return 'جيد';
    if (gradePoint >= 1.0) return 'مقبول';
    return 'راسب';
  }
  
  static String gradePointToLetter(double gradePoint) {
    for (final entry in _kGradeTable) {
      if (!entry.usedInP2L) continue;
      if (gradePoint >= entry.point4) return entry.letter;
    }
    return 'F';
  }

  /// تحويل gradeLetter → gradePoint (نظام 4.0) باستخدام _kGradeTable
  static double gradeLetterToPoint(String letter) {
    final key = letter.trim().toUpperCase();
    for (final entry in _kGradeTable) {
      if (entry.letter == key) return entry.point4;
    }
    throw ArgumentError('Invalid grade letter: $letter');
  }

  /// تحويل gradeLetter → gradePoint على نظام 5.0
  static double gradeLetterToPoint5(String letter) {
    final key = letter.trim().toUpperCase();
    for (final entry in _kGradeTable) {
      if (entry.letter == key) return entry.point5;
    }
    throw ArgumentError('Invalid grade letter: $letter');
  }

  // ── Equality & toString ──────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GPASubject &&
        other.name == name &&
        other.gradePoint == gradePoint &&
        other.creditHours == creditHours &&
        other.semester == semester;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      gradePoint.hashCode ^
      creditHours.hashCode ^
      (semester?.hashCode ?? 0);

  @override
  String toString() =>
      'GPASubject(name: $name, gradePoint: $gradePoint, '
      'creditHours: $creditHours, gradeLevel: $gradeLevel, semester: $semester)';

  String toDetailedString() {
    final buffer = StringBuffer()
      ..writeln('Subject: $name')
      ..writeln('Grade: ${getGradeLetter()} ($gradePoint)')
      ..writeln('Credit Hours: $creditHours')
      ..writeln('Grade Level: $gradeLevel')
      ..writeln('Performance: ${getPerformanceLevel().toString().split('.').last}');
    if (semester != null) buffer.writeln('Semester: $semester');
    if (dateAdded != null) buffer.writeln('Added: ${dateAdded!.toLocal()}');
    buffer.writeln('Recommendation: ${getStudyRecommendation()}');
    return buffer.toString();
  }

  // ── Validation ───────────────────────────────────────────────────────────

  static List<ValidationIssue> validateSubjects(List<GPASubject> subjects) {
    final issues = <ValidationIssue>[];
    final names = <String>[];

    for (final subject in subjects) {
      if (names.contains(subject.name.toLowerCase())) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.duplicateName,
          subject: subject.name,
          message: 'Duplicate subject name: ${subject.name}',
        ));
      }
      names.add(subject.name.toLowerCase());
    }

    for (final subject in subjects) {
      if (subject.creditHours > 4) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.unusualCreditHours,
          subject: subject.name,
          message:
              'Unusual credit hours (${subject.creditHours}) for ${subject.name}',
        ));
      }
    }

    final totalCredits =
        subjects.fold(0, (sum, s) => sum + s.creditHours);
    if (totalCredits > 20) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.excessiveTotalCredits,
        subject: 'All subjects',
        message:
            'Total credit hours ($totalCredits) seems excessive for one semester',
      ));
    }

    return issues;
  }
}

// ── Enums ─────────────────────────────────────────────────────────────────────

enum PerformanceLevel { excellent, veryGood, good, acceptable, failing }

enum ValidationIssueType {
  duplicateName,
  unusualCreditHours,
  excessiveTotalCredits,
  invalidGradePoint,
  invalidCreditHours,
  emptyName,
}

class ValidationIssue {
  final ValidationIssueType type;
  final String subject;
  final String message;

  ValidationIssue({
    required this.type,
    required this.subject,
    required this.message,
  });

  @override
  String toString() =>
      'ValidationIssue(type: $type, subject: $subject, message: $message)';
}
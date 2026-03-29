
// ─── SubjectScheduleEntry ────────────────────────────────────────────────────

class SubjectScheduleEntry {
  final String subjectName;
  final int row;
  final int col;
  final String sessionType;
  final String id;

  /// subjectId الموحَّد — مرجع إلى Subject.id
  final String subjectId;

  const SubjectScheduleEntry({
    required this.subjectName,
    required this.row,
    required this.col,
    required this.sessionType,
    required this.id,
    required this.subjectId,
  });

  factory SubjectScheduleEntry.fromJson(Map<String, dynamic> json) {
    return SubjectScheduleEntry(
      subjectName: json['subjectName'] as String,
      row: json['row'] as int,
      col: json['col'] as int,
      sessionType: json['sessionType'] as String,
      id: json['id'] as String? ?? '${json['row']}_${json['col']}',
      subjectId: json['subjectId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'row': row,
        'col': col,
        'sessionType': sessionType,
        'id': id,
        'subjectId': subjectId,
      };

  SubjectScheduleEntry copyWith({
    String? subjectName,
    int? row,
    int? col,
    String? sessionType,
    String? id,
    String? subjectId,
  }) {
    return SubjectScheduleEntry(
      subjectName: subjectName ?? this.subjectName,
      row: row ?? this.row,
      col: col ?? this.col,
      sessionType: sessionType ?? this.sessionType,
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectScheduleEntry &&
          subjectName == other.subjectName &&
          row == other.row &&
          col == other.col &&
          sessionType == other.sessionType &&
          id == other.id &&
          subjectId == other.subjectId;

  @override
  int get hashCode =>
      Object.hash(id, subjectId, subjectName, row, col, sessionType);
}
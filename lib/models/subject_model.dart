import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/stable_hash.dart';

class Subject {
  final String id;
  final String semesterId;
  final String name;
  final int difficulty;
  final DateTime createdAt;

  const Subject._({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.difficulty,
    required this.createdAt,
  });

  factory Subject({
    required String id,
    required String semesterId,
    required String name,
    required int difficulty,
    required DateTime createdAt,
  }) {
    if (id.isEmpty) throw ArgumentError('id cannot be empty');
    if (semesterId.isEmpty) throw ArgumentError('semesterId cannot be empty');
    if (name.trim().isEmpty) throw ArgumentError('name cannot be empty');
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError('difficulty must be between 1 and 5');
    }

    return Subject._(
      id: id,
      semesterId: semesterId,
      name: name.trim(),
      difficulty: difficulty,
      createdAt: createdAt,
    );
  }

  static String generateId(String semesterId, String name) {
    final normalized = name.trim().toLowerCase();
    final hash = stableHash(normalized);
    return 'subj_${semesterId}_$hash';
  }

  factory Subject.create({
    required String semesterId,
    required String name,
    required int difficulty,
  }) {
    return Subject(
      id: generateId(semesterId, name),
      semesterId: semesterId,
      name: name.trim(),
      difficulty: difficulty,
      createdAt: DateTime.now(),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'];
    final createdAt = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.parse(rawDate as String);
    return Subject(
      id: json['id'] as String,
      semesterId: json['semesterId'] as String,
      name: json['name'] as String,
      difficulty: json['difficulty'] as int,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'semesterId': semesterId,
        'name': name,
        'difficulty': difficulty,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Map<String, dynamic> toJsonForCache() => {
        'id': id,
        'semesterId': semesterId,
        'name': name,
        'difficulty': difficulty,
        'createdAt': createdAt.toIso8601String(),
      };

  Subject copyWith({
    String? id,
    String? semesterId,
    String? name,
    int? difficulty,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          semesterId == other.semesterId &&
          name == other.name &&
          difficulty == other.difficulty;

  @override
  int get hashCode => Object.hash(id, semesterId, name, difficulty);

  @override
  String toString() =>
      'Subject(id: $id, name: $name, difficulty: $difficulty)';
}
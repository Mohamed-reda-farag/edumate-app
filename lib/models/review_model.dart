import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج مراجعة الكورس
class ReviewModel {
  final String id;       // = userId (مراجعة واحدة لكل مستخدم لكل كورس)
  final String courseId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFlagged;  // تم الإبلاغ عن محتوى مسيء

  ReviewModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isFlagged = false,
  });

  /// هل تم تعديل المراجعة بعد إنشائها
  bool get isEdited =>
      updatedAt.isAfter(createdAt.add(const Duration(seconds: 5)));

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseId': courseId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isFlagged': isFlagged,
      };

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return ReviewModel(
      id: docId,
      courseId: map['courseId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'مستخدم',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment']?.toString() ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      isFlagged: map['isFlagged'] as bool? ?? false,
    );
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) =>
      ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  ReviewModel copyWith({
    double? rating,
    String? comment,
    DateTime? updatedAt,
    bool? isFlagged,
  }) =>
      ReviewModel(
        id: id,
        courseId: courseId,
        userId: userId,
        userName: userName,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isFlagged: isFlagged ?? this.isFlagged,
      );
}
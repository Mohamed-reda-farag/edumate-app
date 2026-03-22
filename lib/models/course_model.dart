import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_model.freezed.dart';
part 'course_model.g.dart';

/// نموذج الكورس (Course)
@freezed
abstract class CourseModel with _$CourseModel {
  const factory CourseModel({
    required String id,
    required String title,
    required String description,
    required String platform,
    required String language,
    required String level,
    required String price, // free, paid, freemium
    @Default(0) double priceAmount,
    required String duration,
    required double rating,
    required int enrollments,
    required String link,
    required String instructor,
    required String lastUpdated,
    required bool hasSubtitles,
    required List<String> subtitleLanguages,
    required bool hasCertificate,
    String? thumbnailUrl,
    required String skillId,
    @Default([]) List<LessonModel> lessons,
  }) = _CourseModel;

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);
}


/// نموذج الدرس
@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String title,
    required int order,
    required String duration,   // مثال: '20 minutes'
    @Default('') String description,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);
}
import 'package:freezed_annotation/freezed_annotation.dart';
import 'course_model.dart';

part 'skill_model.freezed.dart';
part 'skill_model.g.dart';

/// نموذج المهارة (Skill)
@freezed
abstract class SkillModel with _$SkillModel {
  const factory SkillModel({
    required String id,
    required String name,
    required String nameEn,
    required String description,
    required String icon,
    required String level,
    required int importance,
    required bool isMandatory,
    required List<String> prerequisites,
    required String estimatedDuration,
    required String difficulty,
    required String fieldId,
    required List<String> whatYouWillLearn,
    required List<String> realWorldApplications,
    required List<CourseModel> courses,
    required List<LearningPath> learningPaths,
    required List<ProjectIdea> practiceProjects,
  }) = _SkillModel;

  factory SkillModel.fromJson(Map<String, dynamic> json) =>
      _$SkillModelFromJson(json);
}

/// مسار التعلم
@freezed
abstract class LearningPath with _$LearningPath {
  const factory LearningPath({
    required int order,
    required String title,
    required String description,
    required List<String> topics,
    required String estimatedDuration,
  }) = _LearningPath;

  factory LearningPath.fromJson(Map<String, dynamic> json) =>
      _$LearningPathFromJson(json);
}

/// فكرة مشروع تطبيقي
@freezed
abstract class ProjectIdea with _$ProjectIdea {
  const factory ProjectIdea({
    required String title,
    required String description,
    required String difficulty,
    required String estimatedTime,
    required List<String> skillsUsed,
    required List<String> steps,
  }) = _ProjectIdea;

  factory ProjectIdea.fromJson(Map<String, dynamic> json) =>
      _$ProjectIdeaFromJson(json);
}
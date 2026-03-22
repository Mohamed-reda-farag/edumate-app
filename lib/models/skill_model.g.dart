// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SkillModel _$SkillModelFromJson(Map<String, dynamic> json) => _SkillModel(
  id: json['id'] as String,
  name: json['name'] as String,
  nameEn: json['nameEn'] as String,
  description: json['description'] as String,
  icon: json['icon'] as String,
  level: json['level'] as String,
  importance: (json['importance'] as num).toInt(),
  isMandatory: json['isMandatory'] as bool,
  prerequisites:
      (json['prerequisites'] as List<dynamic>).map((e) => e as String).toList(),
  estimatedDuration: json['estimatedDuration'] as String,
  difficulty: json['difficulty'] as String,
  fieldId: json['fieldId'] as String,
  whatYouWillLearn:
      (json['whatYouWillLearn'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  realWorldApplications:
      (json['realWorldApplications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  courses:
      (json['courses'] as List<dynamic>)
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
  learningPaths:
      (json['learningPaths'] as List<dynamic>)
          .map((e) => LearningPath.fromJson(e as Map<String, dynamic>))
          .toList(),
  practiceProjects:
      (json['practiceProjects'] as List<dynamic>)
          .map((e) => ProjectIdea.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$SkillModelToJson(_SkillModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameEn': instance.nameEn,
      'description': instance.description,
      'icon': instance.icon,
      'level': instance.level,
      'importance': instance.importance,
      'isMandatory': instance.isMandatory,
      'prerequisites': instance.prerequisites,
      'estimatedDuration': instance.estimatedDuration,
      'difficulty': instance.difficulty,
      'fieldId': instance.fieldId,
      'whatYouWillLearn': instance.whatYouWillLearn,
      'realWorldApplications': instance.realWorldApplications,
      'courses': instance.courses,
      'learningPaths': instance.learningPaths,
      'practiceProjects': instance.practiceProjects,
    };

_LearningPath _$LearningPathFromJson(Map<String, dynamic> json) =>
    _LearningPath(
      order: (json['order'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      topics:
          (json['topics'] as List<dynamic>).map((e) => e as String).toList(),
      estimatedDuration: json['estimatedDuration'] as String,
    );

Map<String, dynamic> _$LearningPathToJson(_LearningPath instance) =>
    <String, dynamic>{
      'order': instance.order,
      'title': instance.title,
      'description': instance.description,
      'topics': instance.topics,
      'estimatedDuration': instance.estimatedDuration,
    };

_ProjectIdea _$ProjectIdeaFromJson(Map<String, dynamic> json) => _ProjectIdea(
  title: json['title'] as String,
  description: json['description'] as String,
  difficulty: json['difficulty'] as String,
  estimatedTime: json['estimatedTime'] as String,
  skillsUsed:
      (json['skillsUsed'] as List<dynamic>).map((e) => e as String).toList(),
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ProjectIdeaToJson(_ProjectIdea instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'difficulty': instance.difficulty,
      'estimatedTime': instance.estimatedTime,
      'skillsUsed': instance.skillsUsed,
      'steps': instance.steps,
    };

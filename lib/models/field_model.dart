import 'package:freezed_annotation/freezed_annotation.dart';
import 'skill_model.dart';

part 'field_model.freezed.dart';
part 'field_model.g.dart';

/// نموذج المجال الهندسي (Engineering Field)
@freezed
abstract class FieldModel with _$FieldModel {
  const factory FieldModel({
    required String id,
    required String name,
    required String nameEn,
    required String description,
    required String icon,
    required String category,
    required List<String> careerPaths,
    required List<String> egyptianCompanies,
    required List<String> globalCompanies,
    required SalaryRange salaryRange,
    required int demandLevel,
    required String estimatedDuration,
    required int totalSkills,
    required RoadmapData roadmap,
    required Map<String, SkillModel> skills,
  }) = _FieldModel;

  factory FieldModel.fromJson(Map<String, dynamic> json) =>
      _$FieldModelFromJson(json);
}

/// نطاق الراتب
@freezed
abstract class SalaryRange with _$SalaryRange {
  const factory SalaryRange({
    required String beginner,
    required String intermediate,
    required String expert,
  }) = _SalaryRange;

  factory SalaryRange.fromJson(Map<String, dynamic> json) =>
      _$SalaryRangeFromJson(json);
}

/// بيانات خريطة الطريق
@freezed
abstract class RoadmapData with _$RoadmapData {
  const factory RoadmapData({
    required List<RoadmapNode> nodes,
    required List<RoadmapEdge> edges,
  }) = _RoadmapData;

  factory RoadmapData.fromJson(Map<String, dynamic> json) =>
      _$RoadmapDataFromJson(json);
}

/// عقدة في خريطة الطريق
@freezed
abstract class RoadmapNode with _$RoadmapNode {
  const factory RoadmapNode({
    required String skillId,
    required String skillName,
    required String level,
    required NodePosition position,
    required int order,
  }) = _RoadmapNode;

  factory RoadmapNode.fromJson(Map<String, dynamic> json) =>
      _$RoadmapNodeFromJson(json);
}

/// موقع العقدة
@freezed
abstract class NodePosition with _$NodePosition {
  const factory NodePosition({
    required double x,
    required double y,
  }) = _NodePosition;

  factory NodePosition.fromJson(Map<String, dynamic> json) =>
      _$NodePositionFromJson(json);
}

/// حافة/رابط بين العقد
@freezed
abstract class RoadmapEdge with _$RoadmapEdge {
  const factory RoadmapEdge({
    required String from,
    required String to,
    required String type,
  }) = _RoadmapEdge;

  factory RoadmapEdge.fromJson(Map<String, dynamic> json) =>
      _$RoadmapEdgeFromJson(json);
}

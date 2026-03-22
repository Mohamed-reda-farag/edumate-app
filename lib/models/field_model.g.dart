// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FieldModel _$FieldModelFromJson(Map<String, dynamic> json) => _FieldModel(
  id: json['id'] as String,
  name: json['name'] as String,
  nameEn: json['nameEn'] as String,
  description: json['description'] as String,
  icon: json['icon'] as String,
  category: json['category'] as String,
  careerPaths:
      (json['careerPaths'] as List<dynamic>).map((e) => e as String).toList(),
  egyptianCompanies:
      (json['egyptianCompanies'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  globalCompanies:
      (json['globalCompanies'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  salaryRange: SalaryRange.fromJson(
    json['salaryRange'] as Map<String, dynamic>,
  ),
  demandLevel: (json['demandLevel'] as num).toInt(),
  estimatedDuration: json['estimatedDuration'] as String,
  totalSkills: (json['totalSkills'] as num).toInt(),
  roadmap: RoadmapData.fromJson(json['roadmap'] as Map<String, dynamic>),
  skills: (json['skills'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, SkillModel.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$FieldModelToJson(_FieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameEn': instance.nameEn,
      'description': instance.description,
      'icon': instance.icon,
      'category': instance.category,
      'careerPaths': instance.careerPaths,
      'egyptianCompanies': instance.egyptianCompanies,
      'globalCompanies': instance.globalCompanies,
      'salaryRange': instance.salaryRange,
      'demandLevel': instance.demandLevel,
      'estimatedDuration': instance.estimatedDuration,
      'totalSkills': instance.totalSkills,
      'roadmap': instance.roadmap,
      'skills': instance.skills,
    };

_SalaryRange _$SalaryRangeFromJson(Map<String, dynamic> json) => _SalaryRange(
  beginner: json['beginner'] as String,
  intermediate: json['intermediate'] as String,
  expert: json['expert'] as String,
);

Map<String, dynamic> _$SalaryRangeToJson(_SalaryRange instance) =>
    <String, dynamic>{
      'beginner': instance.beginner,
      'intermediate': instance.intermediate,
      'expert': instance.expert,
    };

_RoadmapData _$RoadmapDataFromJson(Map<String, dynamic> json) => _RoadmapData(
  nodes:
      (json['nodes'] as List<dynamic>)
          .map((e) => RoadmapNode.fromJson(e as Map<String, dynamic>))
          .toList(),
  edges:
      (json['edges'] as List<dynamic>)
          .map((e) => RoadmapEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$RoadmapDataToJson(_RoadmapData instance) =>
    <String, dynamic>{'nodes': instance.nodes, 'edges': instance.edges};

_RoadmapNode _$RoadmapNodeFromJson(Map<String, dynamic> json) => _RoadmapNode(
  skillId: json['skillId'] as String,
  skillName: json['skillName'] as String,
  level: json['level'] as String,
  position: NodePosition.fromJson(json['position'] as Map<String, dynamic>),
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$RoadmapNodeToJson(_RoadmapNode instance) =>
    <String, dynamic>{
      'skillId': instance.skillId,
      'skillName': instance.skillName,
      'level': instance.level,
      'position': instance.position,
      'order': instance.order,
    };

_NodePosition _$NodePositionFromJson(Map<String, dynamic> json) =>
    _NodePosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$NodePositionToJson(_NodePosition instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

_RoadmapEdge _$RoadmapEdgeFromJson(Map<String, dynamic> json) => _RoadmapEdge(
  from: json['from'] as String,
  to: json['to'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$RoadmapEdgeToJson(_RoadmapEdge instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'type': instance.type,
    };

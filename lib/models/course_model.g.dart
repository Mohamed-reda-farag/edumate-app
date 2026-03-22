// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => _CourseModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  platform: json['platform'] as String,
  language: json['language'] as String,
  level: json['level'] as String,
  price: json['price'] as String,
  priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
  duration: json['duration'] as String,
  rating: (json['rating'] as num).toDouble(),
  enrollments: (json['enrollments'] as num).toInt(),
  link: json['link'] as String,
  instructor: json['instructor'] as String,
  lastUpdated: json['lastUpdated'] as String,
  hasSubtitles: json['hasSubtitles'] as bool,
  subtitleLanguages:
      (json['subtitleLanguages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  hasCertificate: json['hasCertificate'] as bool,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  skillId: json['skillId'] as String,
  lessons:
      (json['lessons'] as List<dynamic>?)
          ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$CourseModelToJson(_CourseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'platform': instance.platform,
      'language': instance.language,
      'level': instance.level,
      'price': instance.price,
      'priceAmount': instance.priceAmount,
      'duration': instance.duration,
      'rating': instance.rating,
      'enrollments': instance.enrollments,
      'link': instance.link,
      'instructor': instance.instructor,
      'lastUpdated': instance.lastUpdated,
      'hasSubtitles': instance.hasSubtitles,
      'subtitleLanguages': instance.subtitleLanguages,
      'hasCertificate': instance.hasCertificate,
      'thumbnailUrl': instance.thumbnailUrl,
      'skillId': instance.skillId,
      'lessons': instance.lessons,
    };

_LessonModel _$LessonModelFromJson(Map<String, dynamic> json) => _LessonModel(
  id: json['id'] as String,
  title: json['title'] as String,
  order: (json['order'] as num).toInt(),
  duration: json['duration'] as String,
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$LessonModelToJson(_LessonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'order': instance.order,
      'duration': instance.duration,
      'description': instance.description,
    };

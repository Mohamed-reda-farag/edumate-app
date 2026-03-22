// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SkillModel {

 String get id; String get name; String get nameEn; String get description; String get icon; String get level; int get importance; bool get isMandatory; List<String> get prerequisites; String get estimatedDuration; String get difficulty; String get fieldId; List<String> get whatYouWillLearn; List<String> get realWorldApplications; List<CourseModel> get courses; List<LearningPath> get learningPaths; List<ProjectIdea> get practiceProjects;
/// Create a copy of SkillModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillModelCopyWith<SkillModel> get copyWith => _$SkillModelCopyWithImpl<SkillModel>(this as SkillModel, _$identity);

  /// Serializes this SkillModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.level, level) || other.level == level)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory)&&const DeepCollectionEquality().equals(other.prerequisites, prerequisites)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&const DeepCollectionEquality().equals(other.whatYouWillLearn, whatYouWillLearn)&&const DeepCollectionEquality().equals(other.realWorldApplications, realWorldApplications)&&const DeepCollectionEquality().equals(other.courses, courses)&&const DeepCollectionEquality().equals(other.learningPaths, learningPaths)&&const DeepCollectionEquality().equals(other.practiceProjects, practiceProjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameEn,description,icon,level,importance,isMandatory,const DeepCollectionEquality().hash(prerequisites),estimatedDuration,difficulty,fieldId,const DeepCollectionEquality().hash(whatYouWillLearn),const DeepCollectionEquality().hash(realWorldApplications),const DeepCollectionEquality().hash(courses),const DeepCollectionEquality().hash(learningPaths),const DeepCollectionEquality().hash(practiceProjects));

@override
String toString() {
  return 'SkillModel(id: $id, name: $name, nameEn: $nameEn, description: $description, icon: $icon, level: $level, importance: $importance, isMandatory: $isMandatory, prerequisites: $prerequisites, estimatedDuration: $estimatedDuration, difficulty: $difficulty, fieldId: $fieldId, whatYouWillLearn: $whatYouWillLearn, realWorldApplications: $realWorldApplications, courses: $courses, learningPaths: $learningPaths, practiceProjects: $practiceProjects)';
}


}

/// @nodoc
abstract mixin class $SkillModelCopyWith<$Res>  {
  factory $SkillModelCopyWith(SkillModel value, $Res Function(SkillModel) _then) = _$SkillModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String nameEn, String description, String icon, String level, int importance, bool isMandatory, List<String> prerequisites, String estimatedDuration, String difficulty, String fieldId, List<String> whatYouWillLearn, List<String> realWorldApplications, List<CourseModel> courses, List<LearningPath> learningPaths, List<ProjectIdea> practiceProjects
});




}
/// @nodoc
class _$SkillModelCopyWithImpl<$Res>
    implements $SkillModelCopyWith<$Res> {
  _$SkillModelCopyWithImpl(this._self, this._then);

  final SkillModel _self;
  final $Res Function(SkillModel) _then;

/// Create a copy of SkillModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameEn = null,Object? description = null,Object? icon = null,Object? level = null,Object? importance = null,Object? isMandatory = null,Object? prerequisites = null,Object? estimatedDuration = null,Object? difficulty = null,Object? fieldId = null,Object? whatYouWillLearn = null,Object? realWorldApplications = null,Object? courses = null,Object? learningPaths = null,Object? practiceProjects = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as int,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,prerequisites: null == prerequisites ? _self.prerequisites : prerequisites // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedDuration: null == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,fieldId: null == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String,whatYouWillLearn: null == whatYouWillLearn ? _self.whatYouWillLearn : whatYouWillLearn // ignore: cast_nullable_to_non_nullable
as List<String>,realWorldApplications: null == realWorldApplications ? _self.realWorldApplications : realWorldApplications // ignore: cast_nullable_to_non_nullable
as List<String>,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<CourseModel>,learningPaths: null == learningPaths ? _self.learningPaths : learningPaths // ignore: cast_nullable_to_non_nullable
as List<LearningPath>,practiceProjects: null == practiceProjects ? _self.practiceProjects : practiceProjects // ignore: cast_nullable_to_non_nullable
as List<ProjectIdea>,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillModel].
extension SkillModelPatterns on SkillModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillModel value)  $default,){
final _that = this;
switch (_that) {
case _SkillModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillModel value)?  $default,){
final _that = this;
switch (_that) {
case _SkillModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String nameEn,  String description,  String icon,  String level,  int importance,  bool isMandatory,  List<String> prerequisites,  String estimatedDuration,  String difficulty,  String fieldId,  List<String> whatYouWillLearn,  List<String> realWorldApplications,  List<CourseModel> courses,  List<LearningPath> learningPaths,  List<ProjectIdea> practiceProjects)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillModel() when $default != null:
return $default(_that.id,_that.name,_that.nameEn,_that.description,_that.icon,_that.level,_that.importance,_that.isMandatory,_that.prerequisites,_that.estimatedDuration,_that.difficulty,_that.fieldId,_that.whatYouWillLearn,_that.realWorldApplications,_that.courses,_that.learningPaths,_that.practiceProjects);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String nameEn,  String description,  String icon,  String level,  int importance,  bool isMandatory,  List<String> prerequisites,  String estimatedDuration,  String difficulty,  String fieldId,  List<String> whatYouWillLearn,  List<String> realWorldApplications,  List<CourseModel> courses,  List<LearningPath> learningPaths,  List<ProjectIdea> practiceProjects)  $default,) {final _that = this;
switch (_that) {
case _SkillModel():
return $default(_that.id,_that.name,_that.nameEn,_that.description,_that.icon,_that.level,_that.importance,_that.isMandatory,_that.prerequisites,_that.estimatedDuration,_that.difficulty,_that.fieldId,_that.whatYouWillLearn,_that.realWorldApplications,_that.courses,_that.learningPaths,_that.practiceProjects);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String nameEn,  String description,  String icon,  String level,  int importance,  bool isMandatory,  List<String> prerequisites,  String estimatedDuration,  String difficulty,  String fieldId,  List<String> whatYouWillLearn,  List<String> realWorldApplications,  List<CourseModel> courses,  List<LearningPath> learningPaths,  List<ProjectIdea> practiceProjects)?  $default,) {final _that = this;
switch (_that) {
case _SkillModel() when $default != null:
return $default(_that.id,_that.name,_that.nameEn,_that.description,_that.icon,_that.level,_that.importance,_that.isMandatory,_that.prerequisites,_that.estimatedDuration,_that.difficulty,_that.fieldId,_that.whatYouWillLearn,_that.realWorldApplications,_that.courses,_that.learningPaths,_that.practiceProjects);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkillModel implements SkillModel {
  const _SkillModel({required this.id, required this.name, required this.nameEn, required this.description, required this.icon, required this.level, required this.importance, required this.isMandatory, required final  List<String> prerequisites, required this.estimatedDuration, required this.difficulty, required this.fieldId, required final  List<String> whatYouWillLearn, required final  List<String> realWorldApplications, required final  List<CourseModel> courses, required final  List<LearningPath> learningPaths, required final  List<ProjectIdea> practiceProjects}): _prerequisites = prerequisites,_whatYouWillLearn = whatYouWillLearn,_realWorldApplications = realWorldApplications,_courses = courses,_learningPaths = learningPaths,_practiceProjects = practiceProjects;
  factory _SkillModel.fromJson(Map<String, dynamic> json) => _$SkillModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String nameEn;
@override final  String description;
@override final  String icon;
@override final  String level;
@override final  int importance;
@override final  bool isMandatory;
 final  List<String> _prerequisites;
@override List<String> get prerequisites {
  if (_prerequisites is EqualUnmodifiableListView) return _prerequisites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prerequisites);
}

@override final  String estimatedDuration;
@override final  String difficulty;
@override final  String fieldId;
 final  List<String> _whatYouWillLearn;
@override List<String> get whatYouWillLearn {
  if (_whatYouWillLearn is EqualUnmodifiableListView) return _whatYouWillLearn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whatYouWillLearn);
}

 final  List<String> _realWorldApplications;
@override List<String> get realWorldApplications {
  if (_realWorldApplications is EqualUnmodifiableListView) return _realWorldApplications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_realWorldApplications);
}

 final  List<CourseModel> _courses;
@override List<CourseModel> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

 final  List<LearningPath> _learningPaths;
@override List<LearningPath> get learningPaths {
  if (_learningPaths is EqualUnmodifiableListView) return _learningPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_learningPaths);
}

 final  List<ProjectIdea> _practiceProjects;
@override List<ProjectIdea> get practiceProjects {
  if (_practiceProjects is EqualUnmodifiableListView) return _practiceProjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_practiceProjects);
}


/// Create a copy of SkillModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillModelCopyWith<_SkillModel> get copyWith => __$SkillModelCopyWithImpl<_SkillModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkillModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.level, level) || other.level == level)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory)&&const DeepCollectionEquality().equals(other._prerequisites, _prerequisites)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&const DeepCollectionEquality().equals(other._whatYouWillLearn, _whatYouWillLearn)&&const DeepCollectionEquality().equals(other._realWorldApplications, _realWorldApplications)&&const DeepCollectionEquality().equals(other._courses, _courses)&&const DeepCollectionEquality().equals(other._learningPaths, _learningPaths)&&const DeepCollectionEquality().equals(other._practiceProjects, _practiceProjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameEn,description,icon,level,importance,isMandatory,const DeepCollectionEquality().hash(_prerequisites),estimatedDuration,difficulty,fieldId,const DeepCollectionEquality().hash(_whatYouWillLearn),const DeepCollectionEquality().hash(_realWorldApplications),const DeepCollectionEquality().hash(_courses),const DeepCollectionEquality().hash(_learningPaths),const DeepCollectionEquality().hash(_practiceProjects));

@override
String toString() {
  return 'SkillModel(id: $id, name: $name, nameEn: $nameEn, description: $description, icon: $icon, level: $level, importance: $importance, isMandatory: $isMandatory, prerequisites: $prerequisites, estimatedDuration: $estimatedDuration, difficulty: $difficulty, fieldId: $fieldId, whatYouWillLearn: $whatYouWillLearn, realWorldApplications: $realWorldApplications, courses: $courses, learningPaths: $learningPaths, practiceProjects: $practiceProjects)';
}


}

/// @nodoc
abstract mixin class _$SkillModelCopyWith<$Res> implements $SkillModelCopyWith<$Res> {
  factory _$SkillModelCopyWith(_SkillModel value, $Res Function(_SkillModel) _then) = __$SkillModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String nameEn, String description, String icon, String level, int importance, bool isMandatory, List<String> prerequisites, String estimatedDuration, String difficulty, String fieldId, List<String> whatYouWillLearn, List<String> realWorldApplications, List<CourseModel> courses, List<LearningPath> learningPaths, List<ProjectIdea> practiceProjects
});




}
/// @nodoc
class __$SkillModelCopyWithImpl<$Res>
    implements _$SkillModelCopyWith<$Res> {
  __$SkillModelCopyWithImpl(this._self, this._then);

  final _SkillModel _self;
  final $Res Function(_SkillModel) _then;

/// Create a copy of SkillModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameEn = null,Object? description = null,Object? icon = null,Object? level = null,Object? importance = null,Object? isMandatory = null,Object? prerequisites = null,Object? estimatedDuration = null,Object? difficulty = null,Object? fieldId = null,Object? whatYouWillLearn = null,Object? realWorldApplications = null,Object? courses = null,Object? learningPaths = null,Object? practiceProjects = null,}) {
  return _then(_SkillModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as int,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,prerequisites: null == prerequisites ? _self._prerequisites : prerequisites // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedDuration: null == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,fieldId: null == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String,whatYouWillLearn: null == whatYouWillLearn ? _self._whatYouWillLearn : whatYouWillLearn // ignore: cast_nullable_to_non_nullable
as List<String>,realWorldApplications: null == realWorldApplications ? _self._realWorldApplications : realWorldApplications // ignore: cast_nullable_to_non_nullable
as List<String>,courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<CourseModel>,learningPaths: null == learningPaths ? _self._learningPaths : learningPaths // ignore: cast_nullable_to_non_nullable
as List<LearningPath>,practiceProjects: null == practiceProjects ? _self._practiceProjects : practiceProjects // ignore: cast_nullable_to_non_nullable
as List<ProjectIdea>,
  ));
}


}


/// @nodoc
mixin _$LearningPath {

 int get order; String get title; String get description; List<String> get topics; String get estimatedDuration;
/// Create a copy of LearningPath
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearningPathCopyWith<LearningPath> get copyWith => _$LearningPathCopyWithImpl<LearningPath>(this as LearningPath, _$identity);

  /// Serializes this LearningPath to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearningPath&&(identical(other.order, order) || other.order == order)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,order,title,description,const DeepCollectionEquality().hash(topics),estimatedDuration);

@override
String toString() {
  return 'LearningPath(order: $order, title: $title, description: $description, topics: $topics, estimatedDuration: $estimatedDuration)';
}


}

/// @nodoc
abstract mixin class $LearningPathCopyWith<$Res>  {
  factory $LearningPathCopyWith(LearningPath value, $Res Function(LearningPath) _then) = _$LearningPathCopyWithImpl;
@useResult
$Res call({
 int order, String title, String description, List<String> topics, String estimatedDuration
});




}
/// @nodoc
class _$LearningPathCopyWithImpl<$Res>
    implements $LearningPathCopyWith<$Res> {
  _$LearningPathCopyWithImpl(this._self, this._then);

  final LearningPath _self;
  final $Res Function(LearningPath) _then;

/// Create a copy of LearningPath
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? order = null,Object? title = null,Object? description = null,Object? topics = null,Object? estimatedDuration = null,}) {
  return _then(_self.copyWith(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedDuration: null == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LearningPath].
extension LearningPathPatterns on LearningPath {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearningPath value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearningPath() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearningPath value)  $default,){
final _that = this;
switch (_that) {
case _LearningPath():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearningPath value)?  $default,){
final _that = this;
switch (_that) {
case _LearningPath() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int order,  String title,  String description,  List<String> topics,  String estimatedDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearningPath() when $default != null:
return $default(_that.order,_that.title,_that.description,_that.topics,_that.estimatedDuration);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int order,  String title,  String description,  List<String> topics,  String estimatedDuration)  $default,) {final _that = this;
switch (_that) {
case _LearningPath():
return $default(_that.order,_that.title,_that.description,_that.topics,_that.estimatedDuration);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int order,  String title,  String description,  List<String> topics,  String estimatedDuration)?  $default,) {final _that = this;
switch (_that) {
case _LearningPath() when $default != null:
return $default(_that.order,_that.title,_that.description,_that.topics,_that.estimatedDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearningPath implements LearningPath {
  const _LearningPath({required this.order, required this.title, required this.description, required final  List<String> topics, required this.estimatedDuration}): _topics = topics;
  factory _LearningPath.fromJson(Map<String, dynamic> json) => _$LearningPathFromJson(json);

@override final  int order;
@override final  String title;
@override final  String description;
 final  List<String> _topics;
@override List<String> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

@override final  String estimatedDuration;

/// Create a copy of LearningPath
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearningPathCopyWith<_LearningPath> get copyWith => __$LearningPathCopyWithImpl<_LearningPath>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearningPathToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearningPath&&(identical(other.order, order) || other.order == order)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,order,title,description,const DeepCollectionEquality().hash(_topics),estimatedDuration);

@override
String toString() {
  return 'LearningPath(order: $order, title: $title, description: $description, topics: $topics, estimatedDuration: $estimatedDuration)';
}


}

/// @nodoc
abstract mixin class _$LearningPathCopyWith<$Res> implements $LearningPathCopyWith<$Res> {
  factory _$LearningPathCopyWith(_LearningPath value, $Res Function(_LearningPath) _then) = __$LearningPathCopyWithImpl;
@override @useResult
$Res call({
 int order, String title, String description, List<String> topics, String estimatedDuration
});




}
/// @nodoc
class __$LearningPathCopyWithImpl<$Res>
    implements _$LearningPathCopyWith<$Res> {
  __$LearningPathCopyWithImpl(this._self, this._then);

  final _LearningPath _self;
  final $Res Function(_LearningPath) _then;

/// Create a copy of LearningPath
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? order = null,Object? title = null,Object? description = null,Object? topics = null,Object? estimatedDuration = null,}) {
  return _then(_LearningPath(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedDuration: null == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProjectIdea {

 String get title; String get description; String get difficulty; String get estimatedTime; List<String> get skillsUsed; List<String> get steps;
/// Create a copy of ProjectIdea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectIdeaCopyWith<ProjectIdea> get copyWith => _$ProjectIdeaCopyWithImpl<ProjectIdea>(this as ProjectIdea, _$identity);

  /// Serializes this ProjectIdea to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectIdea&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.estimatedTime, estimatedTime) || other.estimatedTime == estimatedTime)&&const DeepCollectionEquality().equals(other.skillsUsed, skillsUsed)&&const DeepCollectionEquality().equals(other.steps, steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,difficulty,estimatedTime,const DeepCollectionEquality().hash(skillsUsed),const DeepCollectionEquality().hash(steps));

@override
String toString() {
  return 'ProjectIdea(title: $title, description: $description, difficulty: $difficulty, estimatedTime: $estimatedTime, skillsUsed: $skillsUsed, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $ProjectIdeaCopyWith<$Res>  {
  factory $ProjectIdeaCopyWith(ProjectIdea value, $Res Function(ProjectIdea) _then) = _$ProjectIdeaCopyWithImpl;
@useResult
$Res call({
 String title, String description, String difficulty, String estimatedTime, List<String> skillsUsed, List<String> steps
});




}
/// @nodoc
class _$ProjectIdeaCopyWithImpl<$Res>
    implements $ProjectIdeaCopyWith<$Res> {
  _$ProjectIdeaCopyWithImpl(this._self, this._then);

  final ProjectIdea _self;
  final $Res Function(ProjectIdea) _then;

/// Create a copy of ProjectIdea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? difficulty = null,Object? estimatedTime = null,Object? skillsUsed = null,Object? steps = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,estimatedTime: null == estimatedTime ? _self.estimatedTime : estimatedTime // ignore: cast_nullable_to_non_nullable
as String,skillsUsed: null == skillsUsed ? _self.skillsUsed : skillsUsed // ignore: cast_nullable_to_non_nullable
as List<String>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectIdea].
extension ProjectIdeaPatterns on ProjectIdea {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectIdea value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectIdea() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectIdea value)  $default,){
final _that = this;
switch (_that) {
case _ProjectIdea():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectIdea value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectIdea() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String difficulty,  String estimatedTime,  List<String> skillsUsed,  List<String> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectIdea() when $default != null:
return $default(_that.title,_that.description,_that.difficulty,_that.estimatedTime,_that.skillsUsed,_that.steps);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String difficulty,  String estimatedTime,  List<String> skillsUsed,  List<String> steps)  $default,) {final _that = this;
switch (_that) {
case _ProjectIdea():
return $default(_that.title,_that.description,_that.difficulty,_that.estimatedTime,_that.skillsUsed,_that.steps);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String difficulty,  String estimatedTime,  List<String> skillsUsed,  List<String> steps)?  $default,) {final _that = this;
switch (_that) {
case _ProjectIdea() when $default != null:
return $default(_that.title,_that.description,_that.difficulty,_that.estimatedTime,_that.skillsUsed,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectIdea implements ProjectIdea {
  const _ProjectIdea({required this.title, required this.description, required this.difficulty, required this.estimatedTime, required final  List<String> skillsUsed, required final  List<String> steps}): _skillsUsed = skillsUsed,_steps = steps;
  factory _ProjectIdea.fromJson(Map<String, dynamic> json) => _$ProjectIdeaFromJson(json);

@override final  String title;
@override final  String description;
@override final  String difficulty;
@override final  String estimatedTime;
 final  List<String> _skillsUsed;
@override List<String> get skillsUsed {
  if (_skillsUsed is EqualUnmodifiableListView) return _skillsUsed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skillsUsed);
}

 final  List<String> _steps;
@override List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of ProjectIdea
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectIdeaCopyWith<_ProjectIdea> get copyWith => __$ProjectIdeaCopyWithImpl<_ProjectIdea>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectIdeaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectIdea&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.estimatedTime, estimatedTime) || other.estimatedTime == estimatedTime)&&const DeepCollectionEquality().equals(other._skillsUsed, _skillsUsed)&&const DeepCollectionEquality().equals(other._steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,difficulty,estimatedTime,const DeepCollectionEquality().hash(_skillsUsed),const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'ProjectIdea(title: $title, description: $description, difficulty: $difficulty, estimatedTime: $estimatedTime, skillsUsed: $skillsUsed, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$ProjectIdeaCopyWith<$Res> implements $ProjectIdeaCopyWith<$Res> {
  factory _$ProjectIdeaCopyWith(_ProjectIdea value, $Res Function(_ProjectIdea) _then) = __$ProjectIdeaCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String difficulty, String estimatedTime, List<String> skillsUsed, List<String> steps
});




}
/// @nodoc
class __$ProjectIdeaCopyWithImpl<$Res>
    implements _$ProjectIdeaCopyWith<$Res> {
  __$ProjectIdeaCopyWithImpl(this._self, this._then);

  final _ProjectIdea _self;
  final $Res Function(_ProjectIdea) _then;

/// Create a copy of ProjectIdea
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? difficulty = null,Object? estimatedTime = null,Object? skillsUsed = null,Object? steps = null,}) {
  return _then(_ProjectIdea(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,estimatedTime: null == estimatedTime ? _self.estimatedTime : estimatedTime // ignore: cast_nullable_to_non_nullable
as String,skillsUsed: null == skillsUsed ? _self._skillsUsed : skillsUsed // ignore: cast_nullable_to_non_nullable
as List<String>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

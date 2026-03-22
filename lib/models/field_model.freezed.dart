// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FieldModel {

 String get id; String get name; String get nameEn; String get description; String get icon; String get category; List<String> get careerPaths; List<String> get egyptianCompanies; List<String> get globalCompanies; SalaryRange get salaryRange; int get demandLevel; String get estimatedDuration; int get totalSkills; RoadmapData get roadmap; Map<String, SkillModel> get skills;
/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldModelCopyWith<FieldModel> get copyWith => _$FieldModelCopyWithImpl<FieldModel>(this as FieldModel, _$identity);

  /// Serializes this FieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.careerPaths, careerPaths)&&const DeepCollectionEquality().equals(other.egyptianCompanies, egyptianCompanies)&&const DeepCollectionEquality().equals(other.globalCompanies, globalCompanies)&&(identical(other.salaryRange, salaryRange) || other.salaryRange == salaryRange)&&(identical(other.demandLevel, demandLevel) || other.demandLevel == demandLevel)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.totalSkills, totalSkills) || other.totalSkills == totalSkills)&&(identical(other.roadmap, roadmap) || other.roadmap == roadmap)&&const DeepCollectionEquality().equals(other.skills, skills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameEn,description,icon,category,const DeepCollectionEquality().hash(careerPaths),const DeepCollectionEquality().hash(egyptianCompanies),const DeepCollectionEquality().hash(globalCompanies),salaryRange,demandLevel,estimatedDuration,totalSkills,roadmap,const DeepCollectionEquality().hash(skills));

@override
String toString() {
  return 'FieldModel(id: $id, name: $name, nameEn: $nameEn, description: $description, icon: $icon, category: $category, careerPaths: $careerPaths, egyptianCompanies: $egyptianCompanies, globalCompanies: $globalCompanies, salaryRange: $salaryRange, demandLevel: $demandLevel, estimatedDuration: $estimatedDuration, totalSkills: $totalSkills, roadmap: $roadmap, skills: $skills)';
}


}

/// @nodoc
abstract mixin class $FieldModelCopyWith<$Res>  {
  factory $FieldModelCopyWith(FieldModel value, $Res Function(FieldModel) _then) = _$FieldModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String nameEn, String description, String icon, String category, List<String> careerPaths, List<String> egyptianCompanies, List<String> globalCompanies, SalaryRange salaryRange, int demandLevel, String estimatedDuration, int totalSkills, RoadmapData roadmap, Map<String, SkillModel> skills
});


$SalaryRangeCopyWith<$Res> get salaryRange;$RoadmapDataCopyWith<$Res> get roadmap;

}
/// @nodoc
class _$FieldModelCopyWithImpl<$Res>
    implements $FieldModelCopyWith<$Res> {
  _$FieldModelCopyWithImpl(this._self, this._then);

  final FieldModel _self;
  final $Res Function(FieldModel) _then;

/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameEn = null,Object? description = null,Object? icon = null,Object? category = null,Object? careerPaths = null,Object? egyptianCompanies = null,Object? globalCompanies = null,Object? salaryRange = null,Object? demandLevel = null,Object? estimatedDuration = null,Object? totalSkills = null,Object? roadmap = null,Object? skills = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,careerPaths: null == careerPaths ? _self.careerPaths : careerPaths // ignore: cast_nullable_to_non_nullable
as List<String>,egyptianCompanies: null == egyptianCompanies ? _self.egyptianCompanies : egyptianCompanies // ignore: cast_nullable_to_non_nullable
as List<String>,globalCompanies: null == globalCompanies ? _self.globalCompanies : globalCompanies // ignore: cast_nullable_to_non_nullable
as List<String>,salaryRange: null == salaryRange ? _self.salaryRange : salaryRange // ignore: cast_nullable_to_non_nullable
as SalaryRange,demandLevel: null == demandLevel ? _self.demandLevel : demandLevel // ignore: cast_nullable_to_non_nullable
as int,estimatedDuration: null == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as String,totalSkills: null == totalSkills ? _self.totalSkills : totalSkills // ignore: cast_nullable_to_non_nullable
as int,roadmap: null == roadmap ? _self.roadmap : roadmap // ignore: cast_nullable_to_non_nullable
as RoadmapData,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as Map<String, SkillModel>,
  ));
}
/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalaryRangeCopyWith<$Res> get salaryRange {
  
  return $SalaryRangeCopyWith<$Res>(_self.salaryRange, (value) {
    return _then(_self.copyWith(salaryRange: value));
  });
}/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoadmapDataCopyWith<$Res> get roadmap {
  
  return $RoadmapDataCopyWith<$Res>(_self.roadmap, (value) {
    return _then(_self.copyWith(roadmap: value));
  });
}
}


/// Adds pattern-matching-related methods to [FieldModel].
extension FieldModelPatterns on FieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String nameEn,  String description,  String icon,  String category,  List<String> careerPaths,  List<String> egyptianCompanies,  List<String> globalCompanies,  SalaryRange salaryRange,  int demandLevel,  String estimatedDuration,  int totalSkills,  RoadmapData roadmap,  Map<String, SkillModel> skills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
return $default(_that.id,_that.name,_that.nameEn,_that.description,_that.icon,_that.category,_that.careerPaths,_that.egyptianCompanies,_that.globalCompanies,_that.salaryRange,_that.demandLevel,_that.estimatedDuration,_that.totalSkills,_that.roadmap,_that.skills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String nameEn,  String description,  String icon,  String category,  List<String> careerPaths,  List<String> egyptianCompanies,  List<String> globalCompanies,  SalaryRange salaryRange,  int demandLevel,  String estimatedDuration,  int totalSkills,  RoadmapData roadmap,  Map<String, SkillModel> skills)  $default,) {final _that = this;
switch (_that) {
case _FieldModel():
return $default(_that.id,_that.name,_that.nameEn,_that.description,_that.icon,_that.category,_that.careerPaths,_that.egyptianCompanies,_that.globalCompanies,_that.salaryRange,_that.demandLevel,_that.estimatedDuration,_that.totalSkills,_that.roadmap,_that.skills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String nameEn,  String description,  String icon,  String category,  List<String> careerPaths,  List<String> egyptianCompanies,  List<String> globalCompanies,  SalaryRange salaryRange,  int demandLevel,  String estimatedDuration,  int totalSkills,  RoadmapData roadmap,  Map<String, SkillModel> skills)?  $default,) {final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
return $default(_that.id,_that.name,_that.nameEn,_that.description,_that.icon,_that.category,_that.careerPaths,_that.egyptianCompanies,_that.globalCompanies,_that.salaryRange,_that.demandLevel,_that.estimatedDuration,_that.totalSkills,_that.roadmap,_that.skills);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldModel implements FieldModel {
  const _FieldModel({required this.id, required this.name, required this.nameEn, required this.description, required this.icon, required this.category, required final  List<String> careerPaths, required final  List<String> egyptianCompanies, required final  List<String> globalCompanies, required this.salaryRange, required this.demandLevel, required this.estimatedDuration, required this.totalSkills, required this.roadmap, required final  Map<String, SkillModel> skills}): _careerPaths = careerPaths,_egyptianCompanies = egyptianCompanies,_globalCompanies = globalCompanies,_skills = skills;
  factory _FieldModel.fromJson(Map<String, dynamic> json) => _$FieldModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String nameEn;
@override final  String description;
@override final  String icon;
@override final  String category;
 final  List<String> _careerPaths;
@override List<String> get careerPaths {
  if (_careerPaths is EqualUnmodifiableListView) return _careerPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_careerPaths);
}

 final  List<String> _egyptianCompanies;
@override List<String> get egyptianCompanies {
  if (_egyptianCompanies is EqualUnmodifiableListView) return _egyptianCompanies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_egyptianCompanies);
}

 final  List<String> _globalCompanies;
@override List<String> get globalCompanies {
  if (_globalCompanies is EqualUnmodifiableListView) return _globalCompanies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_globalCompanies);
}

@override final  SalaryRange salaryRange;
@override final  int demandLevel;
@override final  String estimatedDuration;
@override final  int totalSkills;
@override final  RoadmapData roadmap;
 final  Map<String, SkillModel> _skills;
@override Map<String, SkillModel> get skills {
  if (_skills is EqualUnmodifiableMapView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skills);
}


/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldModelCopyWith<_FieldModel> get copyWith => __$FieldModelCopyWithImpl<_FieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._careerPaths, _careerPaths)&&const DeepCollectionEquality().equals(other._egyptianCompanies, _egyptianCompanies)&&const DeepCollectionEquality().equals(other._globalCompanies, _globalCompanies)&&(identical(other.salaryRange, salaryRange) || other.salaryRange == salaryRange)&&(identical(other.demandLevel, demandLevel) || other.demandLevel == demandLevel)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.totalSkills, totalSkills) || other.totalSkills == totalSkills)&&(identical(other.roadmap, roadmap) || other.roadmap == roadmap)&&const DeepCollectionEquality().equals(other._skills, _skills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameEn,description,icon,category,const DeepCollectionEquality().hash(_careerPaths),const DeepCollectionEquality().hash(_egyptianCompanies),const DeepCollectionEquality().hash(_globalCompanies),salaryRange,demandLevel,estimatedDuration,totalSkills,roadmap,const DeepCollectionEquality().hash(_skills));

@override
String toString() {
  return 'FieldModel(id: $id, name: $name, nameEn: $nameEn, description: $description, icon: $icon, category: $category, careerPaths: $careerPaths, egyptianCompanies: $egyptianCompanies, globalCompanies: $globalCompanies, salaryRange: $salaryRange, demandLevel: $demandLevel, estimatedDuration: $estimatedDuration, totalSkills: $totalSkills, roadmap: $roadmap, skills: $skills)';
}


}

/// @nodoc
abstract mixin class _$FieldModelCopyWith<$Res> implements $FieldModelCopyWith<$Res> {
  factory _$FieldModelCopyWith(_FieldModel value, $Res Function(_FieldModel) _then) = __$FieldModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String nameEn, String description, String icon, String category, List<String> careerPaths, List<String> egyptianCompanies, List<String> globalCompanies, SalaryRange salaryRange, int demandLevel, String estimatedDuration, int totalSkills, RoadmapData roadmap, Map<String, SkillModel> skills
});


@override $SalaryRangeCopyWith<$Res> get salaryRange;@override $RoadmapDataCopyWith<$Res> get roadmap;

}
/// @nodoc
class __$FieldModelCopyWithImpl<$Res>
    implements _$FieldModelCopyWith<$Res> {
  __$FieldModelCopyWithImpl(this._self, this._then);

  final _FieldModel _self;
  final $Res Function(_FieldModel) _then;

/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameEn = null,Object? description = null,Object? icon = null,Object? category = null,Object? careerPaths = null,Object? egyptianCompanies = null,Object? globalCompanies = null,Object? salaryRange = null,Object? demandLevel = null,Object? estimatedDuration = null,Object? totalSkills = null,Object? roadmap = null,Object? skills = null,}) {
  return _then(_FieldModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,careerPaths: null == careerPaths ? _self._careerPaths : careerPaths // ignore: cast_nullable_to_non_nullable
as List<String>,egyptianCompanies: null == egyptianCompanies ? _self._egyptianCompanies : egyptianCompanies // ignore: cast_nullable_to_non_nullable
as List<String>,globalCompanies: null == globalCompanies ? _self._globalCompanies : globalCompanies // ignore: cast_nullable_to_non_nullable
as List<String>,salaryRange: null == salaryRange ? _self.salaryRange : salaryRange // ignore: cast_nullable_to_non_nullable
as SalaryRange,demandLevel: null == demandLevel ? _self.demandLevel : demandLevel // ignore: cast_nullable_to_non_nullable
as int,estimatedDuration: null == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as String,totalSkills: null == totalSkills ? _self.totalSkills : totalSkills // ignore: cast_nullable_to_non_nullable
as int,roadmap: null == roadmap ? _self.roadmap : roadmap // ignore: cast_nullable_to_non_nullable
as RoadmapData,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as Map<String, SkillModel>,
  ));
}

/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalaryRangeCopyWith<$Res> get salaryRange {
  
  return $SalaryRangeCopyWith<$Res>(_self.salaryRange, (value) {
    return _then(_self.copyWith(salaryRange: value));
  });
}/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoadmapDataCopyWith<$Res> get roadmap {
  
  return $RoadmapDataCopyWith<$Res>(_self.roadmap, (value) {
    return _then(_self.copyWith(roadmap: value));
  });
}
}


/// @nodoc
mixin _$SalaryRange {

 String get beginner; String get intermediate; String get expert;
/// Create a copy of SalaryRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalaryRangeCopyWith<SalaryRange> get copyWith => _$SalaryRangeCopyWithImpl<SalaryRange>(this as SalaryRange, _$identity);

  /// Serializes this SalaryRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalaryRange&&(identical(other.beginner, beginner) || other.beginner == beginner)&&(identical(other.intermediate, intermediate) || other.intermediate == intermediate)&&(identical(other.expert, expert) || other.expert == expert));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,beginner,intermediate,expert);

@override
String toString() {
  return 'SalaryRange(beginner: $beginner, intermediate: $intermediate, expert: $expert)';
}


}

/// @nodoc
abstract mixin class $SalaryRangeCopyWith<$Res>  {
  factory $SalaryRangeCopyWith(SalaryRange value, $Res Function(SalaryRange) _then) = _$SalaryRangeCopyWithImpl;
@useResult
$Res call({
 String beginner, String intermediate, String expert
});




}
/// @nodoc
class _$SalaryRangeCopyWithImpl<$Res>
    implements $SalaryRangeCopyWith<$Res> {
  _$SalaryRangeCopyWithImpl(this._self, this._then);

  final SalaryRange _self;
  final $Res Function(SalaryRange) _then;

/// Create a copy of SalaryRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? beginner = null,Object? intermediate = null,Object? expert = null,}) {
  return _then(_self.copyWith(
beginner: null == beginner ? _self.beginner : beginner // ignore: cast_nullable_to_non_nullable
as String,intermediate: null == intermediate ? _self.intermediate : intermediate // ignore: cast_nullable_to_non_nullable
as String,expert: null == expert ? _self.expert : expert // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SalaryRange].
extension SalaryRangePatterns on SalaryRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalaryRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalaryRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalaryRange value)  $default,){
final _that = this;
switch (_that) {
case _SalaryRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalaryRange value)?  $default,){
final _that = this;
switch (_that) {
case _SalaryRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String beginner,  String intermediate,  String expert)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalaryRange() when $default != null:
return $default(_that.beginner,_that.intermediate,_that.expert);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String beginner,  String intermediate,  String expert)  $default,) {final _that = this;
switch (_that) {
case _SalaryRange():
return $default(_that.beginner,_that.intermediate,_that.expert);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String beginner,  String intermediate,  String expert)?  $default,) {final _that = this;
switch (_that) {
case _SalaryRange() when $default != null:
return $default(_that.beginner,_that.intermediate,_that.expert);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SalaryRange implements SalaryRange {
  const _SalaryRange({required this.beginner, required this.intermediate, required this.expert});
  factory _SalaryRange.fromJson(Map<String, dynamic> json) => _$SalaryRangeFromJson(json);

@override final  String beginner;
@override final  String intermediate;
@override final  String expert;

/// Create a copy of SalaryRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalaryRangeCopyWith<_SalaryRange> get copyWith => __$SalaryRangeCopyWithImpl<_SalaryRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalaryRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalaryRange&&(identical(other.beginner, beginner) || other.beginner == beginner)&&(identical(other.intermediate, intermediate) || other.intermediate == intermediate)&&(identical(other.expert, expert) || other.expert == expert));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,beginner,intermediate,expert);

@override
String toString() {
  return 'SalaryRange(beginner: $beginner, intermediate: $intermediate, expert: $expert)';
}


}

/// @nodoc
abstract mixin class _$SalaryRangeCopyWith<$Res> implements $SalaryRangeCopyWith<$Res> {
  factory _$SalaryRangeCopyWith(_SalaryRange value, $Res Function(_SalaryRange) _then) = __$SalaryRangeCopyWithImpl;
@override @useResult
$Res call({
 String beginner, String intermediate, String expert
});




}
/// @nodoc
class __$SalaryRangeCopyWithImpl<$Res>
    implements _$SalaryRangeCopyWith<$Res> {
  __$SalaryRangeCopyWithImpl(this._self, this._then);

  final _SalaryRange _self;
  final $Res Function(_SalaryRange) _then;

/// Create a copy of SalaryRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? beginner = null,Object? intermediate = null,Object? expert = null,}) {
  return _then(_SalaryRange(
beginner: null == beginner ? _self.beginner : beginner // ignore: cast_nullable_to_non_nullable
as String,intermediate: null == intermediate ? _self.intermediate : intermediate // ignore: cast_nullable_to_non_nullable
as String,expert: null == expert ? _self.expert : expert // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RoadmapData {

 List<RoadmapNode> get nodes; List<RoadmapEdge> get edges;
/// Create a copy of RoadmapData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoadmapDataCopyWith<RoadmapData> get copyWith => _$RoadmapDataCopyWithImpl<RoadmapData>(this as RoadmapData, _$identity);

  /// Serializes this RoadmapData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoadmapData&&const DeepCollectionEquality().equals(other.nodes, nodes)&&const DeepCollectionEquality().equals(other.edges, edges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(nodes),const DeepCollectionEquality().hash(edges));

@override
String toString() {
  return 'RoadmapData(nodes: $nodes, edges: $edges)';
}


}

/// @nodoc
abstract mixin class $RoadmapDataCopyWith<$Res>  {
  factory $RoadmapDataCopyWith(RoadmapData value, $Res Function(RoadmapData) _then) = _$RoadmapDataCopyWithImpl;
@useResult
$Res call({
 List<RoadmapNode> nodes, List<RoadmapEdge> edges
});




}
/// @nodoc
class _$RoadmapDataCopyWithImpl<$Res>
    implements $RoadmapDataCopyWith<$Res> {
  _$RoadmapDataCopyWithImpl(this._self, this._then);

  final RoadmapData _self;
  final $Res Function(RoadmapData) _then;

/// Create a copy of RoadmapData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,Object? edges = null,}) {
  return _then(_self.copyWith(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<RoadmapNode>,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as List<RoadmapEdge>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoadmapData].
extension RoadmapDataPatterns on RoadmapData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoadmapData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoadmapData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoadmapData value)  $default,){
final _that = this;
switch (_that) {
case _RoadmapData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoadmapData value)?  $default,){
final _that = this;
switch (_that) {
case _RoadmapData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RoadmapNode> nodes,  List<RoadmapEdge> edges)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoadmapData() when $default != null:
return $default(_that.nodes,_that.edges);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RoadmapNode> nodes,  List<RoadmapEdge> edges)  $default,) {final _that = this;
switch (_that) {
case _RoadmapData():
return $default(_that.nodes,_that.edges);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RoadmapNode> nodes,  List<RoadmapEdge> edges)?  $default,) {final _that = this;
switch (_that) {
case _RoadmapData() when $default != null:
return $default(_that.nodes,_that.edges);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoadmapData implements RoadmapData {
  const _RoadmapData({required final  List<RoadmapNode> nodes, required final  List<RoadmapEdge> edges}): _nodes = nodes,_edges = edges;
  factory _RoadmapData.fromJson(Map<String, dynamic> json) => _$RoadmapDataFromJson(json);

 final  List<RoadmapNode> _nodes;
@override List<RoadmapNode> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
}

 final  List<RoadmapEdge> _edges;
@override List<RoadmapEdge> get edges {
  if (_edges is EqualUnmodifiableListView) return _edges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edges);
}


/// Create a copy of RoadmapData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoadmapDataCopyWith<_RoadmapData> get copyWith => __$RoadmapDataCopyWithImpl<_RoadmapData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoadmapDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoadmapData&&const DeepCollectionEquality().equals(other._nodes, _nodes)&&const DeepCollectionEquality().equals(other._edges, _edges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_edges));

@override
String toString() {
  return 'RoadmapData(nodes: $nodes, edges: $edges)';
}


}

/// @nodoc
abstract mixin class _$RoadmapDataCopyWith<$Res> implements $RoadmapDataCopyWith<$Res> {
  factory _$RoadmapDataCopyWith(_RoadmapData value, $Res Function(_RoadmapData) _then) = __$RoadmapDataCopyWithImpl;
@override @useResult
$Res call({
 List<RoadmapNode> nodes, List<RoadmapEdge> edges
});




}
/// @nodoc
class __$RoadmapDataCopyWithImpl<$Res>
    implements _$RoadmapDataCopyWith<$Res> {
  __$RoadmapDataCopyWithImpl(this._self, this._then);

  final _RoadmapData _self;
  final $Res Function(_RoadmapData) _then;

/// Create a copy of RoadmapData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,Object? edges = null,}) {
  return _then(_RoadmapData(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<RoadmapNode>,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as List<RoadmapEdge>,
  ));
}


}


/// @nodoc
mixin _$RoadmapNode {

 String get skillId; String get skillName; String get level; NodePosition get position; int get order;
/// Create a copy of RoadmapNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoadmapNodeCopyWith<RoadmapNode> get copyWith => _$RoadmapNodeCopyWithImpl<RoadmapNode>(this as RoadmapNode, _$identity);

  /// Serializes this RoadmapNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoadmapNode&&(identical(other.skillId, skillId) || other.skillId == skillId)&&(identical(other.skillName, skillName) || other.skillName == skillName)&&(identical(other.level, level) || other.level == level)&&(identical(other.position, position) || other.position == position)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skillId,skillName,level,position,order);

@override
String toString() {
  return 'RoadmapNode(skillId: $skillId, skillName: $skillName, level: $level, position: $position, order: $order)';
}


}

/// @nodoc
abstract mixin class $RoadmapNodeCopyWith<$Res>  {
  factory $RoadmapNodeCopyWith(RoadmapNode value, $Res Function(RoadmapNode) _then) = _$RoadmapNodeCopyWithImpl;
@useResult
$Res call({
 String skillId, String skillName, String level, NodePosition position, int order
});


$NodePositionCopyWith<$Res> get position;

}
/// @nodoc
class _$RoadmapNodeCopyWithImpl<$Res>
    implements $RoadmapNodeCopyWith<$Res> {
  _$RoadmapNodeCopyWithImpl(this._self, this._then);

  final RoadmapNode _self;
  final $Res Function(RoadmapNode) _then;

/// Create a copy of RoadmapNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skillId = null,Object? skillName = null,Object? level = null,Object? position = null,Object? order = null,}) {
  return _then(_self.copyWith(
skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,skillName: null == skillName ? _self.skillName : skillName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as NodePosition,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of RoadmapNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodePositionCopyWith<$Res> get position {
  
  return $NodePositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}


/// Adds pattern-matching-related methods to [RoadmapNode].
extension RoadmapNodePatterns on RoadmapNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoadmapNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoadmapNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoadmapNode value)  $default,){
final _that = this;
switch (_that) {
case _RoadmapNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoadmapNode value)?  $default,){
final _that = this;
switch (_that) {
case _RoadmapNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String skillId,  String skillName,  String level,  NodePosition position,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoadmapNode() when $default != null:
return $default(_that.skillId,_that.skillName,_that.level,_that.position,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String skillId,  String skillName,  String level,  NodePosition position,  int order)  $default,) {final _that = this;
switch (_that) {
case _RoadmapNode():
return $default(_that.skillId,_that.skillName,_that.level,_that.position,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String skillId,  String skillName,  String level,  NodePosition position,  int order)?  $default,) {final _that = this;
switch (_that) {
case _RoadmapNode() when $default != null:
return $default(_that.skillId,_that.skillName,_that.level,_that.position,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoadmapNode implements RoadmapNode {
  const _RoadmapNode({required this.skillId, required this.skillName, required this.level, required this.position, required this.order});
  factory _RoadmapNode.fromJson(Map<String, dynamic> json) => _$RoadmapNodeFromJson(json);

@override final  String skillId;
@override final  String skillName;
@override final  String level;
@override final  NodePosition position;
@override final  int order;

/// Create a copy of RoadmapNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoadmapNodeCopyWith<_RoadmapNode> get copyWith => __$RoadmapNodeCopyWithImpl<_RoadmapNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoadmapNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoadmapNode&&(identical(other.skillId, skillId) || other.skillId == skillId)&&(identical(other.skillName, skillName) || other.skillName == skillName)&&(identical(other.level, level) || other.level == level)&&(identical(other.position, position) || other.position == position)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skillId,skillName,level,position,order);

@override
String toString() {
  return 'RoadmapNode(skillId: $skillId, skillName: $skillName, level: $level, position: $position, order: $order)';
}


}

/// @nodoc
abstract mixin class _$RoadmapNodeCopyWith<$Res> implements $RoadmapNodeCopyWith<$Res> {
  factory _$RoadmapNodeCopyWith(_RoadmapNode value, $Res Function(_RoadmapNode) _then) = __$RoadmapNodeCopyWithImpl;
@override @useResult
$Res call({
 String skillId, String skillName, String level, NodePosition position, int order
});


@override $NodePositionCopyWith<$Res> get position;

}
/// @nodoc
class __$RoadmapNodeCopyWithImpl<$Res>
    implements _$RoadmapNodeCopyWith<$Res> {
  __$RoadmapNodeCopyWithImpl(this._self, this._then);

  final _RoadmapNode _self;
  final $Res Function(_RoadmapNode) _then;

/// Create a copy of RoadmapNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skillId = null,Object? skillName = null,Object? level = null,Object? position = null,Object? order = null,}) {
  return _then(_RoadmapNode(
skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,skillName: null == skillName ? _self.skillName : skillName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as NodePosition,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of RoadmapNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodePositionCopyWith<$Res> get position {
  
  return $NodePositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}


/// @nodoc
mixin _$NodePosition {

 double get x; double get y;
/// Create a copy of NodePosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodePositionCopyWith<NodePosition> get copyWith => _$NodePositionCopyWithImpl<NodePosition>(this as NodePosition, _$identity);

  /// Serializes this NodePosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodePosition&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'NodePosition(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $NodePositionCopyWith<$Res>  {
  factory $NodePositionCopyWith(NodePosition value, $Res Function(NodePosition) _then) = _$NodePositionCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$NodePositionCopyWithImpl<$Res>
    implements $NodePositionCopyWith<$Res> {
  _$NodePositionCopyWithImpl(this._self, this._then);

  final NodePosition _self;
  final $Res Function(NodePosition) _then;

/// Create a copy of NodePosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NodePosition].
extension NodePositionPatterns on NodePosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NodePosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NodePosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NodePosition value)  $default,){
final _that = this;
switch (_that) {
case _NodePosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NodePosition value)?  $default,){
final _that = this;
switch (_that) {
case _NodePosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodePosition() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _NodePosition():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _NodePosition() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NodePosition implements NodePosition {
  const _NodePosition({required this.x, required this.y});
  factory _NodePosition.fromJson(Map<String, dynamic> json) => _$NodePositionFromJson(json);

@override final  double x;
@override final  double y;

/// Create a copy of NodePosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodePositionCopyWith<_NodePosition> get copyWith => __$NodePositionCopyWithImpl<_NodePosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NodePositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodePosition&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'NodePosition(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$NodePositionCopyWith<$Res> implements $NodePositionCopyWith<$Res> {
  factory _$NodePositionCopyWith(_NodePosition value, $Res Function(_NodePosition) _then) = __$NodePositionCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$NodePositionCopyWithImpl<$Res>
    implements _$NodePositionCopyWith<$Res> {
  __$NodePositionCopyWithImpl(this._self, this._then);

  final _NodePosition _self;
  final $Res Function(_NodePosition) _then;

/// Create a copy of NodePosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_NodePosition(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$RoadmapEdge {

 String get from; String get to; String get type;
/// Create a copy of RoadmapEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoadmapEdgeCopyWith<RoadmapEdge> get copyWith => _$RoadmapEdgeCopyWithImpl<RoadmapEdge>(this as RoadmapEdge, _$identity);

  /// Serializes this RoadmapEdge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoadmapEdge&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,type);

@override
String toString() {
  return 'RoadmapEdge(from: $from, to: $to, type: $type)';
}


}

/// @nodoc
abstract mixin class $RoadmapEdgeCopyWith<$Res>  {
  factory $RoadmapEdgeCopyWith(RoadmapEdge value, $Res Function(RoadmapEdge) _then) = _$RoadmapEdgeCopyWithImpl;
@useResult
$Res call({
 String from, String to, String type
});




}
/// @nodoc
class _$RoadmapEdgeCopyWithImpl<$Res>
    implements $RoadmapEdgeCopyWith<$Res> {
  _$RoadmapEdgeCopyWithImpl(this._self, this._then);

  final RoadmapEdge _self;
  final $Res Function(RoadmapEdge) _then;

/// Create a copy of RoadmapEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? type = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RoadmapEdge].
extension RoadmapEdgePatterns on RoadmapEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoadmapEdge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoadmapEdge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoadmapEdge value)  $default,){
final _that = this;
switch (_that) {
case _RoadmapEdge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoadmapEdge value)?  $default,){
final _that = this;
switch (_that) {
case _RoadmapEdge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String to,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoadmapEdge() when $default != null:
return $default(_that.from,_that.to,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String to,  String type)  $default,) {final _that = this;
switch (_that) {
case _RoadmapEdge():
return $default(_that.from,_that.to,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String to,  String type)?  $default,) {final _that = this;
switch (_that) {
case _RoadmapEdge() when $default != null:
return $default(_that.from,_that.to,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoadmapEdge implements RoadmapEdge {
  const _RoadmapEdge({required this.from, required this.to, required this.type});
  factory _RoadmapEdge.fromJson(Map<String, dynamic> json) => _$RoadmapEdgeFromJson(json);

@override final  String from;
@override final  String to;
@override final  String type;

/// Create a copy of RoadmapEdge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoadmapEdgeCopyWith<_RoadmapEdge> get copyWith => __$RoadmapEdgeCopyWithImpl<_RoadmapEdge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoadmapEdgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoadmapEdge&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,type);

@override
String toString() {
  return 'RoadmapEdge(from: $from, to: $to, type: $type)';
}


}

/// @nodoc
abstract mixin class _$RoadmapEdgeCopyWith<$Res> implements $RoadmapEdgeCopyWith<$Res> {
  factory _$RoadmapEdgeCopyWith(_RoadmapEdge value, $Res Function(_RoadmapEdge) _then) = __$RoadmapEdgeCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, String type
});




}
/// @nodoc
class __$RoadmapEdgeCopyWithImpl<$Res>
    implements _$RoadmapEdgeCopyWith<$Res> {
  __$RoadmapEdgeCopyWithImpl(this._self, this._then);

  final _RoadmapEdge _self;
  final $Res Function(_RoadmapEdge) _then;

/// Create a copy of RoadmapEdge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? type = null,}) {
  return _then(_RoadmapEdge(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

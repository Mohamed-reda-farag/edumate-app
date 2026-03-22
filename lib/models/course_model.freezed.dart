// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseModel {

 String get id; String get title; String get description; String get platform; String get language; String get level; String get price;// free, paid, freemium
 double get priceAmount; String get duration; double get rating; int get enrollments; String get link; String get instructor; String get lastUpdated; bool get hasSubtitles; List<String> get subtitleLanguages; bool get hasCertificate; String? get thumbnailUrl; String get skillId; List<LessonModel> get lessons;
/// Create a copy of CourseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseModelCopyWith<CourseModel> get copyWith => _$CourseModelCopyWithImpl<CourseModel>(this as CourseModel, _$identity);

  /// Serializes this CourseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.price, price) || other.price == price)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.link, link) || other.link == link)&&(identical(other.instructor, instructor) || other.instructor == instructor)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.hasSubtitles, hasSubtitles) || other.hasSubtitles == hasSubtitles)&&const DeepCollectionEquality().equals(other.subtitleLanguages, subtitleLanguages)&&(identical(other.hasCertificate, hasCertificate) || other.hasCertificate == hasCertificate)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&const DeepCollectionEquality().equals(other.lessons, lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,platform,language,level,price,priceAmount,duration,rating,enrollments,link,instructor,lastUpdated,hasSubtitles,const DeepCollectionEquality().hash(subtitleLanguages),hasCertificate,thumbnailUrl,skillId,const DeepCollectionEquality().hash(lessons)]);

@override
String toString() {
  return 'CourseModel(id: $id, title: $title, description: $description, platform: $platform, language: $language, level: $level, price: $price, priceAmount: $priceAmount, duration: $duration, rating: $rating, enrollments: $enrollments, link: $link, instructor: $instructor, lastUpdated: $lastUpdated, hasSubtitles: $hasSubtitles, subtitleLanguages: $subtitleLanguages, hasCertificate: $hasCertificate, thumbnailUrl: $thumbnailUrl, skillId: $skillId, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class $CourseModelCopyWith<$Res>  {
  factory $CourseModelCopyWith(CourseModel value, $Res Function(CourseModel) _then) = _$CourseModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String platform, String language, String level, String price, double priceAmount, String duration, double rating, int enrollments, String link, String instructor, String lastUpdated, bool hasSubtitles, List<String> subtitleLanguages, bool hasCertificate, String? thumbnailUrl, String skillId, List<LessonModel> lessons
});




}
/// @nodoc
class _$CourseModelCopyWithImpl<$Res>
    implements $CourseModelCopyWith<$Res> {
  _$CourseModelCopyWithImpl(this._self, this._then);

  final CourseModel _self;
  final $Res Function(CourseModel) _then;

/// Create a copy of CourseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? platform = null,Object? language = null,Object? level = null,Object? price = null,Object? priceAmount = null,Object? duration = null,Object? rating = null,Object? enrollments = null,Object? link = null,Object? instructor = null,Object? lastUpdated = null,Object? hasSubtitles = null,Object? subtitleLanguages = null,Object? hasCertificate = null,Object? thumbnailUrl = freezed,Object? skillId = null,Object? lessons = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as double,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,instructor: null == instructor ? _self.instructor : instructor // ignore: cast_nullable_to_non_nullable
as String,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as String,hasSubtitles: null == hasSubtitles ? _self.hasSubtitles : hasSubtitles // ignore: cast_nullable_to_non_nullable
as bool,subtitleLanguages: null == subtitleLanguages ? _self.subtitleLanguages : subtitleLanguages // ignore: cast_nullable_to_non_nullable
as List<String>,hasCertificate: null == hasCertificate ? _self.hasCertificate : hasCertificate // ignore: cast_nullable_to_non_nullable
as bool,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<LessonModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseModel].
extension CourseModelPatterns on CourseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseModel value)  $default,){
final _that = this;
switch (_that) {
case _CourseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseModel value)?  $default,){
final _that = this;
switch (_that) {
case _CourseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String platform,  String language,  String level,  String price,  double priceAmount,  String duration,  double rating,  int enrollments,  String link,  String instructor,  String lastUpdated,  bool hasSubtitles,  List<String> subtitleLanguages,  bool hasCertificate,  String? thumbnailUrl,  String skillId,  List<LessonModel> lessons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.platform,_that.language,_that.level,_that.price,_that.priceAmount,_that.duration,_that.rating,_that.enrollments,_that.link,_that.instructor,_that.lastUpdated,_that.hasSubtitles,_that.subtitleLanguages,_that.hasCertificate,_that.thumbnailUrl,_that.skillId,_that.lessons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String platform,  String language,  String level,  String price,  double priceAmount,  String duration,  double rating,  int enrollments,  String link,  String instructor,  String lastUpdated,  bool hasSubtitles,  List<String> subtitleLanguages,  bool hasCertificate,  String? thumbnailUrl,  String skillId,  List<LessonModel> lessons)  $default,) {final _that = this;
switch (_that) {
case _CourseModel():
return $default(_that.id,_that.title,_that.description,_that.platform,_that.language,_that.level,_that.price,_that.priceAmount,_that.duration,_that.rating,_that.enrollments,_that.link,_that.instructor,_that.lastUpdated,_that.hasSubtitles,_that.subtitleLanguages,_that.hasCertificate,_that.thumbnailUrl,_that.skillId,_that.lessons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String platform,  String language,  String level,  String price,  double priceAmount,  String duration,  double rating,  int enrollments,  String link,  String instructor,  String lastUpdated,  bool hasSubtitles,  List<String> subtitleLanguages,  bool hasCertificate,  String? thumbnailUrl,  String skillId,  List<LessonModel> lessons)?  $default,) {final _that = this;
switch (_that) {
case _CourseModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.platform,_that.language,_that.level,_that.price,_that.priceAmount,_that.duration,_that.rating,_that.enrollments,_that.link,_that.instructor,_that.lastUpdated,_that.hasSubtitles,_that.subtitleLanguages,_that.hasCertificate,_that.thumbnailUrl,_that.skillId,_that.lessons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseModel implements CourseModel {
  const _CourseModel({required this.id, required this.title, required this.description, required this.platform, required this.language, required this.level, required this.price, this.priceAmount = 0, required this.duration, required this.rating, required this.enrollments, required this.link, required this.instructor, required this.lastUpdated, required this.hasSubtitles, required final  List<String> subtitleLanguages, required this.hasCertificate, this.thumbnailUrl, required this.skillId, final  List<LessonModel> lessons = const []}): _subtitleLanguages = subtitleLanguages,_lessons = lessons;
  factory _CourseModel.fromJson(Map<String, dynamic> json) => _$CourseModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String platform;
@override final  String language;
@override final  String level;
@override final  String price;
// free, paid, freemium
@override@JsonKey() final  double priceAmount;
@override final  String duration;
@override final  double rating;
@override final  int enrollments;
@override final  String link;
@override final  String instructor;
@override final  String lastUpdated;
@override final  bool hasSubtitles;
 final  List<String> _subtitleLanguages;
@override List<String> get subtitleLanguages {
  if (_subtitleLanguages is EqualUnmodifiableListView) return _subtitleLanguages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtitleLanguages);
}

@override final  bool hasCertificate;
@override final  String? thumbnailUrl;
@override final  String skillId;
 final  List<LessonModel> _lessons;
@override@JsonKey() List<LessonModel> get lessons {
  if (_lessons is EqualUnmodifiableListView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lessons);
}


/// Create a copy of CourseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseModelCopyWith<_CourseModel> get copyWith => __$CourseModelCopyWithImpl<_CourseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.price, price) || other.price == price)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.link, link) || other.link == link)&&(identical(other.instructor, instructor) || other.instructor == instructor)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.hasSubtitles, hasSubtitles) || other.hasSubtitles == hasSubtitles)&&const DeepCollectionEquality().equals(other._subtitleLanguages, _subtitleLanguages)&&(identical(other.hasCertificate, hasCertificate) || other.hasCertificate == hasCertificate)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&const DeepCollectionEquality().equals(other._lessons, _lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,platform,language,level,price,priceAmount,duration,rating,enrollments,link,instructor,lastUpdated,hasSubtitles,const DeepCollectionEquality().hash(_subtitleLanguages),hasCertificate,thumbnailUrl,skillId,const DeepCollectionEquality().hash(_lessons)]);

@override
String toString() {
  return 'CourseModel(id: $id, title: $title, description: $description, platform: $platform, language: $language, level: $level, price: $price, priceAmount: $priceAmount, duration: $duration, rating: $rating, enrollments: $enrollments, link: $link, instructor: $instructor, lastUpdated: $lastUpdated, hasSubtitles: $hasSubtitles, subtitleLanguages: $subtitleLanguages, hasCertificate: $hasCertificate, thumbnailUrl: $thumbnailUrl, skillId: $skillId, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class _$CourseModelCopyWith<$Res> implements $CourseModelCopyWith<$Res> {
  factory _$CourseModelCopyWith(_CourseModel value, $Res Function(_CourseModel) _then) = __$CourseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String platform, String language, String level, String price, double priceAmount, String duration, double rating, int enrollments, String link, String instructor, String lastUpdated, bool hasSubtitles, List<String> subtitleLanguages, bool hasCertificate, String? thumbnailUrl, String skillId, List<LessonModel> lessons
});




}
/// @nodoc
class __$CourseModelCopyWithImpl<$Res>
    implements _$CourseModelCopyWith<$Res> {
  __$CourseModelCopyWithImpl(this._self, this._then);

  final _CourseModel _self;
  final $Res Function(_CourseModel) _then;

/// Create a copy of CourseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? platform = null,Object? language = null,Object? level = null,Object? price = null,Object? priceAmount = null,Object? duration = null,Object? rating = null,Object? enrollments = null,Object? link = null,Object? instructor = null,Object? lastUpdated = null,Object? hasSubtitles = null,Object? subtitleLanguages = null,Object? hasCertificate = null,Object? thumbnailUrl = freezed,Object? skillId = null,Object? lessons = null,}) {
  return _then(_CourseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as double,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,instructor: null == instructor ? _self.instructor : instructor // ignore: cast_nullable_to_non_nullable
as String,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as String,hasSubtitles: null == hasSubtitles ? _self.hasSubtitles : hasSubtitles // ignore: cast_nullable_to_non_nullable
as bool,subtitleLanguages: null == subtitleLanguages ? _self._subtitleLanguages : subtitleLanguages // ignore: cast_nullable_to_non_nullable
as List<String>,hasCertificate: null == hasCertificate ? _self.hasCertificate : hasCertificate // ignore: cast_nullable_to_non_nullable
as bool,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<LessonModel>,
  ));
}


}


/// @nodoc
mixin _$LessonModel {

 String get id; String get title; int get order; String get duration;// مثال: '20 minutes'
 String get description;
/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonModelCopyWith<LessonModel> get copyWith => _$LessonModelCopyWithImpl<LessonModel>(this as LessonModel, _$identity);

  /// Serializes this LessonModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,duration,description);

@override
String toString() {
  return 'LessonModel(id: $id, title: $title, order: $order, duration: $duration, description: $description)';
}


}

/// @nodoc
abstract mixin class $LessonModelCopyWith<$Res>  {
  factory $LessonModelCopyWith(LessonModel value, $Res Function(LessonModel) _then) = _$LessonModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, int order, String duration, String description
});




}
/// @nodoc
class _$LessonModelCopyWithImpl<$Res>
    implements $LessonModelCopyWith<$Res> {
  _$LessonModelCopyWithImpl(this._self, this._then);

  final LessonModel _self;
  final $Res Function(LessonModel) _then;

/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? order = null,Object? duration = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonModel].
extension LessonModelPatterns on LessonModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonModel value)  $default,){
final _that = this;
switch (_that) {
case _LessonModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonModel value)?  $default,){
final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  int order,  String duration,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.duration,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  int order,  String duration,  String description)  $default,) {final _that = this;
switch (_that) {
case _LessonModel():
return $default(_that.id,_that.title,_that.order,_that.duration,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  int order,  String duration,  String description)?  $default,) {final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.duration,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonModel implements LessonModel {
  const _LessonModel({required this.id, required this.title, required this.order, required this.duration, this.description = ''});
  factory _LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  int order;
@override final  String duration;
// مثال: '20 minutes'
@override@JsonKey() final  String description;

/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonModelCopyWith<_LessonModel> get copyWith => __$LessonModelCopyWithImpl<_LessonModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,duration,description);

@override
String toString() {
  return 'LessonModel(id: $id, title: $title, order: $order, duration: $duration, description: $description)';
}


}

/// @nodoc
abstract mixin class _$LessonModelCopyWith<$Res> implements $LessonModelCopyWith<$Res> {
  factory _$LessonModelCopyWith(_LessonModel value, $Res Function(_LessonModel) _then) = __$LessonModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, int order, String duration, String description
});




}
/// @nodoc
class __$LessonModelCopyWithImpl<$Res>
    implements _$LessonModelCopyWith<$Res> {
  __$LessonModelCopyWithImpl(this._self, this._then);

  final _LessonModel _self;
  final $Res Function(_LessonModel) _then;

/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? order = null,Object? duration = null,Object? description = null,}) {
  return _then(_LessonModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

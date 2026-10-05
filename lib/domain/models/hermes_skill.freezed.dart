// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hermes_skill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HermesSkill {

 String get name; String get description; String? get category;
/// Create a copy of HermesSkill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HermesSkillCopyWith<HermesSkill> get copyWith => _$HermesSkillCopyWithImpl<HermesSkill>(this as HermesSkill, _$identity);

  /// Serializes this HermesSkill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HermesSkill&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,category);

@override
String toString() {
  return 'HermesSkill(name: $name, description: $description, category: $category)';
}


}

/// @nodoc
abstract mixin class $HermesSkillCopyWith<$Res>  {
  factory $HermesSkillCopyWith(HermesSkill value, $Res Function(HermesSkill) _then) = _$HermesSkillCopyWithImpl;
@useResult
$Res call({
 String name, String description, String? category
});




}
/// @nodoc
class _$HermesSkillCopyWithImpl<$Res>
    implements $HermesSkillCopyWith<$Res> {
  _$HermesSkillCopyWithImpl(this._self, this._then);

  final HermesSkill _self;
  final $Res Function(HermesSkill) _then;

/// Create a copy of HermesSkill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? category = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HermesSkill].
extension HermesSkillPatterns on HermesSkill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HermesSkill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HermesSkill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HermesSkill value)  $default,){
final _that = this;
switch (_that) {
case _HermesSkill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HermesSkill value)?  $default,){
final _that = this;
switch (_that) {
case _HermesSkill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HermesSkill() when $default != null:
return $default(_that.name,_that.description,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String? category)  $default,) {final _that = this;
switch (_that) {
case _HermesSkill():
return $default(_that.name,_that.description,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _HermesSkill() when $default != null:
return $default(_that.name,_that.description,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HermesSkill implements HermesSkill {
  const _HermesSkill({required this.name, this.description = '', this.category});
  factory _HermesSkill.fromJson(Map<String, dynamic> json) => _$HermesSkillFromJson(json);

@override final  String name;
@override@JsonKey() final  String description;
@override final  String? category;

/// Create a copy of HermesSkill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HermesSkillCopyWith<_HermesSkill> get copyWith => __$HermesSkillCopyWithImpl<_HermesSkill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HermesSkillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HermesSkill&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,category);

@override
String toString() {
  return 'HermesSkill(name: $name, description: $description, category: $category)';
}


}

/// @nodoc
abstract mixin class _$HermesSkillCopyWith<$Res> implements $HermesSkillCopyWith<$Res> {
  factory _$HermesSkillCopyWith(_HermesSkill value, $Res Function(_HermesSkill) _then) = __$HermesSkillCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String? category
});




}
/// @nodoc
class __$HermesSkillCopyWithImpl<$Res>
    implements _$HermesSkillCopyWith<$Res> {
  __$HermesSkillCopyWithImpl(this._self, this._then);

  final _HermesSkill _self;
  final $Res Function(_HermesSkill) _then;

/// Create a copy of HermesSkill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? category = freezed,}) {
  return _then(_HermesSkill(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

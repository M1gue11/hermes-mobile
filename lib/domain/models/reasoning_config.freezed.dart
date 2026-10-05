// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reasoning_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReasoningConfig {

 bool get showActivity;
/// Create a copy of ReasoningConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReasoningConfigCopyWith<ReasoningConfig> get copyWith => _$ReasoningConfigCopyWithImpl<ReasoningConfig>(this as ReasoningConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReasoningConfig&&(identical(other.showActivity, showActivity) || other.showActivity == showActivity));
}


@override
int get hashCode => Object.hash(runtimeType,showActivity);

@override
String toString() {
  return 'ReasoningConfig(showActivity: $showActivity)';
}


}

/// @nodoc
abstract mixin class $ReasoningConfigCopyWith<$Res>  {
  factory $ReasoningConfigCopyWith(ReasoningConfig value, $Res Function(ReasoningConfig) _then) = _$ReasoningConfigCopyWithImpl;
@useResult
$Res call({
 bool showActivity
});




}
/// @nodoc
class _$ReasoningConfigCopyWithImpl<$Res>
    implements $ReasoningConfigCopyWith<$Res> {
  _$ReasoningConfigCopyWithImpl(this._self, this._then);

  final ReasoningConfig _self;
  final $Res Function(ReasoningConfig) _then;

/// Create a copy of ReasoningConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showActivity = null,}) {
  return _then(_self.copyWith(
showActivity: null == showActivity ? _self.showActivity : showActivity // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReasoningConfig].
extension ReasoningConfigPatterns on ReasoningConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReasoningConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReasoningConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReasoningConfig value)  $default,){
final _that = this;
switch (_that) {
case _ReasoningConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReasoningConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ReasoningConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool showActivity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReasoningConfig() when $default != null:
return $default(_that.showActivity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool showActivity)  $default,) {final _that = this;
switch (_that) {
case _ReasoningConfig():
return $default(_that.showActivity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool showActivity)?  $default,) {final _that = this;
switch (_that) {
case _ReasoningConfig() when $default != null:
return $default(_that.showActivity);case _:
  return null;

}
}

}

/// @nodoc


class _ReasoningConfig implements ReasoningConfig {
  const _ReasoningConfig({this.showActivity = true});
  

@override@JsonKey() final  bool showActivity;

/// Create a copy of ReasoningConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReasoningConfigCopyWith<_ReasoningConfig> get copyWith => __$ReasoningConfigCopyWithImpl<_ReasoningConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReasoningConfig&&(identical(other.showActivity, showActivity) || other.showActivity == showActivity));
}


@override
int get hashCode => Object.hash(runtimeType,showActivity);

@override
String toString() {
  return 'ReasoningConfig(showActivity: $showActivity)';
}


}

/// @nodoc
abstract mixin class _$ReasoningConfigCopyWith<$Res> implements $ReasoningConfigCopyWith<$Res> {
  factory _$ReasoningConfigCopyWith(_ReasoningConfig value, $Res Function(_ReasoningConfig) _then) = __$ReasoningConfigCopyWithImpl;
@override @useResult
$Res call({
 bool showActivity
});




}
/// @nodoc
class __$ReasoningConfigCopyWithImpl<$Res>
    implements _$ReasoningConfigCopyWith<$Res> {
  __$ReasoningConfigCopyWithImpl(this._self, this._then);

  final _ReasoningConfig _self;
  final $Res Function(_ReasoningConfig) _then;

/// Create a copy of ReasoningConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showActivity = null,}) {
  return _then(_ReasoningConfig(
showActivity: null == showActivity ? _self.showActivity : showActivity // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

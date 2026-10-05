// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hermes_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HermesModel {

 String get id;@JsonKey(name: 'owned_by') String? get ownedBy; int? get created;
/// Create a copy of HermesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HermesModelCopyWith<HermesModel> get copyWith => _$HermesModelCopyWithImpl<HermesModel>(this as HermesModel, _$identity);

  /// Serializes this HermesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HermesModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ownedBy, ownedBy) || other.ownedBy == ownedBy)&&(identical(other.created, created) || other.created == created));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownedBy,created);

@override
String toString() {
  return 'HermesModel(id: $id, ownedBy: $ownedBy, created: $created)';
}


}

/// @nodoc
abstract mixin class $HermesModelCopyWith<$Res>  {
  factory $HermesModelCopyWith(HermesModel value, $Res Function(HermesModel) _then) = _$HermesModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'owned_by') String? ownedBy, int? created
});




}
/// @nodoc
class _$HermesModelCopyWithImpl<$Res>
    implements $HermesModelCopyWith<$Res> {
  _$HermesModelCopyWithImpl(this._self, this._then);

  final HermesModel _self;
  final $Res Function(HermesModel) _then;

/// Create a copy of HermesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownedBy = freezed,Object? created = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownedBy: freezed == ownedBy ? _self.ownedBy : ownedBy // ignore: cast_nullable_to_non_nullable
as String?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HermesModel].
extension HermesModelPatterns on HermesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HermesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HermesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HermesModel value)  $default,){
final _that = this;
switch (_that) {
case _HermesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HermesModel value)?  $default,){
final _that = this;
switch (_that) {
case _HermesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'owned_by')  String? ownedBy,  int? created)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HermesModel() when $default != null:
return $default(_that.id,_that.ownedBy,_that.created);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'owned_by')  String? ownedBy,  int? created)  $default,) {final _that = this;
switch (_that) {
case _HermesModel():
return $default(_that.id,_that.ownedBy,_that.created);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'owned_by')  String? ownedBy,  int? created)?  $default,) {final _that = this;
switch (_that) {
case _HermesModel() when $default != null:
return $default(_that.id,_that.ownedBy,_that.created);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HermesModel implements HermesModel {
  const _HermesModel({required this.id, @JsonKey(name: 'owned_by') this.ownedBy, this.created});
  factory _HermesModel.fromJson(Map<String, dynamic> json) => _$HermesModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'owned_by') final  String? ownedBy;
@override final  int? created;

/// Create a copy of HermesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HermesModelCopyWith<_HermesModel> get copyWith => __$HermesModelCopyWithImpl<_HermesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HermesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HermesModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ownedBy, ownedBy) || other.ownedBy == ownedBy)&&(identical(other.created, created) || other.created == created));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownedBy,created);

@override
String toString() {
  return 'HermesModel(id: $id, ownedBy: $ownedBy, created: $created)';
}


}

/// @nodoc
abstract mixin class _$HermesModelCopyWith<$Res> implements $HermesModelCopyWith<$Res> {
  factory _$HermesModelCopyWith(_HermesModel value, $Res Function(_HermesModel) _then) = __$HermesModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'owned_by') String? ownedBy, int? created
});




}
/// @nodoc
class __$HermesModelCopyWithImpl<$Res>
    implements _$HermesModelCopyWith<$Res> {
  __$HermesModelCopyWithImpl(this._self, this._then);

  final _HermesModel _self;
  final $Res Function(_HermesModel) _then;

/// Create a copy of HermesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownedBy = freezed,Object? created = freezed,}) {
  return _then(_HermesModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownedBy: freezed == ownedBy ? _self.ownedBy : ownedBy // ignore: cast_nullable_to_non_nullable
as String?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

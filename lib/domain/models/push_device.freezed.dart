// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PushDevice {

 String get id; String get label; String get endpointHost; bool get encrypted; DateTime? get updatedAt;
/// Create a copy of PushDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushDeviceCopyWith<PushDevice> get copyWith => _$PushDeviceCopyWithImpl<PushDevice>(this as PushDevice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.endpointHost, endpointHost) || other.endpointHost == endpointHost)&&(identical(other.encrypted, encrypted) || other.encrypted == encrypted)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,endpointHost,encrypted,updatedAt);

@override
String toString() {
  return 'PushDevice(id: $id, label: $label, endpointHost: $endpointHost, encrypted: $encrypted, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PushDeviceCopyWith<$Res>  {
  factory $PushDeviceCopyWith(PushDevice value, $Res Function(PushDevice) _then) = _$PushDeviceCopyWithImpl;
@useResult
$Res call({
 String id, String label, String endpointHost, bool encrypted, DateTime? updatedAt
});




}
/// @nodoc
class _$PushDeviceCopyWithImpl<$Res>
    implements $PushDeviceCopyWith<$Res> {
  _$PushDeviceCopyWithImpl(this._self, this._then);

  final PushDevice _self;
  final $Res Function(PushDevice) _then;

/// Create a copy of PushDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? endpointHost = null,Object? encrypted = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,endpointHost: null == endpointHost ? _self.endpointHost : endpointHost // ignore: cast_nullable_to_non_nullable
as String,encrypted: null == encrypted ? _self.encrypted : encrypted // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushDevice].
extension PushDevicePatterns on PushDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushDevice value)  $default,){
final _that = this;
switch (_that) {
case _PushDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushDevice value)?  $default,){
final _that = this;
switch (_that) {
case _PushDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String endpointHost,  bool encrypted,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushDevice() when $default != null:
return $default(_that.id,_that.label,_that.endpointHost,_that.encrypted,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String endpointHost,  bool encrypted,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PushDevice():
return $default(_that.id,_that.label,_that.endpointHost,_that.encrypted,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String endpointHost,  bool encrypted,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PushDevice() when $default != null:
return $default(_that.id,_that.label,_that.endpointHost,_that.encrypted,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PushDevice implements PushDevice {
  const _PushDevice({required this.id, this.label = '', this.endpointHost = '', this.encrypted = false, this.updatedAt});


@override final  String id;
@override@JsonKey() final  String label;
@override@JsonKey() final  String endpointHost;
@override@JsonKey() final  bool encrypted;
@override final  DateTime? updatedAt;

/// Create a copy of PushDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushDeviceCopyWith<_PushDevice> get copyWith => __$PushDeviceCopyWithImpl<_PushDevice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.endpointHost, endpointHost) || other.endpointHost == endpointHost)&&(identical(other.encrypted, encrypted) || other.encrypted == encrypted)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,endpointHost,encrypted,updatedAt);

@override
String toString() {
  return 'PushDevice(id: $id, label: $label, endpointHost: $endpointHost, encrypted: $encrypted, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PushDeviceCopyWith<$Res> implements $PushDeviceCopyWith<$Res> {
  factory _$PushDeviceCopyWith(_PushDevice value, $Res Function(_PushDevice) _then) = __$PushDeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String endpointHost, bool encrypted, DateTime? updatedAt
});




}
/// @nodoc
class __$PushDeviceCopyWithImpl<$Res>
    implements _$PushDeviceCopyWith<$Res> {
  __$PushDeviceCopyWithImpl(this._self, this._then);

  final _PushDevice _self;
  final $Res Function(_PushDevice) _then;

/// Create a copy of PushDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? endpointHost = null,Object? encrypted = null,Object? updatedAt = freezed,}) {
  return _then(_PushDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,endpointHost: null == endpointHost ? _self.endpointHost : endpointHost // ignore: cast_nullable_to_non_nullable
as String,encrypted: null == encrypted ? _self.encrypted : encrypted // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

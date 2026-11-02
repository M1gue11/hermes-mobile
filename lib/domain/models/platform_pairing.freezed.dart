// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'platform_pairing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PairingRequest {

 String get platform; String get requestId; String get userId; String get userName; int get ageMinutes;
/// Create a copy of PairingRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PairingRequestCopyWith<PairingRequest> get copyWith => _$PairingRequestCopyWithImpl<PairingRequest>(this as PairingRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingRequest&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.ageMinutes, ageMinutes) || other.ageMinutes == ageMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,platform,requestId,userId,userName,ageMinutes);

@override
String toString() {
  return 'PairingRequest(platform: $platform, requestId: $requestId, userId: $userId, userName: $userName, ageMinutes: $ageMinutes)';
}


}

/// @nodoc
abstract mixin class $PairingRequestCopyWith<$Res>  {
  factory $PairingRequestCopyWith(PairingRequest value, $Res Function(PairingRequest) _then) = _$PairingRequestCopyWithImpl;
@useResult
$Res call({
 String platform, String requestId, String userId, String userName, int ageMinutes
});




}
/// @nodoc
class _$PairingRequestCopyWithImpl<$Res>
    implements $PairingRequestCopyWith<$Res> {
  _$PairingRequestCopyWithImpl(this._self, this._then);

  final PairingRequest _self;
  final $Res Function(PairingRequest) _then;

/// Create a copy of PairingRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? requestId = null,Object? userId = null,Object? userName = null,Object? ageMinutes = null,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,ageMinutes: null == ageMinutes ? _self.ageMinutes : ageMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PairingRequest].
extension PairingRequestPatterns on PairingRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PairingRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PairingRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PairingRequest value)  $default,){
final _that = this;
switch (_that) {
case _PairingRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PairingRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PairingRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String platform,  String requestId,  String userId,  String userName,  int ageMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PairingRequest() when $default != null:
return $default(_that.platform,_that.requestId,_that.userId,_that.userName,_that.ageMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String platform,  String requestId,  String userId,  String userName,  int ageMinutes)  $default,) {final _that = this;
switch (_that) {
case _PairingRequest():
return $default(_that.platform,_that.requestId,_that.userId,_that.userName,_that.ageMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String platform,  String requestId,  String userId,  String userName,  int ageMinutes)?  $default,) {final _that = this;
switch (_that) {
case _PairingRequest() when $default != null:
return $default(_that.platform,_that.requestId,_that.userId,_that.userName,_that.ageMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _PairingRequest extends PairingRequest {
  const _PairingRequest({required this.platform, this.requestId = '', this.userId = '', this.userName = '', this.ageMinutes = 0}): super._();
  

@override final  String platform;
@override@JsonKey() final  String requestId;
@override@JsonKey() final  String userId;
@override@JsonKey() final  String userName;
@override@JsonKey() final  int ageMinutes;

/// Create a copy of PairingRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PairingRequestCopyWith<_PairingRequest> get copyWith => __$PairingRequestCopyWithImpl<_PairingRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PairingRequest&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.ageMinutes, ageMinutes) || other.ageMinutes == ageMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,platform,requestId,userId,userName,ageMinutes);

@override
String toString() {
  return 'PairingRequest(platform: $platform, requestId: $requestId, userId: $userId, userName: $userName, ageMinutes: $ageMinutes)';
}


}

/// @nodoc
abstract mixin class _$PairingRequestCopyWith<$Res> implements $PairingRequestCopyWith<$Res> {
  factory _$PairingRequestCopyWith(_PairingRequest value, $Res Function(_PairingRequest) _then) = __$PairingRequestCopyWithImpl;
@override @useResult
$Res call({
 String platform, String requestId, String userId, String userName, int ageMinutes
});




}
/// @nodoc
class __$PairingRequestCopyWithImpl<$Res>
    implements _$PairingRequestCopyWith<$Res> {
  __$PairingRequestCopyWithImpl(this._self, this._then);

  final _PairingRequest _self;
  final $Res Function(_PairingRequest) _then;

/// Create a copy of PairingRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? requestId = null,Object? userId = null,Object? userName = null,Object? ageMinutes = null,}) {
  return _then(_PairingRequest(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,ageMinutes: null == ageMinutes ? _self.ageMinutes : ageMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PairedUser {

 String get platform; String get userId; String get userName; DateTime? get approvedAt;
/// Create a copy of PairedUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PairedUserCopyWith<PairedUser> get copyWith => _$PairedUserCopyWithImpl<PairedUser>(this as PairedUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairedUser&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,platform,userId,userName,approvedAt);

@override
String toString() {
  return 'PairedUser(platform: $platform, userId: $userId, userName: $userName, approvedAt: $approvedAt)';
}


}

/// @nodoc
abstract mixin class $PairedUserCopyWith<$Res>  {
  factory $PairedUserCopyWith(PairedUser value, $Res Function(PairedUser) _then) = _$PairedUserCopyWithImpl;
@useResult
$Res call({
 String platform, String userId, String userName, DateTime? approvedAt
});




}
/// @nodoc
class _$PairedUserCopyWithImpl<$Res>
    implements $PairedUserCopyWith<$Res> {
  _$PairedUserCopyWithImpl(this._self, this._then);

  final PairedUser _self;
  final $Res Function(PairedUser) _then;

/// Create a copy of PairedUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? userId = null,Object? userName = null,Object? approvedAt = freezed,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PairedUser].
extension PairedUserPatterns on PairedUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PairedUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PairedUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PairedUser value)  $default,){
final _that = this;
switch (_that) {
case _PairedUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PairedUser value)?  $default,){
final _that = this;
switch (_that) {
case _PairedUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String platform,  String userId,  String userName,  DateTime? approvedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PairedUser() when $default != null:
return $default(_that.platform,_that.userId,_that.userName,_that.approvedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String platform,  String userId,  String userName,  DateTime? approvedAt)  $default,) {final _that = this;
switch (_that) {
case _PairedUser():
return $default(_that.platform,_that.userId,_that.userName,_that.approvedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String platform,  String userId,  String userName,  DateTime? approvedAt)?  $default,) {final _that = this;
switch (_that) {
case _PairedUser() when $default != null:
return $default(_that.platform,_that.userId,_that.userName,_that.approvedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PairedUser implements PairedUser {
  const _PairedUser({required this.platform, required this.userId, this.userName = '', this.approvedAt});
  

@override final  String platform;
@override final  String userId;
@override@JsonKey() final  String userName;
@override final  DateTime? approvedAt;

/// Create a copy of PairedUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PairedUserCopyWith<_PairedUser> get copyWith => __$PairedUserCopyWithImpl<_PairedUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PairedUser&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,platform,userId,userName,approvedAt);

@override
String toString() {
  return 'PairedUser(platform: $platform, userId: $userId, userName: $userName, approvedAt: $approvedAt)';
}


}

/// @nodoc
abstract mixin class _$PairedUserCopyWith<$Res> implements $PairedUserCopyWith<$Res> {
  factory _$PairedUserCopyWith(_PairedUser value, $Res Function(_PairedUser) _then) = __$PairedUserCopyWithImpl;
@override @useResult
$Res call({
 String platform, String userId, String userName, DateTime? approvedAt
});




}
/// @nodoc
class __$PairedUserCopyWithImpl<$Res>
    implements _$PairedUserCopyWith<$Res> {
  __$PairedUserCopyWithImpl(this._self, this._then);

  final _PairedUser _self;
  final $Res Function(_PairedUser) _then;

/// Create a copy of PairedUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? userId = null,Object? userName = null,Object? approvedAt = freezed,}) {
  return _then(_PairedUser(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

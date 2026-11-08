// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_notice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PushNotice {

 PushNoticeKind get kind; String get sessionId; String? get title; PushInputKind? get input; String? get requestId; DateTime? get sentAt;
/// Create a copy of PushNotice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushNoticeCopyWith<PushNotice> get copyWith => _$PushNoticeCopyWithImpl<PushNotice>(this as PushNotice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushNotice&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.input, input) || other.input == input)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,kind,sessionId,title,input,requestId,sentAt);

@override
String toString() {
  return 'PushNotice(kind: $kind, sessionId: $sessionId, title: $title, input: $input, requestId: $requestId, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $PushNoticeCopyWith<$Res>  {
  factory $PushNoticeCopyWith(PushNotice value, $Res Function(PushNotice) _then) = _$PushNoticeCopyWithImpl;
@useResult
$Res call({
 PushNoticeKind kind, String sessionId, String? title, PushInputKind? input, String? requestId, DateTime? sentAt
});




}
/// @nodoc
class _$PushNoticeCopyWithImpl<$Res>
    implements $PushNoticeCopyWith<$Res> {
  _$PushNoticeCopyWithImpl(this._self, this._then);

  final PushNotice _self;
  final $Res Function(PushNotice) _then;

/// Create a copy of PushNotice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? sessionId = null,Object? title = freezed,Object? input = freezed,Object? requestId = freezed,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PushNoticeKind,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PushInputKind?,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushNotice].
extension PushNoticePatterns on PushNotice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushNotice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushNotice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushNotice value)  $default,){
final _that = this;
switch (_that) {
case _PushNotice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushNotice value)?  $default,){
final _that = this;
switch (_that) {
case _PushNotice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PushNoticeKind kind,  String sessionId,  String? title,  PushInputKind? input,  String? requestId,  DateTime? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushNotice() when $default != null:
return $default(_that.kind,_that.sessionId,_that.title,_that.input,_that.requestId,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PushNoticeKind kind,  String sessionId,  String? title,  PushInputKind? input,  String? requestId,  DateTime? sentAt)  $default,) {final _that = this;
switch (_that) {
case _PushNotice():
return $default(_that.kind,_that.sessionId,_that.title,_that.input,_that.requestId,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PushNoticeKind kind,  String sessionId,  String? title,  PushInputKind? input,  String? requestId,  DateTime? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _PushNotice() when $default != null:
return $default(_that.kind,_that.sessionId,_that.title,_that.input,_that.requestId,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc


class _PushNotice extends PushNotice {
  const _PushNotice({required this.kind, this.sessionId = '', this.title, this.input, this.requestId, this.sentAt}): super._();


@override final  PushNoticeKind kind;
@override@JsonKey() final  String sessionId;
@override final  String? title;
@override final  PushInputKind? input;
@override final  String? requestId;
@override final  DateTime? sentAt;

/// Create a copy of PushNotice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushNoticeCopyWith<_PushNotice> get copyWith => __$PushNoticeCopyWithImpl<_PushNotice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushNotice&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.input, input) || other.input == input)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,kind,sessionId,title,input,requestId,sentAt);

@override
String toString() {
  return 'PushNotice(kind: $kind, sessionId: $sessionId, title: $title, input: $input, requestId: $requestId, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$PushNoticeCopyWith<$Res> implements $PushNoticeCopyWith<$Res> {
  factory _$PushNoticeCopyWith(_PushNotice value, $Res Function(_PushNotice) _then) = __$PushNoticeCopyWithImpl;
@override @useResult
$Res call({
 PushNoticeKind kind, String sessionId, String? title, PushInputKind? input, String? requestId, DateTime? sentAt
});




}
/// @nodoc
class __$PushNoticeCopyWithImpl<$Res>
    implements _$PushNoticeCopyWith<$Res> {
  __$PushNoticeCopyWithImpl(this._self, this._then);

  final _PushNotice _self;
  final $Res Function(_PushNotice) _then;

/// Create a copy of PushNotice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? sessionId = null,Object? title = freezed,Object? input = freezed,Object? requestId = freezed,Object? sentAt = freezed,}) {
  return _then(_PushNotice(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PushNoticeKind,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PushInputKind?,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

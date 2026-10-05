// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'composer_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComposerAttachment {

 String get id; String get name; String get mimeType; Uint8List get bytes; ComposerAttachmentKind get kind; ComposerAttachmentStatus get status; String? get localPath; String? get refText; String? get error;
/// Create a copy of ComposerAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComposerAttachmentCopyWith<ComposerAttachment> get copyWith => _$ComposerAttachmentCopyWithImpl<ComposerAttachment>(this as ComposerAttachment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComposerAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.refText, refText) || other.refText == refText)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,mimeType,const DeepCollectionEquality().hash(bytes),kind,status,localPath,refText,error);

@override
String toString() {
  return 'ComposerAttachment(id: $id, name: $name, mimeType: $mimeType, bytes: $bytes, kind: $kind, status: $status, localPath: $localPath, refText: $refText, error: $error)';
}


}

/// @nodoc
abstract mixin class $ComposerAttachmentCopyWith<$Res>  {
  factory $ComposerAttachmentCopyWith(ComposerAttachment value, $Res Function(ComposerAttachment) _then) = _$ComposerAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String mimeType, Uint8List bytes, ComposerAttachmentKind kind, ComposerAttachmentStatus status, String? localPath, String? refText, String? error
});




}
/// @nodoc
class _$ComposerAttachmentCopyWithImpl<$Res>
    implements $ComposerAttachmentCopyWith<$Res> {
  _$ComposerAttachmentCopyWithImpl(this._self, this._then);

  final ComposerAttachment _self;
  final $Res Function(ComposerAttachment) _then;

/// Create a copy of ComposerAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? mimeType = null,Object? bytes = null,Object? kind = null,Object? status = null,Object? localPath = freezed,Object? refText = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ComposerAttachmentKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ComposerAttachmentStatus,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,refText: freezed == refText ? _self.refText : refText // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ComposerAttachment].
extension ComposerAttachmentPatterns on ComposerAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComposerAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComposerAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComposerAttachment value)  $default,){
final _that = this;
switch (_that) {
case _ComposerAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComposerAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _ComposerAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String mimeType,  Uint8List bytes,  ComposerAttachmentKind kind,  ComposerAttachmentStatus status,  String? localPath,  String? refText,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComposerAttachment() when $default != null:
return $default(_that.id,_that.name,_that.mimeType,_that.bytes,_that.kind,_that.status,_that.localPath,_that.refText,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String mimeType,  Uint8List bytes,  ComposerAttachmentKind kind,  ComposerAttachmentStatus status,  String? localPath,  String? refText,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ComposerAttachment():
return $default(_that.id,_that.name,_that.mimeType,_that.bytes,_that.kind,_that.status,_that.localPath,_that.refText,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String mimeType,  Uint8List bytes,  ComposerAttachmentKind kind,  ComposerAttachmentStatus status,  String? localPath,  String? refText,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ComposerAttachment() when $default != null:
return $default(_that.id,_that.name,_that.mimeType,_that.bytes,_that.kind,_that.status,_that.localPath,_that.refText,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ComposerAttachment implements ComposerAttachment {
  const _ComposerAttachment({required this.id, required this.name, required this.mimeType, required this.bytes, this.kind = ComposerAttachmentKind.file, this.status = ComposerAttachmentStatus.ready, this.localPath, this.refText, this.error});


@override final  String id;
@override final  String name;
@override final  String mimeType;
@override final  Uint8List bytes;
@override@JsonKey() final  ComposerAttachmentKind kind;
@override@JsonKey() final  ComposerAttachmentStatus status;
@override final  String? localPath;
@override final  String? refText;
@override final  String? error;

/// Create a copy of ComposerAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComposerAttachmentCopyWith<_ComposerAttachment> get copyWith => __$ComposerAttachmentCopyWithImpl<_ComposerAttachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComposerAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.refText, refText) || other.refText == refText)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,mimeType,const DeepCollectionEquality().hash(bytes),kind,status,localPath,refText,error);

@override
String toString() {
  return 'ComposerAttachment(id: $id, name: $name, mimeType: $mimeType, bytes: $bytes, kind: $kind, status: $status, localPath: $localPath, refText: $refText, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ComposerAttachmentCopyWith<$Res> implements $ComposerAttachmentCopyWith<$Res> {
  factory _$ComposerAttachmentCopyWith(_ComposerAttachment value, $Res Function(_ComposerAttachment) _then) = __$ComposerAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String mimeType, Uint8List bytes, ComposerAttachmentKind kind, ComposerAttachmentStatus status, String? localPath, String? refText, String? error
});




}
/// @nodoc
class __$ComposerAttachmentCopyWithImpl<$Res>
    implements _$ComposerAttachmentCopyWith<$Res> {
  __$ComposerAttachmentCopyWithImpl(this._self, this._then);

  final _ComposerAttachment _self;
  final $Res Function(_ComposerAttachment) _then;

/// Create a copy of ComposerAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? mimeType = null,Object? bytes = null,Object? kind = null,Object? status = null,Object? localPath = freezed,Object? refText = freezed,Object? error = freezed,}) {
  return _then(_ComposerAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ComposerAttachmentKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ComposerAttachmentStatus,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,refText: freezed == refText ? _self.refText : refText // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

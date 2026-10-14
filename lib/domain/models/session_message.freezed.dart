// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionMessage {

 String get id; String get role; String get content;@JsonKey(name: 'row_id') int? get rowId;@JsonKey(name: 'display_kind') String? get displayKind;@JsonKey(name: 'display_metadata') Map<String, dynamic>? get displayMetadata;@JsonKey(name: 'display_commentary') List<String> get displayCommentary;@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? get timestamp; String? get reasoning;@JsonKey(name: 'reasoning_content') String? get reasoningContent;@JsonKey(name: 'tool_name') String? get toolName;@JsonKey(name: 'context') String? get toolContext;@JsonKey(name: 'args') Map<String, dynamic>? get toolArgs;@JsonKey(name: 'tool_call_id') String? get toolCallId;@JsonKey(name: 'tool_calls') Object? get toolCalls;@JsonKey(name: 'token_count') num? get tokenCount;@JsonKey(name: 'finish_reason') String? get finishReason;
/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionMessageCopyWith<SessionMessage> get copyWith => _$SessionMessageCopyWithImpl<SessionMessage>(this as SessionMessage, _$identity);

  /// Serializes this SessionMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.displayKind, displayKind) || other.displayKind == displayKind)&&const DeepCollectionEquality().equals(other.displayMetadata, displayMetadata)&&const DeepCollectionEquality().equals(other.displayCommentary, displayCommentary)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.reasoningContent, reasoningContent) || other.reasoningContent == reasoningContent)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.toolContext, toolContext) || other.toolContext == toolContext)&&const DeepCollectionEquality().equals(other.toolArgs, toolArgs)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,rowId,displayKind,const DeepCollectionEquality().hash(displayMetadata),const DeepCollectionEquality().hash(displayCommentary),timestamp,reasoning,reasoningContent,toolName,toolContext,const DeepCollectionEquality().hash(toolArgs),toolCallId,const DeepCollectionEquality().hash(toolCalls),tokenCount,finishReason);

@override
String toString() {
  return 'SessionMessage(id: $id, role: $role, content: $content, rowId: $rowId, displayKind: $displayKind, displayMetadata: $displayMetadata, displayCommentary: $displayCommentary, timestamp: $timestamp, reasoning: $reasoning, reasoningContent: $reasoningContent, toolName: $toolName, toolContext: $toolContext, toolArgs: $toolArgs, toolCallId: $toolCallId, toolCalls: $toolCalls, tokenCount: $tokenCount, finishReason: $finishReason)';
}


}

/// @nodoc
abstract mixin class $SessionMessageCopyWith<$Res>  {
  factory $SessionMessageCopyWith(SessionMessage value, $Res Function(SessionMessage) _then) = _$SessionMessageCopyWithImpl;
@useResult
$Res call({
 String id, String role, String content,@JsonKey(name: 'row_id') int? rowId,@JsonKey(name: 'display_kind') String? displayKind,@JsonKey(name: 'display_metadata') Map<String, dynamic>? displayMetadata,@JsonKey(name: 'display_commentary') List<String> displayCommentary,@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? timestamp, String? reasoning,@JsonKey(name: 'reasoning_content') String? reasoningContent,@JsonKey(name: 'tool_name') String? toolName,@JsonKey(name: 'context') String? toolContext,@JsonKey(name: 'args') Map<String, dynamic>? toolArgs,@JsonKey(name: 'tool_call_id') String? toolCallId,@JsonKey(name: 'tool_calls') Object? toolCalls,@JsonKey(name: 'token_count') num? tokenCount,@JsonKey(name: 'finish_reason') String? finishReason
});




}
/// @nodoc
class _$SessionMessageCopyWithImpl<$Res>
    implements $SessionMessageCopyWith<$Res> {
  _$SessionMessageCopyWithImpl(this._self, this._then);

  final SessionMessage _self;
  final $Res Function(SessionMessage) _then;

/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? content = null,Object? rowId = freezed,Object? displayKind = freezed,Object? displayMetadata = freezed,Object? displayCommentary = null,Object? timestamp = freezed,Object? reasoning = freezed,Object? reasoningContent = freezed,Object? toolName = freezed,Object? toolContext = freezed,Object? toolArgs = freezed,Object? toolCallId = freezed,Object? toolCalls = freezed,Object? tokenCount = freezed,Object? finishReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,displayKind: freezed == displayKind ? _self.displayKind : displayKind // ignore: cast_nullable_to_non_nullable
as String?,displayMetadata: freezed == displayMetadata ? _self.displayMetadata : displayMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,displayCommentary: null == displayCommentary ? _self.displayCommentary : displayCommentary // ignore: cast_nullable_to_non_nullable
as List<String>,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent // ignore: cast_nullable_to_non_nullable
as String?,toolName: freezed == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String?,toolContext: freezed == toolContext ? _self.toolContext : toolContext // ignore: cast_nullable_to_non_nullable
as String?,toolArgs: freezed == toolArgs ? _self.toolArgs : toolArgs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,toolCallId: freezed == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String?,toolCalls: freezed == toolCalls ? _self.toolCalls : toolCalls ,tokenCount: freezed == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as num?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionMessage].
extension SessionMessagePatterns on SessionMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionMessage value)  $default,){
final _that = this;
switch (_that) {
case _SessionMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String role,  String content, @JsonKey(name: 'row_id')  int? rowId, @JsonKey(name: 'display_kind')  String? displayKind, @JsonKey(name: 'display_metadata')  Map<String, dynamic>? displayMetadata, @JsonKey(name: 'display_commentary')  List<String> displayCommentary, @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? timestamp,  String? reasoning, @JsonKey(name: 'reasoning_content')  String? reasoningContent, @JsonKey(name: 'tool_name')  String? toolName, @JsonKey(name: 'context')  String? toolContext, @JsonKey(name: 'args')  Map<String, dynamic>? toolArgs, @JsonKey(name: 'tool_call_id')  String? toolCallId, @JsonKey(name: 'tool_calls')  Object? toolCalls, @JsonKey(name: 'token_count')  num? tokenCount, @JsonKey(name: 'finish_reason')  String? finishReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.rowId,_that.displayKind,_that.displayMetadata,_that.displayCommentary,_that.timestamp,_that.reasoning,_that.reasoningContent,_that.toolName,_that.toolContext,_that.toolArgs,_that.toolCallId,_that.toolCalls,_that.tokenCount,_that.finishReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String role,  String content, @JsonKey(name: 'row_id')  int? rowId, @JsonKey(name: 'display_kind')  String? displayKind, @JsonKey(name: 'display_metadata')  Map<String, dynamic>? displayMetadata, @JsonKey(name: 'display_commentary')  List<String> displayCommentary, @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? timestamp,  String? reasoning, @JsonKey(name: 'reasoning_content')  String? reasoningContent, @JsonKey(name: 'tool_name')  String? toolName, @JsonKey(name: 'context')  String? toolContext, @JsonKey(name: 'args')  Map<String, dynamic>? toolArgs, @JsonKey(name: 'tool_call_id')  String? toolCallId, @JsonKey(name: 'tool_calls')  Object? toolCalls, @JsonKey(name: 'token_count')  num? tokenCount, @JsonKey(name: 'finish_reason')  String? finishReason)  $default,) {final _that = this;
switch (_that) {
case _SessionMessage():
return $default(_that.id,_that.role,_that.content,_that.rowId,_that.displayKind,_that.displayMetadata,_that.displayCommentary,_that.timestamp,_that.reasoning,_that.reasoningContent,_that.toolName,_that.toolContext,_that.toolArgs,_that.toolCallId,_that.toolCalls,_that.tokenCount,_that.finishReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String role,  String content, @JsonKey(name: 'row_id')  int? rowId, @JsonKey(name: 'display_kind')  String? displayKind, @JsonKey(name: 'display_metadata')  Map<String, dynamic>? displayMetadata, @JsonKey(name: 'display_commentary')  List<String> displayCommentary, @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? timestamp,  String? reasoning, @JsonKey(name: 'reasoning_content')  String? reasoningContent, @JsonKey(name: 'tool_name')  String? toolName, @JsonKey(name: 'context')  String? toolContext, @JsonKey(name: 'args')  Map<String, dynamic>? toolArgs, @JsonKey(name: 'tool_call_id')  String? toolCallId, @JsonKey(name: 'tool_calls')  Object? toolCalls, @JsonKey(name: 'token_count')  num? tokenCount, @JsonKey(name: 'finish_reason')  String? finishReason)?  $default,) {final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.rowId,_that.displayKind,_that.displayMetadata,_that.displayCommentary,_that.timestamp,_that.reasoning,_that.reasoningContent,_that.toolName,_that.toolContext,_that.toolArgs,_that.toolCallId,_that.toolCalls,_that.tokenCount,_that.finishReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionMessage implements SessionMessage {
  const _SessionMessage({required this.id, required this.role, this.content = '', @JsonKey(name: 'row_id') this.rowId, @JsonKey(name: 'display_kind') this.displayKind, @JsonKey(name: 'display_metadata') final  Map<String, dynamic>? displayMetadata, @JsonKey(name: 'display_commentary') final  List<String> displayCommentary = const <String>[], @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) this.timestamp, this.reasoning, @JsonKey(name: 'reasoning_content') this.reasoningContent, @JsonKey(name: 'tool_name') this.toolName, @JsonKey(name: 'context') this.toolContext, @JsonKey(name: 'args') final  Map<String, dynamic>? toolArgs, @JsonKey(name: 'tool_call_id') this.toolCallId, @JsonKey(name: 'tool_calls') this.toolCalls, @JsonKey(name: 'token_count') this.tokenCount, @JsonKey(name: 'finish_reason') this.finishReason}): _displayMetadata = displayMetadata,_displayCommentary = displayCommentary,_toolArgs = toolArgs;
  factory _SessionMessage.fromJson(Map<String, dynamic> json) => _$SessionMessageFromJson(json);

@override final  String id;
@override final  String role;
@override@JsonKey() final  String content;
@override@JsonKey(name: 'row_id') final  int? rowId;
@override@JsonKey(name: 'display_kind') final  String? displayKind;
 final  Map<String, dynamic>? _displayMetadata;
@override@JsonKey(name: 'display_metadata') Map<String, dynamic>? get displayMetadata {
  final value = _displayMetadata;
  if (value == null) return null;
  if (_displayMetadata is EqualUnmodifiableMapView) return _displayMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String> _displayCommentary;
@override@JsonKey(name: 'display_commentary') List<String> get displayCommentary {
  if (_displayCommentary is EqualUnmodifiableListView) return _displayCommentary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_displayCommentary);
}

@override@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) final  DateTime? timestamp;
@override final  String? reasoning;
@override@JsonKey(name: 'reasoning_content') final  String? reasoningContent;
@override@JsonKey(name: 'tool_name') final  String? toolName;
@override@JsonKey(name: 'context') final  String? toolContext;
 final  Map<String, dynamic>? _toolArgs;
@override@JsonKey(name: 'args') Map<String, dynamic>? get toolArgs {
  final value = _toolArgs;
  if (value == null) return null;
  if (_toolArgs is EqualUnmodifiableMapView) return _toolArgs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'tool_call_id') final  String? toolCallId;
@override@JsonKey(name: 'tool_calls') final  Object? toolCalls;
@override@JsonKey(name: 'token_count') final  num? tokenCount;
@override@JsonKey(name: 'finish_reason') final  String? finishReason;

/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionMessageCopyWith<_SessionMessage> get copyWith => __$SessionMessageCopyWithImpl<_SessionMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.displayKind, displayKind) || other.displayKind == displayKind)&&const DeepCollectionEquality().equals(other._displayMetadata, _displayMetadata)&&const DeepCollectionEquality().equals(other._displayCommentary, _displayCommentary)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.reasoningContent, reasoningContent) || other.reasoningContent == reasoningContent)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.toolContext, toolContext) || other.toolContext == toolContext)&&const DeepCollectionEquality().equals(other._toolArgs, _toolArgs)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,rowId,displayKind,const DeepCollectionEquality().hash(_displayMetadata),const DeepCollectionEquality().hash(_displayCommentary),timestamp,reasoning,reasoningContent,toolName,toolContext,const DeepCollectionEquality().hash(_toolArgs),toolCallId,const DeepCollectionEquality().hash(toolCalls),tokenCount,finishReason);

@override
String toString() {
  return 'SessionMessage(id: $id, role: $role, content: $content, rowId: $rowId, displayKind: $displayKind, displayMetadata: $displayMetadata, displayCommentary: $displayCommentary, timestamp: $timestamp, reasoning: $reasoning, reasoningContent: $reasoningContent, toolName: $toolName, toolContext: $toolContext, toolArgs: $toolArgs, toolCallId: $toolCallId, toolCalls: $toolCalls, tokenCount: $tokenCount, finishReason: $finishReason)';
}


}

/// @nodoc
abstract mixin class _$SessionMessageCopyWith<$Res> implements $SessionMessageCopyWith<$Res> {
  factory _$SessionMessageCopyWith(_SessionMessage value, $Res Function(_SessionMessage) _then) = __$SessionMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String role, String content,@JsonKey(name: 'row_id') int? rowId,@JsonKey(name: 'display_kind') String? displayKind,@JsonKey(name: 'display_metadata') Map<String, dynamic>? displayMetadata,@JsonKey(name: 'display_commentary') List<String> displayCommentary,@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? timestamp, String? reasoning,@JsonKey(name: 'reasoning_content') String? reasoningContent,@JsonKey(name: 'tool_name') String? toolName,@JsonKey(name: 'context') String? toolContext,@JsonKey(name: 'args') Map<String, dynamic>? toolArgs,@JsonKey(name: 'tool_call_id') String? toolCallId,@JsonKey(name: 'tool_calls') Object? toolCalls,@JsonKey(name: 'token_count') num? tokenCount,@JsonKey(name: 'finish_reason') String? finishReason
});




}
/// @nodoc
class __$SessionMessageCopyWithImpl<$Res>
    implements _$SessionMessageCopyWith<$Res> {
  __$SessionMessageCopyWithImpl(this._self, this._then);

  final _SessionMessage _self;
  final $Res Function(_SessionMessage) _then;

/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? content = null,Object? rowId = freezed,Object? displayKind = freezed,Object? displayMetadata = freezed,Object? displayCommentary = null,Object? timestamp = freezed,Object? reasoning = freezed,Object? reasoningContent = freezed,Object? toolName = freezed,Object? toolContext = freezed,Object? toolArgs = freezed,Object? toolCallId = freezed,Object? toolCalls = freezed,Object? tokenCount = freezed,Object? finishReason = freezed,}) {
  return _then(_SessionMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,displayKind: freezed == displayKind ? _self.displayKind : displayKind // ignore: cast_nullable_to_non_nullable
as String?,displayMetadata: freezed == displayMetadata ? _self._displayMetadata : displayMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,displayCommentary: null == displayCommentary ? _self._displayCommentary : displayCommentary // ignore: cast_nullable_to_non_nullable
as List<String>,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent // ignore: cast_nullable_to_non_nullable
as String?,toolName: freezed == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String?,toolContext: freezed == toolContext ? _self.toolContext : toolContext // ignore: cast_nullable_to_non_nullable
as String?,toolArgs: freezed == toolArgs ? _self._toolArgs : toolArgs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,toolCallId: freezed == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String?,toolCalls: freezed == toolCalls ? _self.toolCalls : toolCalls ,tokenCount: freezed == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as num?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

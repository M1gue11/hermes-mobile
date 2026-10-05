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

 String get id; String get role; String get content;@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? get timestamp; String? get reasoning;@JsonKey(name: 'reasoning_content') String? get reasoningContent;@JsonKey(name: 'tool_name') String? get toolName;@JsonKey(name: 'tool_call_id') String? get toolCallId;@JsonKey(name: 'tool_calls') Object? get toolCalls;@JsonKey(name: 'token_count') num? get tokenCount;@JsonKey(name: 'finish_reason') String? get finishReason;
/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionMessageCopyWith<SessionMessage> get copyWith => _$SessionMessageCopyWithImpl<SessionMessage>(this as SessionMessage, _$identity);

  /// Serializes this SessionMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.reasoningContent, reasoningContent) || other.reasoningContent == reasoningContent)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,timestamp,reasoning,reasoningContent,toolName,toolCallId,const DeepCollectionEquality().hash(toolCalls),tokenCount,finishReason);

@override
String toString() {
  return 'SessionMessage(id: $id, role: $role, content: $content, timestamp: $timestamp, reasoning: $reasoning, reasoningContent: $reasoningContent, toolName: $toolName, toolCallId: $toolCallId, toolCalls: $toolCalls, tokenCount: $tokenCount, finishReason: $finishReason)';
}


}

/// @nodoc
abstract mixin class $SessionMessageCopyWith<$Res>  {
  factory $SessionMessageCopyWith(SessionMessage value, $Res Function(SessionMessage) _then) = _$SessionMessageCopyWithImpl;
@useResult
$Res call({
 String id, String role, String content,@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? timestamp, String? reasoning,@JsonKey(name: 'reasoning_content') String? reasoningContent,@JsonKey(name: 'tool_name') String? toolName,@JsonKey(name: 'tool_call_id') String? toolCallId,@JsonKey(name: 'tool_calls') Object? toolCalls,@JsonKey(name: 'token_count') num? tokenCount,@JsonKey(name: 'finish_reason') String? finishReason
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? content = null,Object? timestamp = freezed,Object? reasoning = freezed,Object? reasoningContent = freezed,Object? toolName = freezed,Object? toolCallId = freezed,Object? toolCalls = freezed,Object? tokenCount = freezed,Object? finishReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent // ignore: cast_nullable_to_non_nullable
as String?,toolName: freezed == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String?,toolCallId: freezed == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String role,  String content, @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? timestamp,  String? reasoning, @JsonKey(name: 'reasoning_content')  String? reasoningContent, @JsonKey(name: 'tool_name')  String? toolName, @JsonKey(name: 'tool_call_id')  String? toolCallId, @JsonKey(name: 'tool_calls')  Object? toolCalls, @JsonKey(name: 'token_count')  num? tokenCount, @JsonKey(name: 'finish_reason')  String? finishReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.timestamp,_that.reasoning,_that.reasoningContent,_that.toolName,_that.toolCallId,_that.toolCalls,_that.tokenCount,_that.finishReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String role,  String content, @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? timestamp,  String? reasoning, @JsonKey(name: 'reasoning_content')  String? reasoningContent, @JsonKey(name: 'tool_name')  String? toolName, @JsonKey(name: 'tool_call_id')  String? toolCallId, @JsonKey(name: 'tool_calls')  Object? toolCalls, @JsonKey(name: 'token_count')  num? tokenCount, @JsonKey(name: 'finish_reason')  String? finishReason)  $default,) {final _that = this;
switch (_that) {
case _SessionMessage():
return $default(_that.id,_that.role,_that.content,_that.timestamp,_that.reasoning,_that.reasoningContent,_that.toolName,_that.toolCallId,_that.toolCalls,_that.tokenCount,_that.finishReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String role,  String content, @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? timestamp,  String? reasoning, @JsonKey(name: 'reasoning_content')  String? reasoningContent, @JsonKey(name: 'tool_name')  String? toolName, @JsonKey(name: 'tool_call_id')  String? toolCallId, @JsonKey(name: 'tool_calls')  Object? toolCalls, @JsonKey(name: 'token_count')  num? tokenCount, @JsonKey(name: 'finish_reason')  String? finishReason)?  $default,) {final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.timestamp,_that.reasoning,_that.reasoningContent,_that.toolName,_that.toolCallId,_that.toolCalls,_that.tokenCount,_that.finishReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionMessage implements SessionMessage {
  const _SessionMessage({required this.id, required this.role, this.content = '', @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) this.timestamp, this.reasoning, @JsonKey(name: 'reasoning_content') this.reasoningContent, @JsonKey(name: 'tool_name') this.toolName, @JsonKey(name: 'tool_call_id') this.toolCallId, @JsonKey(name: 'tool_calls') this.toolCalls, @JsonKey(name: 'token_count') this.tokenCount, @JsonKey(name: 'finish_reason') this.finishReason});
  factory _SessionMessage.fromJson(Map<String, dynamic> json) => _$SessionMessageFromJson(json);

@override final  String id;
@override final  String role;
@override@JsonKey() final  String content;
@override@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) final  DateTime? timestamp;
@override final  String? reasoning;
@override@JsonKey(name: 'reasoning_content') final  String? reasoningContent;
@override@JsonKey(name: 'tool_name') final  String? toolName;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.reasoningContent, reasoningContent) || other.reasoningContent == reasoningContent)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,timestamp,reasoning,reasoningContent,toolName,toolCallId,const DeepCollectionEquality().hash(toolCalls),tokenCount,finishReason);

@override
String toString() {
  return 'SessionMessage(id: $id, role: $role, content: $content, timestamp: $timestamp, reasoning: $reasoning, reasoningContent: $reasoningContent, toolName: $toolName, toolCallId: $toolCallId, toolCalls: $toolCalls, tokenCount: $tokenCount, finishReason: $finishReason)';
}


}

/// @nodoc
abstract mixin class _$SessionMessageCopyWith<$Res> implements $SessionMessageCopyWith<$Res> {
  factory _$SessionMessageCopyWith(_SessionMessage value, $Res Function(_SessionMessage) _then) = __$SessionMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String role, String content,@JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? timestamp, String? reasoning,@JsonKey(name: 'reasoning_content') String? reasoningContent,@JsonKey(name: 'tool_name') String? toolName,@JsonKey(name: 'tool_call_id') String? toolCallId,@JsonKey(name: 'tool_calls') Object? toolCalls,@JsonKey(name: 'token_count') num? tokenCount,@JsonKey(name: 'finish_reason') String? finishReason
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? content = null,Object? timestamp = freezed,Object? reasoning = freezed,Object? reasoningContent = freezed,Object? toolName = freezed,Object? toolCallId = freezed,Object? toolCalls = freezed,Object? tokenCount = freezed,Object? finishReason = freezed,}) {
  return _then(_SessionMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent // ignore: cast_nullable_to_non_nullable
as String?,toolName: freezed == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String?,toolCallId: freezed == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String?,toolCalls: freezed == toolCalls ? _self.toolCalls : toolCalls ,tokenCount: freezed == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as num?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

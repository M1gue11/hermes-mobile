// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Conversation {

 String get id; String get title; String get preview; String? get model; String? get provider;@JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? get lastActive;@JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? get startedAt;@JsonKey(name: 'message_count') num get messageCount;@JsonKey(name: 'tool_call_count') num get toolCallCount; String? get source;@JsonKey(name: 'parent_session_id') String? get parentSessionId;@JsonKey(name: 'end_reason') String? get endReason;@JsonKey(name: 'input_tokens') num get inputTokens;@JsonKey(name: 'output_tokens') num get outputTokens;@JsonKey(name: 'estimated_cost_usd') num? get estimatedCostUsd;@JsonKey(name: 'actual_cost_usd') num? get actualCostUsd;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.model, model) || other.model == model)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.lastActive, lastActive) || other.lastActive == lastActive)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.messageCount, messageCount) || other.messageCount == messageCount)&&(identical(other.toolCallCount, toolCallCount) || other.toolCallCount == toolCallCount)&&(identical(other.source, source) || other.source == source)&&(identical(other.parentSessionId, parentSessionId) || other.parentSessionId == parentSessionId)&&(identical(other.endReason, endReason) || other.endReason == endReason)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.estimatedCostUsd, estimatedCostUsd) || other.estimatedCostUsd == estimatedCostUsd)&&(identical(other.actualCostUsd, actualCostUsd) || other.actualCostUsd == actualCostUsd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,preview,model,provider,lastActive,startedAt,messageCount,toolCallCount,source,parentSessionId,endReason,inputTokens,outputTokens,estimatedCostUsd,actualCostUsd);

@override
String toString() {
  return 'Conversation(id: $id, title: $title, preview: $preview, model: $model, provider: $provider, lastActive: $lastActive, startedAt: $startedAt, messageCount: $messageCount, toolCallCount: $toolCallCount, source: $source, parentSessionId: $parentSessionId, endReason: $endReason, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCostUsd: $estimatedCostUsd, actualCostUsd: $actualCostUsd)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id, String title, String preview, String? model, String? provider,@JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? lastActive,@JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? startedAt,@JsonKey(name: 'message_count') num messageCount,@JsonKey(name: 'tool_call_count') num toolCallCount, String? source,@JsonKey(name: 'parent_session_id') String? parentSessionId,@JsonKey(name: 'end_reason') String? endReason,@JsonKey(name: 'input_tokens') num inputTokens,@JsonKey(name: 'output_tokens') num outputTokens,@JsonKey(name: 'estimated_cost_usd') num? estimatedCostUsd,@JsonKey(name: 'actual_cost_usd') num? actualCostUsd
});




}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? preview = null,Object? model = freezed,Object? provider = freezed,Object? lastActive = freezed,Object? startedAt = freezed,Object? messageCount = null,Object? toolCallCount = null,Object? source = freezed,Object? parentSessionId = freezed,Object? endReason = freezed,Object? inputTokens = null,Object? outputTokens = null,Object? estimatedCostUsd = freezed,Object? actualCostUsd = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,lastActive: freezed == lastActive ? _self.lastActive : lastActive // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,messageCount: null == messageCount ? _self.messageCount : messageCount // ignore: cast_nullable_to_non_nullable
as num,toolCallCount: null == toolCallCount ? _self.toolCallCount : toolCallCount // ignore: cast_nullable_to_non_nullable
as num,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,parentSessionId: freezed == parentSessionId ? _self.parentSessionId : parentSessionId // ignore: cast_nullable_to_non_nullable
as String?,endReason: freezed == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as String?,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as num,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as num,estimatedCostUsd: freezed == estimatedCostUsd ? _self.estimatedCostUsd : estimatedCostUsd // ignore: cast_nullable_to_non_nullable
as num?,actualCostUsd: freezed == actualCostUsd ? _self.actualCostUsd : actualCostUsd // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String preview,  String? model,  String? provider, @JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? lastActive, @JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? startedAt, @JsonKey(name: 'message_count')  num messageCount, @JsonKey(name: 'tool_call_count')  num toolCallCount,  String? source, @JsonKey(name: 'parent_session_id')  String? parentSessionId, @JsonKey(name: 'end_reason')  String? endReason, @JsonKey(name: 'input_tokens')  num inputTokens, @JsonKey(name: 'output_tokens')  num outputTokens, @JsonKey(name: 'estimated_cost_usd')  num? estimatedCostUsd, @JsonKey(name: 'actual_cost_usd')  num? actualCostUsd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.title,_that.preview,_that.model,_that.provider,_that.lastActive,_that.startedAt,_that.messageCount,_that.toolCallCount,_that.source,_that.parentSessionId,_that.endReason,_that.inputTokens,_that.outputTokens,_that.estimatedCostUsd,_that.actualCostUsd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String preview,  String? model,  String? provider, @JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? lastActive, @JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? startedAt, @JsonKey(name: 'message_count')  num messageCount, @JsonKey(name: 'tool_call_count')  num toolCallCount,  String? source, @JsonKey(name: 'parent_session_id')  String? parentSessionId, @JsonKey(name: 'end_reason')  String? endReason, @JsonKey(name: 'input_tokens')  num inputTokens, @JsonKey(name: 'output_tokens')  num outputTokens, @JsonKey(name: 'estimated_cost_usd')  num? estimatedCostUsd, @JsonKey(name: 'actual_cost_usd')  num? actualCostUsd)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.id,_that.title,_that.preview,_that.model,_that.provider,_that.lastActive,_that.startedAt,_that.messageCount,_that.toolCallCount,_that.source,_that.parentSessionId,_that.endReason,_that.inputTokens,_that.outputTokens,_that.estimatedCostUsd,_that.actualCostUsd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String preview,  String? model,  String? provider, @JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? lastActive, @JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson)  DateTime? startedAt, @JsonKey(name: 'message_count')  num messageCount, @JsonKey(name: 'tool_call_count')  num toolCallCount,  String? source, @JsonKey(name: 'parent_session_id')  String? parentSessionId, @JsonKey(name: 'end_reason')  String? endReason, @JsonKey(name: 'input_tokens')  num inputTokens, @JsonKey(name: 'output_tokens')  num outputTokens, @JsonKey(name: 'estimated_cost_usd')  num? estimatedCostUsd, @JsonKey(name: 'actual_cost_usd')  num? actualCostUsd)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.title,_that.preview,_that.model,_that.provider,_that.lastActive,_that.startedAt,_that.messageCount,_that.toolCallCount,_that.source,_that.parentSessionId,_that.endReason,_that.inputTokens,_that.outputTokens,_that.estimatedCostUsd,_that.actualCostUsd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation implements Conversation {
  const _Conversation({required this.id, this.title = 'Nova conversa', this.preview = '', this.model, this.provider, @JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) this.lastActive, @JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) this.startedAt, @JsonKey(name: 'message_count') this.messageCount = 0, @JsonKey(name: 'tool_call_count') this.toolCallCount = 0, this.source, @JsonKey(name: 'parent_session_id') this.parentSessionId, @JsonKey(name: 'end_reason') this.endReason, @JsonKey(name: 'input_tokens') this.inputTokens = 0, @JsonKey(name: 'output_tokens') this.outputTokens = 0, @JsonKey(name: 'estimated_cost_usd') this.estimatedCostUsd, @JsonKey(name: 'actual_cost_usd') this.actualCostUsd});
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String preview;
@override final  String? model;
@override final  String? provider;
@override@JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) final  DateTime? lastActive;
@override@JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) final  DateTime? startedAt;
@override@JsonKey(name: 'message_count') final  num messageCount;
@override@JsonKey(name: 'tool_call_count') final  num toolCallCount;
@override final  String? source;
@override@JsonKey(name: 'parent_session_id') final  String? parentSessionId;
@override@JsonKey(name: 'end_reason') final  String? endReason;
@override@JsonKey(name: 'input_tokens') final  num inputTokens;
@override@JsonKey(name: 'output_tokens') final  num outputTokens;
@override@JsonKey(name: 'estimated_cost_usd') final  num? estimatedCostUsd;
@override@JsonKey(name: 'actual_cost_usd') final  num? actualCostUsd;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.model, model) || other.model == model)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.lastActive, lastActive) || other.lastActive == lastActive)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.messageCount, messageCount) || other.messageCount == messageCount)&&(identical(other.toolCallCount, toolCallCount) || other.toolCallCount == toolCallCount)&&(identical(other.source, source) || other.source == source)&&(identical(other.parentSessionId, parentSessionId) || other.parentSessionId == parentSessionId)&&(identical(other.endReason, endReason) || other.endReason == endReason)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.estimatedCostUsd, estimatedCostUsd) || other.estimatedCostUsd == estimatedCostUsd)&&(identical(other.actualCostUsd, actualCostUsd) || other.actualCostUsd == actualCostUsd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,preview,model,provider,lastActive,startedAt,messageCount,toolCallCount,source,parentSessionId,endReason,inputTokens,outputTokens,estimatedCostUsd,actualCostUsd);

@override
String toString() {
  return 'Conversation(id: $id, title: $title, preview: $preview, model: $model, provider: $provider, lastActive: $lastActive, startedAt: $startedAt, messageCount: $messageCount, toolCallCount: $toolCallCount, source: $source, parentSessionId: $parentSessionId, endReason: $endReason, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCostUsd: $estimatedCostUsd, actualCostUsd: $actualCostUsd)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String preview, String? model, String? provider,@JsonKey(name: 'last_active', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? lastActive,@JsonKey(name: 'started_at', fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? startedAt,@JsonKey(name: 'message_count') num messageCount,@JsonKey(name: 'tool_call_count') num toolCallCount, String? source,@JsonKey(name: 'parent_session_id') String? parentSessionId,@JsonKey(name: 'end_reason') String? endReason,@JsonKey(name: 'input_tokens') num inputTokens,@JsonKey(name: 'output_tokens') num outputTokens,@JsonKey(name: 'estimated_cost_usd') num? estimatedCostUsd,@JsonKey(name: 'actual_cost_usd') num? actualCostUsd
});




}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? preview = null,Object? model = freezed,Object? provider = freezed,Object? lastActive = freezed,Object? startedAt = freezed,Object? messageCount = null,Object? toolCallCount = null,Object? source = freezed,Object? parentSessionId = freezed,Object? endReason = freezed,Object? inputTokens = null,Object? outputTokens = null,Object? estimatedCostUsd = freezed,Object? actualCostUsd = freezed,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,lastActive: freezed == lastActive ? _self.lastActive : lastActive // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,messageCount: null == messageCount ? _self.messageCount : messageCount // ignore: cast_nullable_to_non_nullable
as num,toolCallCount: null == toolCallCount ? _self.toolCallCount : toolCallCount // ignore: cast_nullable_to_non_nullable
as num,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,parentSessionId: freezed == parentSessionId ? _self.parentSessionId : parentSessionId // ignore: cast_nullable_to_non_nullable
as String?,endReason: freezed == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as String?,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as num,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as num,estimatedCostUsd: freezed == estimatedCostUsd ? _self.estimatedCostUsd : estimatedCostUsd // ignore: cast_nullable_to_non_nullable
as num?,actualCostUsd: freezed == actualCostUsd ? _self.actualCostUsd : actualCostUsd // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}

// dart format on

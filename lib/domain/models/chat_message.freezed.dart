// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatMessage {

 String get id; String get text; String? get time;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.time, time) || other.time == time));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,time);

@override
String toString() {
  return 'ChatMessage(id: $id, text: $text, time: $time)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String text, String time
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? time = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time! : time // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserMessage value)?  user,TResult Function( AssistantMessage value)?  assistant,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that);case AssistantMessage() when assistant != null:
return assistant(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserMessage value)  user,required TResult Function( AssistantMessage value)  assistant,}){
final _that = this;
switch (_that) {
case UserMessage():
return user(_that);case AssistantMessage():
return assistant(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserMessage value)?  user,TResult? Function( AssistantMessage value)?  assistant,}){
final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that);case AssistantMessage() when assistant != null:
return assistant(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String text,  String time,  bool scaffolding)?  user,TResult Function( String id,  ChatPhase phase,  String reasoning,  String activity,  String thinking,  String? reasonTime,  List<ToolCall> tools,  List<TurnActivity> activityItems,  String text,  String? time,  String? model,  String? runId,  String? error)?  assistant,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that.id,_that.text,_that.time,_that.scaffolding);case AssistantMessage() when assistant != null:
return assistant(_that.id,_that.phase,_that.reasoning,_that.activity,_that.thinking,_that.reasonTime,_that.tools,_that.activityItems,_that.text,_that.time,_that.model,_that.runId,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String text,  String time,  bool scaffolding)  user,required TResult Function( String id,  ChatPhase phase,  String reasoning,  String activity,  String thinking,  String? reasonTime,  List<ToolCall> tools,  List<TurnActivity> activityItems,  String text,  String? time,  String? model,  String? runId,  String? error)  assistant,}) {final _that = this;
switch (_that) {
case UserMessage():
return user(_that.id,_that.text,_that.time,_that.scaffolding);case AssistantMessage():
return assistant(_that.id,_that.phase,_that.reasoning,_that.activity,_that.thinking,_that.reasonTime,_that.tools,_that.activityItems,_that.text,_that.time,_that.model,_that.runId,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String text,  String time,  bool scaffolding)?  user,TResult? Function( String id,  ChatPhase phase,  String reasoning,  String activity,  String thinking,  String? reasonTime,  List<ToolCall> tools,  List<TurnActivity> activityItems,  String text,  String? time,  String? model,  String? runId,  String? error)?  assistant,}) {final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that.id,_that.text,_that.time,_that.scaffolding);case AssistantMessage() when assistant != null:
return assistant(_that.id,_that.phase,_that.reasoning,_that.activity,_that.thinking,_that.reasonTime,_that.tools,_that.activityItems,_that.text,_that.time,_that.model,_that.runId,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class UserMessage implements ChatMessage {
  const UserMessage({required this.id, required this.text, required this.time, this.scaffolding = false});
  

@override final  String id;
@override final  String text;
@override final  String time;
/// Turno com papel de usuário que o runtime injetou, e não a pessoa.
///
/// Continua sendo `user` porque é assim que está persistido e é assim que o
/// modelo o recebeu; o que muda é a apresentação. Ver A23.
@JsonKey() final  bool scaffolding;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserMessageCopyWith<UserMessage> get copyWith => _$UserMessageCopyWithImpl<UserMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.time, time) || other.time == time)&&(identical(other.scaffolding, scaffolding) || other.scaffolding == scaffolding));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,time,scaffolding);

@override
String toString() {
  return 'ChatMessage.user(id: $id, text: $text, time: $time, scaffolding: $scaffolding)';
}


}

/// @nodoc
abstract mixin class $UserMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $UserMessageCopyWith(UserMessage value, $Res Function(UserMessage) _then) = _$UserMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, String time, bool scaffolding
});




}
/// @nodoc
class _$UserMessageCopyWithImpl<$Res>
    implements $UserMessageCopyWith<$Res> {
  _$UserMessageCopyWithImpl(this._self, this._then);

  final UserMessage _self;
  final $Res Function(UserMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? time = null,Object? scaffolding = null,}) {
  return _then(UserMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,scaffolding: null == scaffolding ? _self.scaffolding : scaffolding // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AssistantMessage implements ChatMessage {
  const AssistantMessage({required this.id, this.phase = ChatPhase.reasoning, this.reasoning = '', this.activity = '', this.thinking = '', this.reasonTime, final  List<ToolCall> tools = const <ToolCall>[], final  List<TurnActivity> activityItems = const <TurnActivity>[], this.text = '', this.time, this.model, this.runId, this.error}): _tools = tools,_activityItems = activityItems;
  

@override final  String id;
@JsonKey() final  ChatPhase phase;
@JsonKey() final  String reasoning;
/// Prévia de atividade do servidor, nunca raciocínio nativo do modelo.
@JsonKey() final  String activity;
/// Estado transitório do turno em execução, o kaomoji do `thinking.delta`.
///
/// Vive só enquanto o turno corre: o gateway o substitui a cada chegada e
/// o apaga com um evento de texto vazio. Por isso ele **não** está em
/// [activityItems] e a conversa reaberta nunca o reconstrói, que é o que
/// mantém a timeline ao vivo igual à do histórico.
@JsonKey() final  String thinking;
 final  String? reasonTime;
 final  List<ToolCall> _tools;
@JsonKey() List<ToolCall> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}

 final  List<TurnActivity> _activityItems;
@JsonKey() List<TurnActivity> get activityItems {
  if (_activityItems is EqualUnmodifiableListView) return _activityItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activityItems);
}

@override@JsonKey() final  String text;
@override final  String? time;
 final  String? model;
 final  String? runId;
 final  String? error;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantMessageCopyWith<AssistantMessage> get copyWith => _$AssistantMessageCopyWithImpl<AssistantMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.reasonTime, reasonTime) || other.reasonTime == reasonTime)&&const DeepCollectionEquality().equals(other._tools, _tools)&&const DeepCollectionEquality().equals(other._activityItems, _activityItems)&&(identical(other.text, text) || other.text == text)&&(identical(other.time, time) || other.time == time)&&(identical(other.model, model) || other.model == model)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,id,phase,reasoning,activity,thinking,reasonTime,const DeepCollectionEquality().hash(_tools),const DeepCollectionEquality().hash(_activityItems),text,time,model,runId,error);

@override
String toString() {
  return 'ChatMessage.assistant(id: $id, phase: $phase, reasoning: $reasoning, activity: $activity, thinking: $thinking, reasonTime: $reasonTime, tools: $tools, activityItems: $activityItems, text: $text, time: $time, model: $model, runId: $runId, error: $error)';
}


}

/// @nodoc
abstract mixin class $AssistantMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $AssistantMessageCopyWith(AssistantMessage value, $Res Function(AssistantMessage) _then) = _$AssistantMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, ChatPhase phase, String reasoning, String activity, String thinking, String? reasonTime, List<ToolCall> tools, List<TurnActivity> activityItems, String text, String? time, String? model, String? runId, String? error
});




}
/// @nodoc
class _$AssistantMessageCopyWithImpl<$Res>
    implements $AssistantMessageCopyWith<$Res> {
  _$AssistantMessageCopyWithImpl(this._self, this._then);

  final AssistantMessage _self;
  final $Res Function(AssistantMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phase = null,Object? reasoning = null,Object? activity = null,Object? thinking = null,Object? reasonTime = freezed,Object? tools = null,Object? activityItems = null,Object? text = null,Object? time = freezed,Object? model = freezed,Object? runId = freezed,Object? error = freezed,}) {
  return _then(AssistantMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChatPhase,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String,reasonTime: freezed == reasonTime ? _self.reasonTime : reasonTime // ignore: cast_nullable_to_non_nullable
as String?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<ToolCall>,activityItems: null == activityItems ? _self._activityItems : activityItems // ignore: cast_nullable_to_non_nullable
as List<TurnActivity>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

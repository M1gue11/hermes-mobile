// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatState {

 List<ChatMessage> get messages; String get title; bool get streaming; String get modelId; String? get modelProvider; ReasoningConfig get reasoning; String get instructions; String? get sessionId; String? get runId;/// A rota já abriu, mas histórico e eventual turno ativo ainda estão sendo
/// reconciliados. Nunca deve bloquear a navegação na lista.
 bool get openingConversation; HermesFailure? get conversationLoadFailure;/// Aprovação de ferramenta esperando gesto explícito.
///
/// Enquanto não for nulo a run está parada no servidor, com a thread do
/// agente bloqueada. Nada é aprovado por omissão, e o composer fica fechado:
/// mandar outra mensagem enquanto o Hermes espera resposta seria confuso.
 ApprovalRequest? get pendingApproval;/// Última recusa do servidor a uma resposta de aprovação, para a tela poder
/// dizer o que aconteceu em vez de simplesmente não reagir ao toque.
 String? get approvalError;/// Pergunta do gateway TUI que bloqueia o turno até resposta explícita.
 ClarifyRequest? get pendingClarification; String? get clarificationError;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.title, title) || other.title == title)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.modelProvider, modelProvider) || other.modelProvider == modelProvider)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.openingConversation, openingConversation) || other.openingConversation == openingConversation)&&(identical(other.conversationLoadFailure, conversationLoadFailure) || other.conversationLoadFailure == conversationLoadFailure)&&(identical(other.pendingApproval, pendingApproval) || other.pendingApproval == pendingApproval)&&(identical(other.approvalError, approvalError) || other.approvalError == approvalError)&&(identical(other.pendingClarification, pendingClarification) || other.pendingClarification == pendingClarification)&&(identical(other.clarificationError, clarificationError) || other.clarificationError == clarificationError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(messages),title,streaming,modelId,modelProvider,reasoning,instructions,sessionId,runId,openingConversation,conversationLoadFailure,pendingApproval,approvalError,pendingClarification,clarificationError);

@override
String toString() {
  return 'ChatState(messages: $messages, title: $title, streaming: $streaming, modelId: $modelId, modelProvider: $modelProvider, reasoning: $reasoning, instructions: $instructions, sessionId: $sessionId, runId: $runId, openingConversation: $openingConversation, conversationLoadFailure: $conversationLoadFailure, pendingApproval: $pendingApproval, approvalError: $approvalError, pendingClarification: $pendingClarification, clarificationError: $clarificationError)';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 List<ChatMessage> messages, String title, bool streaming, String modelId, String? modelProvider, ReasoningConfig reasoning, String instructions, String? sessionId, String? runId, bool openingConversation, HermesFailure? conversationLoadFailure, ApprovalRequest? pendingApproval, String? approvalError, ClarifyRequest? pendingClarification, String? clarificationError
});


$ReasoningConfigCopyWith<$Res> get reasoning;

}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? title = null,Object? streaming = null,Object? modelId = null,Object? modelProvider = freezed,Object? reasoning = null,Object? instructions = null,Object? sessionId = freezed,Object? runId = freezed,Object? openingConversation = null,Object? conversationLoadFailure = freezed,Object? pendingApproval = freezed,Object? approvalError = freezed,Object? pendingClarification = freezed,Object? clarificationError = freezed,}) {
  return _then(_self.copyWith(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,modelProvider: freezed == modelProvider ? _self.modelProvider : modelProvider // ignore: cast_nullable_to_non_nullable
as String?,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as ReasoningConfig,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,openingConversation: null == openingConversation ? _self.openingConversation : openingConversation // ignore: cast_nullable_to_non_nullable
as bool,conversationLoadFailure: freezed == conversationLoadFailure ? _self.conversationLoadFailure : conversationLoadFailure // ignore: cast_nullable_to_non_nullable
as HermesFailure?,pendingApproval: freezed == pendingApproval ? _self.pendingApproval : pendingApproval // ignore: cast_nullable_to_non_nullable
as ApprovalRequest?,approvalError: freezed == approvalError ? _self.approvalError : approvalError // ignore: cast_nullable_to_non_nullable
as String?,pendingClarification: freezed == pendingClarification ? _self.pendingClarification : pendingClarification // ignore: cast_nullable_to_non_nullable
as ClarifyRequest?,clarificationError: freezed == clarificationError ? _self.clarificationError : clarificationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReasoningConfigCopyWith<$Res> get reasoning {
  
  return $ReasoningConfigCopyWith<$Res>(_self.reasoning, (value) {
    return _then(_self.copyWith(reasoning: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatState value)  $default,){
final _that = this;
switch (_that) {
case _ChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChatMessage> messages,  String title,  bool streaming,  String modelId,  String? modelProvider,  ReasoningConfig reasoning,  String instructions,  String? sessionId,  String? runId,  bool openingConversation,  HermesFailure? conversationLoadFailure,  ApprovalRequest? pendingApproval,  String? approvalError,  ClarifyRequest? pendingClarification,  String? clarificationError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.title,_that.streaming,_that.modelId,_that.modelProvider,_that.reasoning,_that.instructions,_that.sessionId,_that.runId,_that.openingConversation,_that.conversationLoadFailure,_that.pendingApproval,_that.approvalError,_that.pendingClarification,_that.clarificationError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChatMessage> messages,  String title,  bool streaming,  String modelId,  String? modelProvider,  ReasoningConfig reasoning,  String instructions,  String? sessionId,  String? runId,  bool openingConversation,  HermesFailure? conversationLoadFailure,  ApprovalRequest? pendingApproval,  String? approvalError,  ClarifyRequest? pendingClarification,  String? clarificationError)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.messages,_that.title,_that.streaming,_that.modelId,_that.modelProvider,_that.reasoning,_that.instructions,_that.sessionId,_that.runId,_that.openingConversation,_that.conversationLoadFailure,_that.pendingApproval,_that.approvalError,_that.pendingClarification,_that.clarificationError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChatMessage> messages,  String title,  bool streaming,  String modelId,  String? modelProvider,  ReasoningConfig reasoning,  String instructions,  String? sessionId,  String? runId,  bool openingConversation,  HermesFailure? conversationLoadFailure,  ApprovalRequest? pendingApproval,  String? approvalError,  ClarifyRequest? pendingClarification,  String? clarificationError)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.title,_that.streaming,_that.modelId,_that.modelProvider,_that.reasoning,_that.instructions,_that.sessionId,_that.runId,_that.openingConversation,_that.conversationLoadFailure,_that.pendingApproval,_that.approvalError,_that.pendingClarification,_that.clarificationError);case _:
  return null;

}
}

}

/// @nodoc


class _ChatState implements ChatState {
  const _ChatState({final  List<ChatMessage> messages = const <ChatMessage>[], this.title = 'Nova conversa', this.streaming = false, this.modelId = '', this.modelProvider, this.reasoning = const ReasoningConfig(), this.instructions = '', this.sessionId, this.runId, this.openingConversation = false, this.conversationLoadFailure, this.pendingApproval, this.approvalError, this.pendingClarification, this.clarificationError}): _messages = messages;
  

 final  List<ChatMessage> _messages;
@override@JsonKey() List<ChatMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey() final  String title;
@override@JsonKey() final  bool streaming;
@override@JsonKey() final  String modelId;
@override final  String? modelProvider;
@override@JsonKey() final  ReasoningConfig reasoning;
@override@JsonKey() final  String instructions;
@override final  String? sessionId;
@override final  String? runId;
/// A rota já abriu, mas histórico e eventual turno ativo ainda estão sendo
/// reconciliados. Nunca deve bloquear a navegação na lista.
@override@JsonKey() final  bool openingConversation;
@override final  HermesFailure? conversationLoadFailure;
/// Aprovação de ferramenta esperando gesto explícito.
///
/// Enquanto não for nulo a run está parada no servidor, com a thread do
/// agente bloqueada. Nada é aprovado por omissão, e o composer fica fechado:
/// mandar outra mensagem enquanto o Hermes espera resposta seria confuso.
@override final  ApprovalRequest? pendingApproval;
/// Última recusa do servidor a uma resposta de aprovação, para a tela poder
/// dizer o que aconteceu em vez de simplesmente não reagir ao toque.
@override final  String? approvalError;
/// Pergunta do gateway TUI que bloqueia o turno até resposta explícita.
@override final  ClarifyRequest? pendingClarification;
@override final  String? clarificationError;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.title, title) || other.title == title)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.modelProvider, modelProvider) || other.modelProvider == modelProvider)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.openingConversation, openingConversation) || other.openingConversation == openingConversation)&&(identical(other.conversationLoadFailure, conversationLoadFailure) || other.conversationLoadFailure == conversationLoadFailure)&&(identical(other.pendingApproval, pendingApproval) || other.pendingApproval == pendingApproval)&&(identical(other.approvalError, approvalError) || other.approvalError == approvalError)&&(identical(other.pendingClarification, pendingClarification) || other.pendingClarification == pendingClarification)&&(identical(other.clarificationError, clarificationError) || other.clarificationError == clarificationError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),title,streaming,modelId,modelProvider,reasoning,instructions,sessionId,runId,openingConversation,conversationLoadFailure,pendingApproval,approvalError,pendingClarification,clarificationError);

@override
String toString() {
  return 'ChatState(messages: $messages, title: $title, streaming: $streaming, modelId: $modelId, modelProvider: $modelProvider, reasoning: $reasoning, instructions: $instructions, sessionId: $sessionId, runId: $runId, openingConversation: $openingConversation, conversationLoadFailure: $conversationLoadFailure, pendingApproval: $pendingApproval, approvalError: $approvalError, pendingClarification: $pendingClarification, clarificationError: $clarificationError)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 List<ChatMessage> messages, String title, bool streaming, String modelId, String? modelProvider, ReasoningConfig reasoning, String instructions, String? sessionId, String? runId, bool openingConversation, HermesFailure? conversationLoadFailure, ApprovalRequest? pendingApproval, String? approvalError, ClarifyRequest? pendingClarification, String? clarificationError
});


@override $ReasoningConfigCopyWith<$Res> get reasoning;

}
/// @nodoc
class __$ChatStateCopyWithImpl<$Res>
    implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? title = null,Object? streaming = null,Object? modelId = null,Object? modelProvider = freezed,Object? reasoning = null,Object? instructions = null,Object? sessionId = freezed,Object? runId = freezed,Object? openingConversation = null,Object? conversationLoadFailure = freezed,Object? pendingApproval = freezed,Object? approvalError = freezed,Object? pendingClarification = freezed,Object? clarificationError = freezed,}) {
  return _then(_ChatState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,modelProvider: freezed == modelProvider ? _self.modelProvider : modelProvider // ignore: cast_nullable_to_non_nullable
as String?,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as ReasoningConfig,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,openingConversation: null == openingConversation ? _self.openingConversation : openingConversation // ignore: cast_nullable_to_non_nullable
as bool,conversationLoadFailure: freezed == conversationLoadFailure ? _self.conversationLoadFailure : conversationLoadFailure // ignore: cast_nullable_to_non_nullable
as HermesFailure?,pendingApproval: freezed == pendingApproval ? _self.pendingApproval : pendingApproval // ignore: cast_nullable_to_non_nullable
as ApprovalRequest?,approvalError: freezed == approvalError ? _self.approvalError : approvalError // ignore: cast_nullable_to_non_nullable
as String?,pendingClarification: freezed == pendingClarification ? _self.pendingClarification : pendingClarification // ignore: cast_nullable_to_non_nullable
as ClarifyRequest?,clarificationError: freezed == clarificationError ? _self.clarificationError : clarificationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReasoningConfigCopyWith<$Res> get reasoning {
  
  return $ReasoningConfigCopyWith<$Res>(_self.reasoning, (value) {
    return _then(_self.copyWith(reasoning: value));
  });
}
}

// dart format on

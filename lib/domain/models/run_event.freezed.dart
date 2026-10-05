// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RunEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RunEvent()';
}


}

/// @nodoc
class $RunEventCopyWith<$Res>  {
$RunEventCopyWith(RunEvent _, $Res Function(RunEvent) __);
}


/// Adds pattern-matching-related methods to [RunEvent].
extension RunEventPatterns on RunEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RunActivityPreview value)?  activityPreview,TResult Function( RunReasoningDelta value)?  reasoningDelta,TResult Function( RunThinkingState value)?  thinkingState,TResult Function( RunTextDelta value)?  delta,TResult Function( RunToolProgress value)?  toolProgress,TResult Function( RunApprovalRequest value)?  approvalRequest,TResult Function( RunApprovalResolved value)?  approvalResolved,TResult Function( RunClarifyRequest value)?  clarifyRequest,TResult Function( RunClarifyResolved value)?  clarifyResolved,TResult Function( RunStatusEvent value)?  status,TResult Function( RunCompleted value)?  completed,TResult Function( RunFailed value)?  failed,TResult Function( RunUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RunActivityPreview() when activityPreview != null:
return activityPreview(_that);case RunReasoningDelta() when reasoningDelta != null:
return reasoningDelta(_that);case RunThinkingState() when thinkingState != null:
return thinkingState(_that);case RunTextDelta() when delta != null:
return delta(_that);case RunToolProgress() when toolProgress != null:
return toolProgress(_that);case RunApprovalRequest() when approvalRequest != null:
return approvalRequest(_that);case RunApprovalResolved() when approvalResolved != null:
return approvalResolved(_that);case RunClarifyRequest() when clarifyRequest != null:
return clarifyRequest(_that);case RunClarifyResolved() when clarifyResolved != null:
return clarifyResolved(_that);case RunStatusEvent() when status != null:
return status(_that);case RunCompleted() when completed != null:
return completed(_that);case RunFailed() when failed != null:
return failed(_that);case RunUnknown() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RunActivityPreview value)  activityPreview,required TResult Function( RunReasoningDelta value)  reasoningDelta,required TResult Function( RunThinkingState value)  thinkingState,required TResult Function( RunTextDelta value)  delta,required TResult Function( RunToolProgress value)  toolProgress,required TResult Function( RunApprovalRequest value)  approvalRequest,required TResult Function( RunApprovalResolved value)  approvalResolved,required TResult Function( RunClarifyRequest value)  clarifyRequest,required TResult Function( RunClarifyResolved value)  clarifyResolved,required TResult Function( RunStatusEvent value)  status,required TResult Function( RunCompleted value)  completed,required TResult Function( RunFailed value)  failed,required TResult Function( RunUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case RunActivityPreview():
return activityPreview(_that);case RunReasoningDelta():
return reasoningDelta(_that);case RunThinkingState():
return thinkingState(_that);case RunTextDelta():
return delta(_that);case RunToolProgress():
return toolProgress(_that);case RunApprovalRequest():
return approvalRequest(_that);case RunApprovalResolved():
return approvalResolved(_that);case RunClarifyRequest():
return clarifyRequest(_that);case RunClarifyResolved():
return clarifyResolved(_that);case RunStatusEvent():
return status(_that);case RunCompleted():
return completed(_that);case RunFailed():
return failed(_that);case RunUnknown():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RunActivityPreview value)?  activityPreview,TResult? Function( RunReasoningDelta value)?  reasoningDelta,TResult? Function( RunThinkingState value)?  thinkingState,TResult? Function( RunTextDelta value)?  delta,TResult? Function( RunToolProgress value)?  toolProgress,TResult? Function( RunApprovalRequest value)?  approvalRequest,TResult? Function( RunApprovalResolved value)?  approvalResolved,TResult? Function( RunClarifyRequest value)?  clarifyRequest,TResult? Function( RunClarifyResolved value)?  clarifyResolved,TResult? Function( RunStatusEvent value)?  status,TResult? Function( RunCompleted value)?  completed,TResult? Function( RunFailed value)?  failed,TResult? Function( RunUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case RunActivityPreview() when activityPreview != null:
return activityPreview(_that);case RunReasoningDelta() when reasoningDelta != null:
return reasoningDelta(_that);case RunThinkingState() when thinkingState != null:
return thinkingState(_that);case RunTextDelta() when delta != null:
return delta(_that);case RunToolProgress() when toolProgress != null:
return toolProgress(_that);case RunApprovalRequest() when approvalRequest != null:
return approvalRequest(_that);case RunApprovalResolved() when approvalResolved != null:
return approvalResolved(_that);case RunClarifyRequest() when clarifyRequest != null:
return clarifyRequest(_that);case RunClarifyResolved() when clarifyResolved != null:
return clarifyResolved(_that);case RunStatusEvent() when status != null:
return status(_that);case RunCompleted() when completed != null:
return completed(_that);case RunFailed() when failed != null:
return failed(_that);case RunUnknown() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  activityPreview,TResult Function( String text)?  reasoningDelta,TResult Function( String text)?  thinkingState,TResult Function( String text)?  delta,TResult Function( ToolCall tool)?  toolProgress,TResult Function( ApprovalRequest request)?  approvalRequest,TResult Function( ApprovalChoice choice)?  approvalResolved,TResult Function( ClarifyRequest request)?  clarifyRequest,TResult Function()?  clarifyResolved,TResult Function( RunStatus status)?  status,TResult Function( String? output)?  completed,TResult Function( String? error)?  failed,TResult Function( String type,  Map<String, dynamic> data)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RunActivityPreview() when activityPreview != null:
return activityPreview(_that.text);case RunReasoningDelta() when reasoningDelta != null:
return reasoningDelta(_that.text);case RunThinkingState() when thinkingState != null:
return thinkingState(_that.text);case RunTextDelta() when delta != null:
return delta(_that.text);case RunToolProgress() when toolProgress != null:
return toolProgress(_that.tool);case RunApprovalRequest() when approvalRequest != null:
return approvalRequest(_that.request);case RunApprovalResolved() when approvalResolved != null:
return approvalResolved(_that.choice);case RunClarifyRequest() when clarifyRequest != null:
return clarifyRequest(_that.request);case RunClarifyResolved() when clarifyResolved != null:
return clarifyResolved();case RunStatusEvent() when status != null:
return status(_that.status);case RunCompleted() when completed != null:
return completed(_that.output);case RunFailed() when failed != null:
return failed(_that.error);case RunUnknown() when unknown != null:
return unknown(_that.type,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  activityPreview,required TResult Function( String text)  reasoningDelta,required TResult Function( String text)  thinkingState,required TResult Function( String text)  delta,required TResult Function( ToolCall tool)  toolProgress,required TResult Function( ApprovalRequest request)  approvalRequest,required TResult Function( ApprovalChoice choice)  approvalResolved,required TResult Function( ClarifyRequest request)  clarifyRequest,required TResult Function()  clarifyResolved,required TResult Function( RunStatus status)  status,required TResult Function( String? output)  completed,required TResult Function( String? error)  failed,required TResult Function( String type,  Map<String, dynamic> data)  unknown,}) {final _that = this;
switch (_that) {
case RunActivityPreview():
return activityPreview(_that.text);case RunReasoningDelta():
return reasoningDelta(_that.text);case RunThinkingState():
return thinkingState(_that.text);case RunTextDelta():
return delta(_that.text);case RunToolProgress():
return toolProgress(_that.tool);case RunApprovalRequest():
return approvalRequest(_that.request);case RunApprovalResolved():
return approvalResolved(_that.choice);case RunClarifyRequest():
return clarifyRequest(_that.request);case RunClarifyResolved():
return clarifyResolved();case RunStatusEvent():
return status(_that.status);case RunCompleted():
return completed(_that.output);case RunFailed():
return failed(_that.error);case RunUnknown():
return unknown(_that.type,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  activityPreview,TResult? Function( String text)?  reasoningDelta,TResult? Function( String text)?  thinkingState,TResult? Function( String text)?  delta,TResult? Function( ToolCall tool)?  toolProgress,TResult? Function( ApprovalRequest request)?  approvalRequest,TResult? Function( ApprovalChoice choice)?  approvalResolved,TResult? Function( ClarifyRequest request)?  clarifyRequest,TResult? Function()?  clarifyResolved,TResult? Function( RunStatus status)?  status,TResult? Function( String? output)?  completed,TResult? Function( String? error)?  failed,TResult? Function( String type,  Map<String, dynamic> data)?  unknown,}) {final _that = this;
switch (_that) {
case RunActivityPreview() when activityPreview != null:
return activityPreview(_that.text);case RunReasoningDelta() when reasoningDelta != null:
return reasoningDelta(_that.text);case RunThinkingState() when thinkingState != null:
return thinkingState(_that.text);case RunTextDelta() when delta != null:
return delta(_that.text);case RunToolProgress() when toolProgress != null:
return toolProgress(_that.tool);case RunApprovalRequest() when approvalRequest != null:
return approvalRequest(_that.request);case RunApprovalResolved() when approvalResolved != null:
return approvalResolved(_that.choice);case RunClarifyRequest() when clarifyRequest != null:
return clarifyRequest(_that.request);case RunClarifyResolved() when clarifyResolved != null:
return clarifyResolved();case RunStatusEvent() when status != null:
return status(_that.status);case RunCompleted() when completed != null:
return completed(_that.output);case RunFailed() when failed != null:
return failed(_that.error);case RunUnknown() when unknown != null:
return unknown(_that.type,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class RunActivityPreview implements RunEvent {
  const RunActivityPreview(this.text);
  

 final  String text;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunActivityPreviewCopyWith<RunActivityPreview> get copyWith => _$RunActivityPreviewCopyWithImpl<RunActivityPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunActivityPreview&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'RunEvent.activityPreview(text: $text)';
}


}

/// @nodoc
abstract mixin class $RunActivityPreviewCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunActivityPreviewCopyWith(RunActivityPreview value, $Res Function(RunActivityPreview) _then) = _$RunActivityPreviewCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$RunActivityPreviewCopyWithImpl<$Res>
    implements $RunActivityPreviewCopyWith<$Res> {
  _$RunActivityPreviewCopyWithImpl(this._self, this._then);

  final RunActivityPreview _self;
  final $Res Function(RunActivityPreview) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(RunActivityPreview(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RunReasoningDelta implements RunEvent {
  const RunReasoningDelta(this.text);
  

 final  String text;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunReasoningDeltaCopyWith<RunReasoningDelta> get copyWith => _$RunReasoningDeltaCopyWithImpl<RunReasoningDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunReasoningDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'RunEvent.reasoningDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class $RunReasoningDeltaCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunReasoningDeltaCopyWith(RunReasoningDelta value, $Res Function(RunReasoningDelta) _then) = _$RunReasoningDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$RunReasoningDeltaCopyWithImpl<$Res>
    implements $RunReasoningDeltaCopyWith<$Res> {
  _$RunReasoningDeltaCopyWithImpl(this._self, this._then);

  final RunReasoningDelta _self;
  final $Res Function(RunReasoningDelta) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(RunReasoningDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RunThinkingState implements RunEvent {
  const RunThinkingState(this.text);
  

 final  String text;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunThinkingStateCopyWith<RunThinkingState> get copyWith => _$RunThinkingStateCopyWithImpl<RunThinkingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunThinkingState&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'RunEvent.thinkingState(text: $text)';
}


}

/// @nodoc
abstract mixin class $RunThinkingStateCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunThinkingStateCopyWith(RunThinkingState value, $Res Function(RunThinkingState) _then) = _$RunThinkingStateCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$RunThinkingStateCopyWithImpl<$Res>
    implements $RunThinkingStateCopyWith<$Res> {
  _$RunThinkingStateCopyWithImpl(this._self, this._then);

  final RunThinkingState _self;
  final $Res Function(RunThinkingState) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(RunThinkingState(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RunTextDelta implements RunEvent {
  const RunTextDelta(this.text);
  

 final  String text;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunTextDeltaCopyWith<RunTextDelta> get copyWith => _$RunTextDeltaCopyWithImpl<RunTextDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunTextDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'RunEvent.delta(text: $text)';
}


}

/// @nodoc
abstract mixin class $RunTextDeltaCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunTextDeltaCopyWith(RunTextDelta value, $Res Function(RunTextDelta) _then) = _$RunTextDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$RunTextDeltaCopyWithImpl<$Res>
    implements $RunTextDeltaCopyWith<$Res> {
  _$RunTextDeltaCopyWithImpl(this._self, this._then);

  final RunTextDelta _self;
  final $Res Function(RunTextDelta) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(RunTextDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RunToolProgress implements RunEvent {
  const RunToolProgress(this.tool);
  

 final  ToolCall tool;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunToolProgressCopyWith<RunToolProgress> get copyWith => _$RunToolProgressCopyWithImpl<RunToolProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunToolProgress&&(identical(other.tool, tool) || other.tool == tool));
}


@override
int get hashCode => Object.hash(runtimeType,tool);

@override
String toString() {
  return 'RunEvent.toolProgress(tool: $tool)';
}


}

/// @nodoc
abstract mixin class $RunToolProgressCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunToolProgressCopyWith(RunToolProgress value, $Res Function(RunToolProgress) _then) = _$RunToolProgressCopyWithImpl;
@useResult
$Res call({
 ToolCall tool
});


$ToolCallCopyWith<$Res> get tool;

}
/// @nodoc
class _$RunToolProgressCopyWithImpl<$Res>
    implements $RunToolProgressCopyWith<$Res> {
  _$RunToolProgressCopyWithImpl(this._self, this._then);

  final RunToolProgress _self;
  final $Res Function(RunToolProgress) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tool = null,}) {
  return _then(RunToolProgress(
null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as ToolCall,
  ));
}

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallCopyWith<$Res> get tool {
  
  return $ToolCallCopyWith<$Res>(_self.tool, (value) {
    return _then(_self.copyWith(tool: value));
  });
}
}

/// @nodoc


class RunApprovalRequest implements RunEvent {
  const RunApprovalRequest(this.request);
  

 final  ApprovalRequest request;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunApprovalRequestCopyWith<RunApprovalRequest> get copyWith => _$RunApprovalRequestCopyWithImpl<RunApprovalRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunApprovalRequest&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'RunEvent.approvalRequest(request: $request)';
}


}

/// @nodoc
abstract mixin class $RunApprovalRequestCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunApprovalRequestCopyWith(RunApprovalRequest value, $Res Function(RunApprovalRequest) _then) = _$RunApprovalRequestCopyWithImpl;
@useResult
$Res call({
 ApprovalRequest request
});




}
/// @nodoc
class _$RunApprovalRequestCopyWithImpl<$Res>
    implements $RunApprovalRequestCopyWith<$Res> {
  _$RunApprovalRequestCopyWithImpl(this._self, this._then);

  final RunApprovalRequest _self;
  final $Res Function(RunApprovalRequest) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(RunApprovalRequest(
null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as ApprovalRequest,
  ));
}


}

/// @nodoc


class RunApprovalResolved implements RunEvent {
  const RunApprovalResolved(this.choice);
  

 final  ApprovalChoice choice;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunApprovalResolvedCopyWith<RunApprovalResolved> get copyWith => _$RunApprovalResolvedCopyWithImpl<RunApprovalResolved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunApprovalResolved&&(identical(other.choice, choice) || other.choice == choice));
}


@override
int get hashCode => Object.hash(runtimeType,choice);

@override
String toString() {
  return 'RunEvent.approvalResolved(choice: $choice)';
}


}

/// @nodoc
abstract mixin class $RunApprovalResolvedCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunApprovalResolvedCopyWith(RunApprovalResolved value, $Res Function(RunApprovalResolved) _then) = _$RunApprovalResolvedCopyWithImpl;
@useResult
$Res call({
 ApprovalChoice choice
});




}
/// @nodoc
class _$RunApprovalResolvedCopyWithImpl<$Res>
    implements $RunApprovalResolvedCopyWith<$Res> {
  _$RunApprovalResolvedCopyWithImpl(this._self, this._then);

  final RunApprovalResolved _self;
  final $Res Function(RunApprovalResolved) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? choice = null,}) {
  return _then(RunApprovalResolved(
null == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as ApprovalChoice,
  ));
}


}

/// @nodoc


class RunClarifyRequest implements RunEvent {
  const RunClarifyRequest(this.request);
  

 final  ClarifyRequest request;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunClarifyRequestCopyWith<RunClarifyRequest> get copyWith => _$RunClarifyRequestCopyWithImpl<RunClarifyRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunClarifyRequest&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'RunEvent.clarifyRequest(request: $request)';
}


}

/// @nodoc
abstract mixin class $RunClarifyRequestCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunClarifyRequestCopyWith(RunClarifyRequest value, $Res Function(RunClarifyRequest) _then) = _$RunClarifyRequestCopyWithImpl;
@useResult
$Res call({
 ClarifyRequest request
});




}
/// @nodoc
class _$RunClarifyRequestCopyWithImpl<$Res>
    implements $RunClarifyRequestCopyWith<$Res> {
  _$RunClarifyRequestCopyWithImpl(this._self, this._then);

  final RunClarifyRequest _self;
  final $Res Function(RunClarifyRequest) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(RunClarifyRequest(
null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as ClarifyRequest,
  ));
}


}

/// @nodoc


class RunClarifyResolved implements RunEvent {
  const RunClarifyResolved();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunClarifyResolved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RunEvent.clarifyResolved()';
}


}




/// @nodoc


class RunStatusEvent implements RunEvent {
  const RunStatusEvent(this.status);
  

 final  RunStatus status;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunStatusEventCopyWith<RunStatusEvent> get copyWith => _$RunStatusEventCopyWithImpl<RunStatusEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunStatusEvent&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'RunEvent.status(status: $status)';
}


}

/// @nodoc
abstract mixin class $RunStatusEventCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunStatusEventCopyWith(RunStatusEvent value, $Res Function(RunStatusEvent) _then) = _$RunStatusEventCopyWithImpl;
@useResult
$Res call({
 RunStatus status
});




}
/// @nodoc
class _$RunStatusEventCopyWithImpl<$Res>
    implements $RunStatusEventCopyWith<$Res> {
  _$RunStatusEventCopyWithImpl(this._self, this._then);

  final RunStatusEvent _self;
  final $Res Function(RunStatusEvent) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,}) {
  return _then(RunStatusEvent(
null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,
  ));
}


}

/// @nodoc


class RunCompleted implements RunEvent {
  const RunCompleted({this.output});
  

 final  String? output;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunCompletedCopyWith<RunCompleted> get copyWith => _$RunCompletedCopyWithImpl<RunCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunCompleted&&(identical(other.output, output) || other.output == output));
}


@override
int get hashCode => Object.hash(runtimeType,output);

@override
String toString() {
  return 'RunEvent.completed(output: $output)';
}


}

/// @nodoc
abstract mixin class $RunCompletedCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunCompletedCopyWith(RunCompleted value, $Res Function(RunCompleted) _then) = _$RunCompletedCopyWithImpl;
@useResult
$Res call({
 String? output
});




}
/// @nodoc
class _$RunCompletedCopyWithImpl<$Res>
    implements $RunCompletedCopyWith<$Res> {
  _$RunCompletedCopyWithImpl(this._self, this._then);

  final RunCompleted _self;
  final $Res Function(RunCompleted) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? output = freezed,}) {
  return _then(RunCompleted(
output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RunFailed implements RunEvent {
  const RunFailed({this.error});
  

 final  String? error;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunFailedCopyWith<RunFailed> get copyWith => _$RunFailedCopyWithImpl<RunFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunFailed&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'RunEvent.failed(error: $error)';
}


}

/// @nodoc
abstract mixin class $RunFailedCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunFailedCopyWith(RunFailed value, $Res Function(RunFailed) _then) = _$RunFailedCopyWithImpl;
@useResult
$Res call({
 String? error
});




}
/// @nodoc
class _$RunFailedCopyWithImpl<$Res>
    implements $RunFailedCopyWith<$Res> {
  _$RunFailedCopyWithImpl(this._self, this._then);

  final RunFailed _self;
  final $Res Function(RunFailed) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = freezed,}) {
  return _then(RunFailed(
error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RunUnknown implements RunEvent {
  const RunUnknown(this.type, final  Map<String, dynamic> data): _data = data;
  

 final  String type;
 final  Map<String, dynamic> _data;
 Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunUnknownCopyWith<RunUnknown> get copyWith => _$RunUnknownCopyWithImpl<RunUnknown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunUnknown&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'RunEvent.unknown(type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class $RunUnknownCopyWith<$Res> implements $RunEventCopyWith<$Res> {
  factory $RunUnknownCopyWith(RunUnknown value, $Res Function(RunUnknown) _then) = _$RunUnknownCopyWithImpl;
@useResult
$Res call({
 String type, Map<String, dynamic> data
});




}
/// @nodoc
class _$RunUnknownCopyWithImpl<$Res>
    implements $RunUnknownCopyWith<$Res> {
  _$RunUnknownCopyWithImpl(this._self, this._then);

  final RunUnknown _self;
  final $Res Function(RunUnknown) _then;

/// Create a copy of RunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? data = null,}) {
  return _then(RunUnknown(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on

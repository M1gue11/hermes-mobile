// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subagent_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubagentEvent {

 SubagentEventKind get kind; String get key; String get goal; int get taskIndex; int get taskCount; int get depth; String? get text; String? get toolName; String? get toolPreview; SubagentPhase? get phase; String? get summary; Duration? get duration;
/// Create a copy of SubagentEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubagentEventCopyWith<SubagentEvent> get copyWith => _$SubagentEventCopyWithImpl<SubagentEvent>(this as SubagentEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubagentEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.key, key) || other.key == key)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.taskIndex, taskIndex) || other.taskIndex == taskIndex)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.text, text) || other.text == text)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.toolPreview, toolPreview) || other.toolPreview == toolPreview)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,kind,key,goal,taskIndex,taskCount,depth,text,toolName,toolPreview,phase,summary,duration);

@override
String toString() {
  return 'SubagentEvent(kind: $kind, key: $key, goal: $goal, taskIndex: $taskIndex, taskCount: $taskCount, depth: $depth, text: $text, toolName: $toolName, toolPreview: $toolPreview, phase: $phase, summary: $summary, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $SubagentEventCopyWith<$Res>  {
  factory $SubagentEventCopyWith(SubagentEvent value, $Res Function(SubagentEvent) _then) = _$SubagentEventCopyWithImpl;
@useResult
$Res call({
 SubagentEventKind kind, String key, String goal, int taskIndex, int taskCount, int depth, String? text, String? toolName, String? toolPreview, SubagentPhase? phase, String? summary, Duration? duration
});




}
/// @nodoc
class _$SubagentEventCopyWithImpl<$Res>
    implements $SubagentEventCopyWith<$Res> {
  _$SubagentEventCopyWithImpl(this._self, this._then);

  final SubagentEvent _self;
  final $Res Function(SubagentEvent) _then;

/// Create a copy of SubagentEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? key = null,Object? goal = null,Object? taskIndex = null,Object? taskCount = null,Object? depth = null,Object? text = freezed,Object? toolName = freezed,Object? toolPreview = freezed,Object? phase = freezed,Object? summary = freezed,Object? duration = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SubagentEventKind,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,taskIndex: null == taskIndex ? _self.taskIndex : taskIndex // ignore: cast_nullable_to_non_nullable
as int,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,toolName: freezed == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String?,toolPreview: freezed == toolPreview ? _self.toolPreview : toolPreview // ignore: cast_nullable_to_non_nullable
as String?,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SubagentPhase?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubagentEvent].
extension SubagentEventPatterns on SubagentEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubagentEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubagentEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubagentEvent value)  $default,){
final _that = this;
switch (_that) {
case _SubagentEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubagentEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SubagentEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubagentEventKind kind,  String key,  String goal,  int taskIndex,  int taskCount,  int depth,  String? text,  String? toolName,  String? toolPreview,  SubagentPhase? phase,  String? summary,  Duration? duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubagentEvent() when $default != null:
return $default(_that.kind,_that.key,_that.goal,_that.taskIndex,_that.taskCount,_that.depth,_that.text,_that.toolName,_that.toolPreview,_that.phase,_that.summary,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubagentEventKind kind,  String key,  String goal,  int taskIndex,  int taskCount,  int depth,  String? text,  String? toolName,  String? toolPreview,  SubagentPhase? phase,  String? summary,  Duration? duration)  $default,) {final _that = this;
switch (_that) {
case _SubagentEvent():
return $default(_that.kind,_that.key,_that.goal,_that.taskIndex,_that.taskCount,_that.depth,_that.text,_that.toolName,_that.toolPreview,_that.phase,_that.summary,_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubagentEventKind kind,  String key,  String goal,  int taskIndex,  int taskCount,  int depth,  String? text,  String? toolName,  String? toolPreview,  SubagentPhase? phase,  String? summary,  Duration? duration)?  $default,) {final _that = this;
switch (_that) {
case _SubagentEvent() when $default != null:
return $default(_that.kind,_that.key,_that.goal,_that.taskIndex,_that.taskCount,_that.depth,_that.text,_that.toolName,_that.toolPreview,_that.phase,_that.summary,_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class _SubagentEvent extends SubagentEvent {
  const _SubagentEvent({required this.kind, required this.key, this.goal = '', this.taskIndex = 0, this.taskCount = 1, this.depth = 1, this.text, this.toolName, this.toolPreview, this.phase, this.summary, this.duration}): super._();


@override final  SubagentEventKind kind;
@override final  String key;
@override@JsonKey() final  String goal;
@override@JsonKey() final  int taskIndex;
@override@JsonKey() final  int taskCount;
@override@JsonKey() final  int depth;
@override final  String? text;
@override final  String? toolName;
@override final  String? toolPreview;
@override final  SubagentPhase? phase;
@override final  String? summary;
@override final  Duration? duration;

/// Create a copy of SubagentEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubagentEventCopyWith<_SubagentEvent> get copyWith => __$SubagentEventCopyWithImpl<_SubagentEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubagentEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.key, key) || other.key == key)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.taskIndex, taskIndex) || other.taskIndex == taskIndex)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.text, text) || other.text == text)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.toolPreview, toolPreview) || other.toolPreview == toolPreview)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,kind,key,goal,taskIndex,taskCount,depth,text,toolName,toolPreview,phase,summary,duration);

@override
String toString() {
  return 'SubagentEvent(kind: $kind, key: $key, goal: $goal, taskIndex: $taskIndex, taskCount: $taskCount, depth: $depth, text: $text, toolName: $toolName, toolPreview: $toolPreview, phase: $phase, summary: $summary, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$SubagentEventCopyWith<$Res> implements $SubagentEventCopyWith<$Res> {
  factory _$SubagentEventCopyWith(_SubagentEvent value, $Res Function(_SubagentEvent) _then) = __$SubagentEventCopyWithImpl;
@override @useResult
$Res call({
 SubagentEventKind kind, String key, String goal, int taskIndex, int taskCount, int depth, String? text, String? toolName, String? toolPreview, SubagentPhase? phase, String? summary, Duration? duration
});




}
/// @nodoc
class __$SubagentEventCopyWithImpl<$Res>
    implements _$SubagentEventCopyWith<$Res> {
  __$SubagentEventCopyWithImpl(this._self, this._then);

  final _SubagentEvent _self;
  final $Res Function(_SubagentEvent) _then;

/// Create a copy of SubagentEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? key = null,Object? goal = null,Object? taskIndex = null,Object? taskCount = null,Object? depth = null,Object? text = freezed,Object? toolName = freezed,Object? toolPreview = freezed,Object? phase = freezed,Object? summary = freezed,Object? duration = freezed,}) {
  return _then(_SubagentEvent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SubagentEventKind,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,taskIndex: null == taskIndex ? _self.taskIndex : taskIndex // ignore: cast_nullable_to_non_nullable
as int,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,toolName: freezed == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String?,toolPreview: freezed == toolPreview ? _self.toolPreview : toolPreview // ignore: cast_nullable_to_non_nullable
as String?,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SubagentPhase?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc
mixin _$SubagentRun {

 String get key; String get goal; int get taskIndex; int get taskCount; int get depth; SubagentPhase get phase; int get toolCalls;/// Último sinal de vida: ferramenta, progresso ou raciocínio.
 String? get lastNote;/// Resumo que o filho devolveu ao terminar.
 String? get summary; Duration? get duration;
/// Create a copy of SubagentRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubagentRunCopyWith<SubagentRun> get copyWith => _$SubagentRunCopyWithImpl<SubagentRun>(this as SubagentRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubagentRun&&(identical(other.key, key) || other.key == key)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.taskIndex, taskIndex) || other.taskIndex == taskIndex)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.toolCalls, toolCalls) || other.toolCalls == toolCalls)&&(identical(other.lastNote, lastNote) || other.lastNote == lastNote)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,key,goal,taskIndex,taskCount,depth,phase,toolCalls,lastNote,summary,duration);

@override
String toString() {
  return 'SubagentRun(key: $key, goal: $goal, taskIndex: $taskIndex, taskCount: $taskCount, depth: $depth, phase: $phase, toolCalls: $toolCalls, lastNote: $lastNote, summary: $summary, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $SubagentRunCopyWith<$Res>  {
  factory $SubagentRunCopyWith(SubagentRun value, $Res Function(SubagentRun) _then) = _$SubagentRunCopyWithImpl;
@useResult
$Res call({
 String key, String goal, int taskIndex, int taskCount, int depth, SubagentPhase phase, int toolCalls, String? lastNote, String? summary, Duration? duration
});




}
/// @nodoc
class _$SubagentRunCopyWithImpl<$Res>
    implements $SubagentRunCopyWith<$Res> {
  _$SubagentRunCopyWithImpl(this._self, this._then);

  final SubagentRun _self;
  final $Res Function(SubagentRun) _then;

/// Create a copy of SubagentRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? goal = null,Object? taskIndex = null,Object? taskCount = null,Object? depth = null,Object? phase = null,Object? toolCalls = null,Object? lastNote = freezed,Object? summary = freezed,Object? duration = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,taskIndex: null == taskIndex ? _self.taskIndex : taskIndex // ignore: cast_nullable_to_non_nullable
as int,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SubagentPhase,toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as int,lastNote: freezed == lastNote ? _self.lastNote : lastNote // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubagentRun].
extension SubagentRunPatterns on SubagentRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubagentRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubagentRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubagentRun value)  $default,){
final _that = this;
switch (_that) {
case _SubagentRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubagentRun value)?  $default,){
final _that = this;
switch (_that) {
case _SubagentRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String goal,  int taskIndex,  int taskCount,  int depth,  SubagentPhase phase,  int toolCalls,  String? lastNote,  String? summary,  Duration? duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubagentRun() when $default != null:
return $default(_that.key,_that.goal,_that.taskIndex,_that.taskCount,_that.depth,_that.phase,_that.toolCalls,_that.lastNote,_that.summary,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String goal,  int taskIndex,  int taskCount,  int depth,  SubagentPhase phase,  int toolCalls,  String? lastNote,  String? summary,  Duration? duration)  $default,) {final _that = this;
switch (_that) {
case _SubagentRun():
return $default(_that.key,_that.goal,_that.taskIndex,_that.taskCount,_that.depth,_that.phase,_that.toolCalls,_that.lastNote,_that.summary,_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String goal,  int taskIndex,  int taskCount,  int depth,  SubagentPhase phase,  int toolCalls,  String? lastNote,  String? summary,  Duration? duration)?  $default,) {final _that = this;
switch (_that) {
case _SubagentRun() when $default != null:
return $default(_that.key,_that.goal,_that.taskIndex,_that.taskCount,_that.depth,_that.phase,_that.toolCalls,_that.lastNote,_that.summary,_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class _SubagentRun extends SubagentRun {
  const _SubagentRun({required this.key, this.goal = '', this.taskIndex = 0, this.taskCount = 1, this.depth = 1, this.phase = SubagentPhase.queued, this.toolCalls = 0, this.lastNote, this.summary, this.duration}): super._();


@override final  String key;
@override@JsonKey() final  String goal;
@override@JsonKey() final  int taskIndex;
@override@JsonKey() final  int taskCount;
@override@JsonKey() final  int depth;
@override@JsonKey() final  SubagentPhase phase;
@override@JsonKey() final  int toolCalls;
/// Último sinal de vida: ferramenta, progresso ou raciocínio.
@override final  String? lastNote;
/// Resumo que o filho devolveu ao terminar.
@override final  String? summary;
@override final  Duration? duration;

/// Create a copy of SubagentRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubagentRunCopyWith<_SubagentRun> get copyWith => __$SubagentRunCopyWithImpl<_SubagentRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubagentRun&&(identical(other.key, key) || other.key == key)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.taskIndex, taskIndex) || other.taskIndex == taskIndex)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.toolCalls, toolCalls) || other.toolCalls == toolCalls)&&(identical(other.lastNote, lastNote) || other.lastNote == lastNote)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,key,goal,taskIndex,taskCount,depth,phase,toolCalls,lastNote,summary,duration);

@override
String toString() {
  return 'SubagentRun(key: $key, goal: $goal, taskIndex: $taskIndex, taskCount: $taskCount, depth: $depth, phase: $phase, toolCalls: $toolCalls, lastNote: $lastNote, summary: $summary, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$SubagentRunCopyWith<$Res> implements $SubagentRunCopyWith<$Res> {
  factory _$SubagentRunCopyWith(_SubagentRun value, $Res Function(_SubagentRun) _then) = __$SubagentRunCopyWithImpl;
@override @useResult
$Res call({
 String key, String goal, int taskIndex, int taskCount, int depth, SubagentPhase phase, int toolCalls, String? lastNote, String? summary, Duration? duration
});




}
/// @nodoc
class __$SubagentRunCopyWithImpl<$Res>
    implements _$SubagentRunCopyWith<$Res> {
  __$SubagentRunCopyWithImpl(this._self, this._then);

  final _SubagentRun _self;
  final $Res Function(_SubagentRun) _then;

/// Create a copy of SubagentRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? goal = null,Object? taskIndex = null,Object? taskCount = null,Object? depth = null,Object? phase = null,Object? toolCalls = null,Object? lastNote = freezed,Object? summary = freezed,Object? duration = freezed,}) {
  return _then(_SubagentRun(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,taskIndex: null == taskIndex ? _self.taskIndex : taskIndex // ignore: cast_nullable_to_non_nullable
as int,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SubagentPhase,toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as int,lastNote: freezed == lastNote ? _self.lastNote : lastNote // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on

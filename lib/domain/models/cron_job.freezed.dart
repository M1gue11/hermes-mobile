// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cron_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CronJob {

 String get id; String get name; String get prompt;/// Agenda como o servidor a descreve (`every 30m`, `0 9 * * *`).
 String get schedule; bool get enabled; String get state; String? get pausedReason; DateTime? get nextRunAt; DateTime? get lastRunAt;/// `ok`, `error`, `delivery_failed`, `cancelled` ou nulo antes da primeira.
 String? get lastStatus; String? get lastError;/// Há uma execução reivindicada ou rodando agora.
 bool get running; int? get repeatTimes; int get repeatCompleted;
/// Create a copy of CronJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CronJobCopyWith<CronJob> get copyWith => _$CronJobCopyWithImpl<CronJob>(this as CronJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CronJob&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.state, state) || other.state == state)&&(identical(other.pausedReason, pausedReason) || other.pausedReason == pausedReason)&&(identical(other.nextRunAt, nextRunAt) || other.nextRunAt == nextRunAt)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.running, running) || other.running == running)&&(identical(other.repeatTimes, repeatTimes) || other.repeatTimes == repeatTimes)&&(identical(other.repeatCompleted, repeatCompleted) || other.repeatCompleted == repeatCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,prompt,schedule,enabled,state,pausedReason,nextRunAt,lastRunAt,lastStatus,lastError,running,repeatTimes,repeatCompleted);

@override
String toString() {
  return 'CronJob(id: $id, name: $name, prompt: $prompt, schedule: $schedule, enabled: $enabled, state: $state, pausedReason: $pausedReason, nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, lastStatus: $lastStatus, lastError: $lastError, running: $running, repeatTimes: $repeatTimes, repeatCompleted: $repeatCompleted)';
}


}

/// @nodoc
abstract mixin class $CronJobCopyWith<$Res>  {
  factory $CronJobCopyWith(CronJob value, $Res Function(CronJob) _then) = _$CronJobCopyWithImpl;
@useResult
$Res call({
 String id, String name, String prompt, String schedule, bool enabled, String state, String? pausedReason, DateTime? nextRunAt, DateTime? lastRunAt, String? lastStatus, String? lastError, bool running, int? repeatTimes, int repeatCompleted
});




}
/// @nodoc
class _$CronJobCopyWithImpl<$Res>
    implements $CronJobCopyWith<$Res> {
  _$CronJobCopyWithImpl(this._self, this._then);

  final CronJob _self;
  final $Res Function(CronJob) _then;

/// Create a copy of CronJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? prompt = null,Object? schedule = null,Object? enabled = null,Object? state = null,Object? pausedReason = freezed,Object? nextRunAt = freezed,Object? lastRunAt = freezed,Object? lastStatus = freezed,Object? lastError = freezed,Object? running = null,Object? repeatTimes = freezed,Object? repeatCompleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pausedReason: freezed == pausedReason ? _self.pausedReason : pausedReason // ignore: cast_nullable_to_non_nullable
as String?,nextRunAt: freezed == nextRunAt ? _self.nextRunAt : nextRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,repeatTimes: freezed == repeatTimes ? _self.repeatTimes : repeatTimes // ignore: cast_nullable_to_non_nullable
as int?,repeatCompleted: null == repeatCompleted ? _self.repeatCompleted : repeatCompleted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CronJob].
extension CronJobPatterns on CronJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CronJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CronJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CronJob value)  $default,){
final _that = this;
switch (_that) {
case _CronJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CronJob value)?  $default,){
final _that = this;
switch (_that) {
case _CronJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String prompt,  String schedule,  bool enabled,  String state,  String? pausedReason,  DateTime? nextRunAt,  DateTime? lastRunAt,  String? lastStatus,  String? lastError,  bool running,  int? repeatTimes,  int repeatCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CronJob() when $default != null:
return $default(_that.id,_that.name,_that.prompt,_that.schedule,_that.enabled,_that.state,_that.pausedReason,_that.nextRunAt,_that.lastRunAt,_that.lastStatus,_that.lastError,_that.running,_that.repeatTimes,_that.repeatCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String prompt,  String schedule,  bool enabled,  String state,  String? pausedReason,  DateTime? nextRunAt,  DateTime? lastRunAt,  String? lastStatus,  String? lastError,  bool running,  int? repeatTimes,  int repeatCompleted)  $default,) {final _that = this;
switch (_that) {
case _CronJob():
return $default(_that.id,_that.name,_that.prompt,_that.schedule,_that.enabled,_that.state,_that.pausedReason,_that.nextRunAt,_that.lastRunAt,_that.lastStatus,_that.lastError,_that.running,_that.repeatTimes,_that.repeatCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String prompt,  String schedule,  bool enabled,  String state,  String? pausedReason,  DateTime? nextRunAt,  DateTime? lastRunAt,  String? lastStatus,  String? lastError,  bool running,  int? repeatTimes,  int repeatCompleted)?  $default,) {final _that = this;
switch (_that) {
case _CronJob() when $default != null:
return $default(_that.id,_that.name,_that.prompt,_that.schedule,_that.enabled,_that.state,_that.pausedReason,_that.nextRunAt,_that.lastRunAt,_that.lastStatus,_that.lastError,_that.running,_that.repeatTimes,_that.repeatCompleted);case _:
  return null;

}
}

}

/// @nodoc


class _CronJob extends CronJob {
  const _CronJob({required this.id, required this.name, this.prompt = '', this.schedule = '', this.enabled = true, this.state = 'scheduled', this.pausedReason, this.nextRunAt, this.lastRunAt, this.lastStatus, this.lastError, this.running = false, this.repeatTimes, this.repeatCompleted = 0}): super._();
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  String prompt;
/// Agenda como o servidor a descreve (`every 30m`, `0 9 * * *`).
@override@JsonKey() final  String schedule;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String state;
@override final  String? pausedReason;
@override final  DateTime? nextRunAt;
@override final  DateTime? lastRunAt;
/// `ok`, `error`, `delivery_failed`, `cancelled` ou nulo antes da primeira.
@override final  String? lastStatus;
@override final  String? lastError;
/// Há uma execução reivindicada ou rodando agora.
@override@JsonKey() final  bool running;
@override final  int? repeatTimes;
@override@JsonKey() final  int repeatCompleted;

/// Create a copy of CronJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CronJobCopyWith<_CronJob> get copyWith => __$CronJobCopyWithImpl<_CronJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CronJob&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.state, state) || other.state == state)&&(identical(other.pausedReason, pausedReason) || other.pausedReason == pausedReason)&&(identical(other.nextRunAt, nextRunAt) || other.nextRunAt == nextRunAt)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.running, running) || other.running == running)&&(identical(other.repeatTimes, repeatTimes) || other.repeatTimes == repeatTimes)&&(identical(other.repeatCompleted, repeatCompleted) || other.repeatCompleted == repeatCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,prompt,schedule,enabled,state,pausedReason,nextRunAt,lastRunAt,lastStatus,lastError,running,repeatTimes,repeatCompleted);

@override
String toString() {
  return 'CronJob(id: $id, name: $name, prompt: $prompt, schedule: $schedule, enabled: $enabled, state: $state, pausedReason: $pausedReason, nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, lastStatus: $lastStatus, lastError: $lastError, running: $running, repeatTimes: $repeatTimes, repeatCompleted: $repeatCompleted)';
}


}

/// @nodoc
abstract mixin class _$CronJobCopyWith<$Res> implements $CronJobCopyWith<$Res> {
  factory _$CronJobCopyWith(_CronJob value, $Res Function(_CronJob) _then) = __$CronJobCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String prompt, String schedule, bool enabled, String state, String? pausedReason, DateTime? nextRunAt, DateTime? lastRunAt, String? lastStatus, String? lastError, bool running, int? repeatTimes, int repeatCompleted
});




}
/// @nodoc
class __$CronJobCopyWithImpl<$Res>
    implements _$CronJobCopyWith<$Res> {
  __$CronJobCopyWithImpl(this._self, this._then);

  final _CronJob _self;
  final $Res Function(_CronJob) _then;

/// Create a copy of CronJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? prompt = null,Object? schedule = null,Object? enabled = null,Object? state = null,Object? pausedReason = freezed,Object? nextRunAt = freezed,Object? lastRunAt = freezed,Object? lastStatus = freezed,Object? lastError = freezed,Object? running = null,Object? repeatTimes = freezed,Object? repeatCompleted = null,}) {
  return _then(_CronJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pausedReason: freezed == pausedReason ? _self.pausedReason : pausedReason // ignore: cast_nullable_to_non_nullable
as String?,nextRunAt: freezed == nextRunAt ? _self.nextRunAt : nextRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,repeatTimes: freezed == repeatTimes ? _self.repeatTimes : repeatTimes // ignore: cast_nullable_to_non_nullable
as int?,repeatCompleted: null == repeatCompleted ? _self.repeatCompleted : repeatCompleted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

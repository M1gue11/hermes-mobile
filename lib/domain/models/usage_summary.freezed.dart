// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UsageDay {

 DateTime get day; int get inputTokens; int get outputTokens; double get estimatedCost; double get actualCost; int get sessions;
/// Create a copy of UsageDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageDayCopyWith<UsageDay> get copyWith => _$UsageDayCopyWithImpl<UsageDay>(this as UsageDay, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageDay&&(identical(other.day, day) || other.day == day)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}


@override
int get hashCode => Object.hash(runtimeType,day,inputTokens,outputTokens,estimatedCost,actualCost,sessions);

@override
String toString() {
  return 'UsageDay(day: $day, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCost: $estimatedCost, actualCost: $actualCost, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $UsageDayCopyWith<$Res>  {
  factory $UsageDayCopyWith(UsageDay value, $Res Function(UsageDay) _then) = _$UsageDayCopyWithImpl;
@useResult
$Res call({
 DateTime day, int inputTokens, int outputTokens, double estimatedCost, double actualCost, int sessions
});




}
/// @nodoc
class _$UsageDayCopyWithImpl<$Res>
    implements $UsageDayCopyWith<$Res> {
  _$UsageDayCopyWithImpl(this._self, this._then);

  final UsageDay _self;
  final $Res Function(UsageDay) _then;

/// Create a copy of UsageDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? inputTokens = null,Object? outputTokens = null,Object? estimatedCost = null,Object? actualCost = null,Object? sessions = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,estimatedCost: null == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double,actualCost: null == actualCost ? _self.actualCost : actualCost // ignore: cast_nullable_to_non_nullable
as double,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageDay].
extension UsageDayPatterns on UsageDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageDay value)  $default,){
final _that = this;
switch (_that) {
case _UsageDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageDay value)?  $default,){
final _that = this;
switch (_that) {
case _UsageDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  int inputTokens,  int outputTokens,  double estimatedCost,  double actualCost,  int sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageDay() when $default != null:
return $default(_that.day,_that.inputTokens,_that.outputTokens,_that.estimatedCost,_that.actualCost,_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  int inputTokens,  int outputTokens,  double estimatedCost,  double actualCost,  int sessions)  $default,) {final _that = this;
switch (_that) {
case _UsageDay():
return $default(_that.day,_that.inputTokens,_that.outputTokens,_that.estimatedCost,_that.actualCost,_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  int inputTokens,  int outputTokens,  double estimatedCost,  double actualCost,  int sessions)?  $default,) {final _that = this;
switch (_that) {
case _UsageDay() when $default != null:
return $default(_that.day,_that.inputTokens,_that.outputTokens,_that.estimatedCost,_that.actualCost,_that.sessions);case _:
  return null;

}
}

}

/// @nodoc


class _UsageDay extends UsageDay {
  const _UsageDay({required this.day, this.inputTokens = 0, this.outputTokens = 0, this.estimatedCost = 0, this.actualCost = 0, this.sessions = 0}): super._();
  

@override final  DateTime day;
@override@JsonKey() final  int inputTokens;
@override@JsonKey() final  int outputTokens;
@override@JsonKey() final  double estimatedCost;
@override@JsonKey() final  double actualCost;
@override@JsonKey() final  int sessions;

/// Create a copy of UsageDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageDayCopyWith<_UsageDay> get copyWith => __$UsageDayCopyWithImpl<_UsageDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageDay&&(identical(other.day, day) || other.day == day)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}


@override
int get hashCode => Object.hash(runtimeType,day,inputTokens,outputTokens,estimatedCost,actualCost,sessions);

@override
String toString() {
  return 'UsageDay(day: $day, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCost: $estimatedCost, actualCost: $actualCost, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$UsageDayCopyWith<$Res> implements $UsageDayCopyWith<$Res> {
  factory _$UsageDayCopyWith(_UsageDay value, $Res Function(_UsageDay) _then) = __$UsageDayCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, int inputTokens, int outputTokens, double estimatedCost, double actualCost, int sessions
});




}
/// @nodoc
class __$UsageDayCopyWithImpl<$Res>
    implements _$UsageDayCopyWith<$Res> {
  __$UsageDayCopyWithImpl(this._self, this._then);

  final _UsageDay _self;
  final $Res Function(_UsageDay) _then;

/// Create a copy of UsageDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? inputTokens = null,Object? outputTokens = null,Object? estimatedCost = null,Object? actualCost = null,Object? sessions = null,}) {
  return _then(_UsageDay(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,estimatedCost: null == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double,actualCost: null == actualCost ? _self.actualCost : actualCost // ignore: cast_nullable_to_non_nullable
as double,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ModelUsage {

 String get model; int get inputTokens; int get outputTokens; double get estimatedCost; int get sessions;
/// Create a copy of ModelUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelUsageCopyWith<ModelUsage> get copyWith => _$ModelUsageCopyWithImpl<ModelUsage>(this as ModelUsage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelUsage&&(identical(other.model, model) || other.model == model)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}


@override
int get hashCode => Object.hash(runtimeType,model,inputTokens,outputTokens,estimatedCost,sessions);

@override
String toString() {
  return 'ModelUsage(model: $model, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCost: $estimatedCost, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $ModelUsageCopyWith<$Res>  {
  factory $ModelUsageCopyWith(ModelUsage value, $Res Function(ModelUsage) _then) = _$ModelUsageCopyWithImpl;
@useResult
$Res call({
 String model, int inputTokens, int outputTokens, double estimatedCost, int sessions
});




}
/// @nodoc
class _$ModelUsageCopyWithImpl<$Res>
    implements $ModelUsageCopyWith<$Res> {
  _$ModelUsageCopyWithImpl(this._self, this._then);

  final ModelUsage _self;
  final $Res Function(ModelUsage) _then;

/// Create a copy of ModelUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? model = null,Object? inputTokens = null,Object? outputTokens = null,Object? estimatedCost = null,Object? sessions = null,}) {
  return _then(_self.copyWith(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,estimatedCost: null == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelUsage].
extension ModelUsagePatterns on ModelUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelUsage value)  $default,){
final _that = this;
switch (_that) {
case _ModelUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelUsage value)?  $default,){
final _that = this;
switch (_that) {
case _ModelUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String model,  int inputTokens,  int outputTokens,  double estimatedCost,  int sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelUsage() when $default != null:
return $default(_that.model,_that.inputTokens,_that.outputTokens,_that.estimatedCost,_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String model,  int inputTokens,  int outputTokens,  double estimatedCost,  int sessions)  $default,) {final _that = this;
switch (_that) {
case _ModelUsage():
return $default(_that.model,_that.inputTokens,_that.outputTokens,_that.estimatedCost,_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String model,  int inputTokens,  int outputTokens,  double estimatedCost,  int sessions)?  $default,) {final _that = this;
switch (_that) {
case _ModelUsage() when $default != null:
return $default(_that.model,_that.inputTokens,_that.outputTokens,_that.estimatedCost,_that.sessions);case _:
  return null;

}
}

}

/// @nodoc


class _ModelUsage extends ModelUsage {
  const _ModelUsage({required this.model, this.inputTokens = 0, this.outputTokens = 0, this.estimatedCost = 0, this.sessions = 0}): super._();
  

@override final  String model;
@override@JsonKey() final  int inputTokens;
@override@JsonKey() final  int outputTokens;
@override@JsonKey() final  double estimatedCost;
@override@JsonKey() final  int sessions;

/// Create a copy of ModelUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelUsageCopyWith<_ModelUsage> get copyWith => __$ModelUsageCopyWithImpl<_ModelUsage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelUsage&&(identical(other.model, model) || other.model == model)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}


@override
int get hashCode => Object.hash(runtimeType,model,inputTokens,outputTokens,estimatedCost,sessions);

@override
String toString() {
  return 'ModelUsage(model: $model, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCost: $estimatedCost, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$ModelUsageCopyWith<$Res> implements $ModelUsageCopyWith<$Res> {
  factory _$ModelUsageCopyWith(_ModelUsage value, $Res Function(_ModelUsage) _then) = __$ModelUsageCopyWithImpl;
@override @useResult
$Res call({
 String model, int inputTokens, int outputTokens, double estimatedCost, int sessions
});




}
/// @nodoc
class __$ModelUsageCopyWithImpl<$Res>
    implements _$ModelUsageCopyWith<$Res> {
  __$ModelUsageCopyWithImpl(this._self, this._then);

  final _ModelUsage _self;
  final $Res Function(_ModelUsage) _then;

/// Create a copy of ModelUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? model = null,Object? inputTokens = null,Object? outputTokens = null,Object? estimatedCost = null,Object? sessions = null,}) {
  return _then(_ModelUsage(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,estimatedCost: null == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$UsageSummary {

 int get periodDays; int get inputTokens; int get outputTokens; int get cacheReadTokens; int get reasoningTokens; double get estimatedCost; double get actualCost; int get sessions; int get apiCalls;/// Só os dias que tiveram sessão, em ordem.
 List<UsageDay> get daily; List<ModelUsage> get byModel;
/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageSummaryCopyWith<UsageSummary> get copyWith => _$UsageSummaryCopyWithImpl<UsageSummary>(this as UsageSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageSummary&&(identical(other.periodDays, periodDays) || other.periodDays == periodDays)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens)&&(identical(other.reasoningTokens, reasoningTokens) || other.reasoningTokens == reasoningTokens)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.apiCalls, apiCalls) || other.apiCalls == apiCalls)&&const DeepCollectionEquality().equals(other.daily, daily)&&const DeepCollectionEquality().equals(other.byModel, byModel));
}


@override
int get hashCode => Object.hash(runtimeType,periodDays,inputTokens,outputTokens,cacheReadTokens,reasoningTokens,estimatedCost,actualCost,sessions,apiCalls,const DeepCollectionEquality().hash(daily),const DeepCollectionEquality().hash(byModel));

@override
String toString() {
  return 'UsageSummary(periodDays: $periodDays, inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens, reasoningTokens: $reasoningTokens, estimatedCost: $estimatedCost, actualCost: $actualCost, sessions: $sessions, apiCalls: $apiCalls, daily: $daily, byModel: $byModel)';
}


}

/// @nodoc
abstract mixin class $UsageSummaryCopyWith<$Res>  {
  factory $UsageSummaryCopyWith(UsageSummary value, $Res Function(UsageSummary) _then) = _$UsageSummaryCopyWithImpl;
@useResult
$Res call({
 int periodDays, int inputTokens, int outputTokens, int cacheReadTokens, int reasoningTokens, double estimatedCost, double actualCost, int sessions, int apiCalls, List<UsageDay> daily, List<ModelUsage> byModel
});




}
/// @nodoc
class _$UsageSummaryCopyWithImpl<$Res>
    implements $UsageSummaryCopyWith<$Res> {
  _$UsageSummaryCopyWithImpl(this._self, this._then);

  final UsageSummary _self;
  final $Res Function(UsageSummary) _then;

/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? periodDays = null,Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,Object? reasoningTokens = null,Object? estimatedCost = null,Object? actualCost = null,Object? sessions = null,Object? apiCalls = null,Object? daily = null,Object? byModel = null,}) {
  return _then(_self.copyWith(
periodDays: null == periodDays ? _self.periodDays : periodDays // ignore: cast_nullable_to_non_nullable
as int,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,reasoningTokens: null == reasoningTokens ? _self.reasoningTokens : reasoningTokens // ignore: cast_nullable_to_non_nullable
as int,estimatedCost: null == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double,actualCost: null == actualCost ? _self.actualCost : actualCost // ignore: cast_nullable_to_non_nullable
as double,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,apiCalls: null == apiCalls ? _self.apiCalls : apiCalls // ignore: cast_nullable_to_non_nullable
as int,daily: null == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as List<UsageDay>,byModel: null == byModel ? _self.byModel : byModel // ignore: cast_nullable_to_non_nullable
as List<ModelUsage>,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageSummary].
extension UsageSummaryPatterns on UsageSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageSummary value)  $default,){
final _that = this;
switch (_that) {
case _UsageSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageSummary value)?  $default,){
final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int periodDays,  int inputTokens,  int outputTokens,  int cacheReadTokens,  int reasoningTokens,  double estimatedCost,  double actualCost,  int sessions,  int apiCalls,  List<UsageDay> daily,  List<ModelUsage> byModel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
return $default(_that.periodDays,_that.inputTokens,_that.outputTokens,_that.cacheReadTokens,_that.reasoningTokens,_that.estimatedCost,_that.actualCost,_that.sessions,_that.apiCalls,_that.daily,_that.byModel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int periodDays,  int inputTokens,  int outputTokens,  int cacheReadTokens,  int reasoningTokens,  double estimatedCost,  double actualCost,  int sessions,  int apiCalls,  List<UsageDay> daily,  List<ModelUsage> byModel)  $default,) {final _that = this;
switch (_that) {
case _UsageSummary():
return $default(_that.periodDays,_that.inputTokens,_that.outputTokens,_that.cacheReadTokens,_that.reasoningTokens,_that.estimatedCost,_that.actualCost,_that.sessions,_that.apiCalls,_that.daily,_that.byModel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int periodDays,  int inputTokens,  int outputTokens,  int cacheReadTokens,  int reasoningTokens,  double estimatedCost,  double actualCost,  int sessions,  int apiCalls,  List<UsageDay> daily,  List<ModelUsage> byModel)?  $default,) {final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
return $default(_that.periodDays,_that.inputTokens,_that.outputTokens,_that.cacheReadTokens,_that.reasoningTokens,_that.estimatedCost,_that.actualCost,_that.sessions,_that.apiCalls,_that.daily,_that.byModel);case _:
  return null;

}
}

}

/// @nodoc


class _UsageSummary extends UsageSummary {
  const _UsageSummary({required this.periodDays, this.inputTokens = 0, this.outputTokens = 0, this.cacheReadTokens = 0, this.reasoningTokens = 0, this.estimatedCost = 0, this.actualCost = 0, this.sessions = 0, this.apiCalls = 0, final  List<UsageDay> daily = const <UsageDay>[], final  List<ModelUsage> byModel = const <ModelUsage>[]}): _daily = daily,_byModel = byModel,super._();
  

@override final  int periodDays;
@override@JsonKey() final  int inputTokens;
@override@JsonKey() final  int outputTokens;
@override@JsonKey() final  int cacheReadTokens;
@override@JsonKey() final  int reasoningTokens;
@override@JsonKey() final  double estimatedCost;
@override@JsonKey() final  double actualCost;
@override@JsonKey() final  int sessions;
@override@JsonKey() final  int apiCalls;
/// Só os dias que tiveram sessão, em ordem.
 final  List<UsageDay> _daily;
/// Só os dias que tiveram sessão, em ordem.
@override@JsonKey() List<UsageDay> get daily {
  if (_daily is EqualUnmodifiableListView) return _daily;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daily);
}

 final  List<ModelUsage> _byModel;
@override@JsonKey() List<ModelUsage> get byModel {
  if (_byModel is EqualUnmodifiableListView) return _byModel;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byModel);
}


/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageSummaryCopyWith<_UsageSummary> get copyWith => __$UsageSummaryCopyWithImpl<_UsageSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageSummary&&(identical(other.periodDays, periodDays) || other.periodDays == periodDays)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens)&&(identical(other.reasoningTokens, reasoningTokens) || other.reasoningTokens == reasoningTokens)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.apiCalls, apiCalls) || other.apiCalls == apiCalls)&&const DeepCollectionEquality().equals(other._daily, _daily)&&const DeepCollectionEquality().equals(other._byModel, _byModel));
}


@override
int get hashCode => Object.hash(runtimeType,periodDays,inputTokens,outputTokens,cacheReadTokens,reasoningTokens,estimatedCost,actualCost,sessions,apiCalls,const DeepCollectionEquality().hash(_daily),const DeepCollectionEquality().hash(_byModel));

@override
String toString() {
  return 'UsageSummary(periodDays: $periodDays, inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens, reasoningTokens: $reasoningTokens, estimatedCost: $estimatedCost, actualCost: $actualCost, sessions: $sessions, apiCalls: $apiCalls, daily: $daily, byModel: $byModel)';
}


}

/// @nodoc
abstract mixin class _$UsageSummaryCopyWith<$Res> implements $UsageSummaryCopyWith<$Res> {
  factory _$UsageSummaryCopyWith(_UsageSummary value, $Res Function(_UsageSummary) _then) = __$UsageSummaryCopyWithImpl;
@override @useResult
$Res call({
 int periodDays, int inputTokens, int outputTokens, int cacheReadTokens, int reasoningTokens, double estimatedCost, double actualCost, int sessions, int apiCalls, List<UsageDay> daily, List<ModelUsage> byModel
});




}
/// @nodoc
class __$UsageSummaryCopyWithImpl<$Res>
    implements _$UsageSummaryCopyWith<$Res> {
  __$UsageSummaryCopyWithImpl(this._self, this._then);

  final _UsageSummary _self;
  final $Res Function(_UsageSummary) _then;

/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? periodDays = null,Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,Object? reasoningTokens = null,Object? estimatedCost = null,Object? actualCost = null,Object? sessions = null,Object? apiCalls = null,Object? daily = null,Object? byModel = null,}) {
  return _then(_UsageSummary(
periodDays: null == periodDays ? _self.periodDays : periodDays // ignore: cast_nullable_to_non_nullable
as int,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,reasoningTokens: null == reasoningTokens ? _self.reasoningTokens : reasoningTokens // ignore: cast_nullable_to_non_nullable
as int,estimatedCost: null == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double,actualCost: null == actualCost ? _self.actualCost : actualCost // ignore: cast_nullable_to_non_nullable
as double,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,apiCalls: null == apiCalls ? _self.apiCalls : apiCalls // ignore: cast_nullable_to_non_nullable
as int,daily: null == daily ? _self._daily : daily // ignore: cast_nullable_to_non_nullable
as List<UsageDay>,byModel: null == byModel ? _self._byModel : byModel // ignore: cast_nullable_to_non_nullable
as List<ModelUsage>,
  ));
}


}

// dart format on

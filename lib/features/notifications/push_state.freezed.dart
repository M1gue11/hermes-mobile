// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PushSetupState {

 PushPhase get phase;/// A pessoa ligou as notificações, mesmo que falte distribuidor ou plugin.
 bool get enabled; List<String> get distributors; String? get distributor;/// Host do endpoint, para a pessoa reconhecer o servidor ntfy.
 String? get endpointHost;/// O servidor já tem o endpoint atual deste aparelho.
 bool get synced;/// `null` enquanto não foi possível perguntar ao Dashboard.
 bool? get pluginAvailable; bool get serverEncryption; bool get permissionDenied; String? get error; bool get busy; PushTestResult? get lastTest;
/// Create a copy of PushSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushSetupStateCopyWith<PushSetupState> get copyWith => _$PushSetupStateCopyWithImpl<PushSetupState>(this as PushSetupState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushSetupState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.distributors, distributors)&&(identical(other.distributor, distributor) || other.distributor == distributor)&&(identical(other.endpointHost, endpointHost) || other.endpointHost == endpointHost)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.pluginAvailable, pluginAvailable) || other.pluginAvailable == pluginAvailable)&&(identical(other.serverEncryption, serverEncryption) || other.serverEncryption == serverEncryption)&&(identical(other.permissionDenied, permissionDenied) || other.permissionDenied == permissionDenied)&&(identical(other.error, error) || other.error == error)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.lastTest, lastTest) || other.lastTest == lastTest));
}


@override
int get hashCode => Object.hash(runtimeType,phase,enabled,const DeepCollectionEquality().hash(distributors),distributor,endpointHost,synced,pluginAvailable,serverEncryption,permissionDenied,error,busy,lastTest);

@override
String toString() {
  return 'PushSetupState(phase: $phase, enabled: $enabled, distributors: $distributors, distributor: $distributor, endpointHost: $endpointHost, synced: $synced, pluginAvailable: $pluginAvailable, serverEncryption: $serverEncryption, permissionDenied: $permissionDenied, error: $error, busy: $busy, lastTest: $lastTest)';
}


}

/// @nodoc
abstract mixin class $PushSetupStateCopyWith<$Res>  {
  factory $PushSetupStateCopyWith(PushSetupState value, $Res Function(PushSetupState) _then) = _$PushSetupStateCopyWithImpl;
@useResult
$Res call({
 PushPhase phase, bool enabled, List<String> distributors, String? distributor, String? endpointHost, bool synced, bool? pluginAvailable, bool serverEncryption, bool permissionDenied, String? error, bool busy, PushTestResult? lastTest
});




}
/// @nodoc
class _$PushSetupStateCopyWithImpl<$Res>
    implements $PushSetupStateCopyWith<$Res> {
  _$PushSetupStateCopyWithImpl(this._self, this._then);

  final PushSetupState _self;
  final $Res Function(PushSetupState) _then;

/// Create a copy of PushSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? enabled = null,Object? distributors = null,Object? distributor = freezed,Object? endpointHost = freezed,Object? synced = null,Object? pluginAvailable = freezed,Object? serverEncryption = null,Object? permissionDenied = null,Object? error = freezed,Object? busy = null,Object? lastTest = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PushPhase,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,distributors: null == distributors ? _self.distributors : distributors // ignore: cast_nullable_to_non_nullable
as List<String>,distributor: freezed == distributor ? _self.distributor : distributor // ignore: cast_nullable_to_non_nullable
as String?,endpointHost: freezed == endpointHost ? _self.endpointHost : endpointHost // ignore: cast_nullable_to_non_nullable
as String?,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,pluginAvailable: freezed == pluginAvailable ? _self.pluginAvailable : pluginAvailable // ignore: cast_nullable_to_non_nullable
as bool?,serverEncryption: null == serverEncryption ? _self.serverEncryption : serverEncryption // ignore: cast_nullable_to_non_nullable
as bool,permissionDenied: null == permissionDenied ? _self.permissionDenied : permissionDenied // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,lastTest: freezed == lastTest ? _self.lastTest : lastTest // ignore: cast_nullable_to_non_nullable
as PushTestResult?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushSetupState].
extension PushSetupStatePatterns on PushSetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushSetupState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushSetupState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushSetupState value)  $default,){
final _that = this;
switch (_that) {
case _PushSetupState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushSetupState value)?  $default,){
final _that = this;
switch (_that) {
case _PushSetupState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PushPhase phase,  bool enabled,  List<String> distributors,  String? distributor,  String? endpointHost,  bool synced,  bool? pluginAvailable,  bool serverEncryption,  bool permissionDenied,  String? error,  bool busy,  PushTestResult? lastTest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushSetupState() when $default != null:
return $default(_that.phase,_that.enabled,_that.distributors,_that.distributor,_that.endpointHost,_that.synced,_that.pluginAvailable,_that.serverEncryption,_that.permissionDenied,_that.error,_that.busy,_that.lastTest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PushPhase phase,  bool enabled,  List<String> distributors,  String? distributor,  String? endpointHost,  bool synced,  bool? pluginAvailable,  bool serverEncryption,  bool permissionDenied,  String? error,  bool busy,  PushTestResult? lastTest)  $default,) {final _that = this;
switch (_that) {
case _PushSetupState():
return $default(_that.phase,_that.enabled,_that.distributors,_that.distributor,_that.endpointHost,_that.synced,_that.pluginAvailable,_that.serverEncryption,_that.permissionDenied,_that.error,_that.busy,_that.lastTest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PushPhase phase,  bool enabled,  List<String> distributors,  String? distributor,  String? endpointHost,  bool synced,  bool? pluginAvailable,  bool serverEncryption,  bool permissionDenied,  String? error,  bool busy,  PushTestResult? lastTest)?  $default,) {final _that = this;
switch (_that) {
case _PushSetupState() when $default != null:
return $default(_that.phase,_that.enabled,_that.distributors,_that.distributor,_that.endpointHost,_that.synced,_that.pluginAvailable,_that.serverEncryption,_that.permissionDenied,_that.error,_that.busy,_that.lastTest);case _:
  return null;

}
}

}

/// @nodoc


class _PushSetupState extends PushSetupState {
  const _PushSetupState({this.phase = PushPhase.loading, this.enabled = false, final  List<String> distributors = const <String>[], this.distributor, this.endpointHost, this.synced = false, this.pluginAvailable, this.serverEncryption = false, this.permissionDenied = false, this.error, this.busy = false, this.lastTest}): _distributors = distributors,super._();


@override@JsonKey() final  PushPhase phase;
/// A pessoa ligou as notificações, mesmo que falte distribuidor ou plugin.
@override@JsonKey() final  bool enabled;
 final  List<String> _distributors;
@override@JsonKey() List<String> get distributors {
  if (_distributors is EqualUnmodifiableListView) return _distributors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_distributors);
}

@override final  String? distributor;
/// Host do endpoint, para a pessoa reconhecer o servidor ntfy.
@override final  String? endpointHost;
/// O servidor já tem o endpoint atual deste aparelho.
@override@JsonKey() final  bool synced;
/// `null` enquanto não foi possível perguntar ao Dashboard.
@override final  bool? pluginAvailable;
@override@JsonKey() final  bool serverEncryption;
@override@JsonKey() final  bool permissionDenied;
@override final  String? error;
@override@JsonKey() final  bool busy;
@override final  PushTestResult? lastTest;

/// Create a copy of PushSetupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushSetupStateCopyWith<_PushSetupState> get copyWith => __$PushSetupStateCopyWithImpl<_PushSetupState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushSetupState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._distributors, _distributors)&&(identical(other.distributor, distributor) || other.distributor == distributor)&&(identical(other.endpointHost, endpointHost) || other.endpointHost == endpointHost)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.pluginAvailable, pluginAvailable) || other.pluginAvailable == pluginAvailable)&&(identical(other.serverEncryption, serverEncryption) || other.serverEncryption == serverEncryption)&&(identical(other.permissionDenied, permissionDenied) || other.permissionDenied == permissionDenied)&&(identical(other.error, error) || other.error == error)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.lastTest, lastTest) || other.lastTest == lastTest));
}


@override
int get hashCode => Object.hash(runtimeType,phase,enabled,const DeepCollectionEquality().hash(_distributors),distributor,endpointHost,synced,pluginAvailable,serverEncryption,permissionDenied,error,busy,lastTest);

@override
String toString() {
  return 'PushSetupState(phase: $phase, enabled: $enabled, distributors: $distributors, distributor: $distributor, endpointHost: $endpointHost, synced: $synced, pluginAvailable: $pluginAvailable, serverEncryption: $serverEncryption, permissionDenied: $permissionDenied, error: $error, busy: $busy, lastTest: $lastTest)';
}


}

/// @nodoc
abstract mixin class _$PushSetupStateCopyWith<$Res> implements $PushSetupStateCopyWith<$Res> {
  factory _$PushSetupStateCopyWith(_PushSetupState value, $Res Function(_PushSetupState) _then) = __$PushSetupStateCopyWithImpl;
@override @useResult
$Res call({
 PushPhase phase, bool enabled, List<String> distributors, String? distributor, String? endpointHost, bool synced, bool? pluginAvailable, bool serverEncryption, bool permissionDenied, String? error, bool busy, PushTestResult? lastTest
});




}
/// @nodoc
class __$PushSetupStateCopyWithImpl<$Res>
    implements _$PushSetupStateCopyWith<$Res> {
  __$PushSetupStateCopyWithImpl(this._self, this._then);

  final _PushSetupState _self;
  final $Res Function(_PushSetupState) _then;

/// Create a copy of PushSetupState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? enabled = null,Object? distributors = null,Object? distributor = freezed,Object? endpointHost = freezed,Object? synced = null,Object? pluginAvailable = freezed,Object? serverEncryption = null,Object? permissionDenied = null,Object? error = freezed,Object? busy = null,Object? lastTest = freezed,}) {
  return _then(_PushSetupState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PushPhase,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,distributors: null == distributors ? _self._distributors : distributors // ignore: cast_nullable_to_non_nullable
as List<String>,distributor: freezed == distributor ? _self.distributor : distributor // ignore: cast_nullable_to_non_nullable
as String?,endpointHost: freezed == endpointHost ? _self.endpointHost : endpointHost // ignore: cast_nullable_to_non_nullable
as String?,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,pluginAvailable: freezed == pluginAvailable ? _self.pluginAvailable : pluginAvailable // ignore: cast_nullable_to_non_nullable
as bool?,serverEncryption: null == serverEncryption ? _self.serverEncryption : serverEncryption // ignore: cast_nullable_to_non_nullable
as bool,permissionDenied: null == permissionDenied ? _self.permissionDenied : permissionDenied // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,lastTest: freezed == lastTest ? _self.lastTest : lastTest // ignore: cast_nullable_to_non_nullable
as PushTestResult?,
  ));
}


}

// dart format on

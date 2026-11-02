// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_health.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GatewayRuntime {

 bool get running; String? get state; DateTime? get updatedAt; String? get exitReason; int get activeSessions; int get activeAgents;/// Há turno em andamento: reiniciar agora interrompe alguém.
 bool get busy;/// Versão do Dashboard que respondeu.
 String? get version; int? get platformsConnected; int? get platformsConfigured;
/// Create a copy of GatewayRuntime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GatewayRuntimeCopyWith<GatewayRuntime> get copyWith => _$GatewayRuntimeCopyWithImpl<GatewayRuntime>(this as GatewayRuntime, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GatewayRuntime&&(identical(other.running, running) || other.running == running)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.exitReason, exitReason) || other.exitReason == exitReason)&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&(identical(other.activeAgents, activeAgents) || other.activeAgents == activeAgents)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.version, version) || other.version == version)&&(identical(other.platformsConnected, platformsConnected) || other.platformsConnected == platformsConnected)&&(identical(other.platformsConfigured, platformsConfigured) || other.platformsConfigured == platformsConfigured));
}


@override
int get hashCode => Object.hash(runtimeType,running,state,updatedAt,exitReason,activeSessions,activeAgents,busy,version,platformsConnected,platformsConfigured);

@override
String toString() {
  return 'GatewayRuntime(running: $running, state: $state, updatedAt: $updatedAt, exitReason: $exitReason, activeSessions: $activeSessions, activeAgents: $activeAgents, busy: $busy, version: $version, platformsConnected: $platformsConnected, platformsConfigured: $platformsConfigured)';
}


}

/// @nodoc
abstract mixin class $GatewayRuntimeCopyWith<$Res>  {
  factory $GatewayRuntimeCopyWith(GatewayRuntime value, $Res Function(GatewayRuntime) _then) = _$GatewayRuntimeCopyWithImpl;
@useResult
$Res call({
 bool running, String? state, DateTime? updatedAt, String? exitReason, int activeSessions, int activeAgents, bool busy, String? version, int? platformsConnected, int? platformsConfigured
});




}
/// @nodoc
class _$GatewayRuntimeCopyWithImpl<$Res>
    implements $GatewayRuntimeCopyWith<$Res> {
  _$GatewayRuntimeCopyWithImpl(this._self, this._then);

  final GatewayRuntime _self;
  final $Res Function(GatewayRuntime) _then;

/// Create a copy of GatewayRuntime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? running = null,Object? state = freezed,Object? updatedAt = freezed,Object? exitReason = freezed,Object? activeSessions = null,Object? activeAgents = null,Object? busy = null,Object? version = freezed,Object? platformsConnected = freezed,Object? platformsConfigured = freezed,}) {
  return _then(_self.copyWith(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exitReason: freezed == exitReason ? _self.exitReason : exitReason // ignore: cast_nullable_to_non_nullable
as String?,activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,activeAgents: null == activeAgents ? _self.activeAgents : activeAgents // ignore: cast_nullable_to_non_nullable
as int,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,platformsConnected: freezed == platformsConnected ? _self.platformsConnected : platformsConnected // ignore: cast_nullable_to_non_nullable
as int?,platformsConfigured: freezed == platformsConfigured ? _self.platformsConfigured : platformsConfigured // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GatewayRuntime].
extension GatewayRuntimePatterns on GatewayRuntime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GatewayRuntime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GatewayRuntime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GatewayRuntime value)  $default,){
final _that = this;
switch (_that) {
case _GatewayRuntime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GatewayRuntime value)?  $default,){
final _that = this;
switch (_that) {
case _GatewayRuntime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool running,  String? state,  DateTime? updatedAt,  String? exitReason,  int activeSessions,  int activeAgents,  bool busy,  String? version,  int? platformsConnected,  int? platformsConfigured)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GatewayRuntime() when $default != null:
return $default(_that.running,_that.state,_that.updatedAt,_that.exitReason,_that.activeSessions,_that.activeAgents,_that.busy,_that.version,_that.platformsConnected,_that.platformsConfigured);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool running,  String? state,  DateTime? updatedAt,  String? exitReason,  int activeSessions,  int activeAgents,  bool busy,  String? version,  int? platformsConnected,  int? platformsConfigured)  $default,) {final _that = this;
switch (_that) {
case _GatewayRuntime():
return $default(_that.running,_that.state,_that.updatedAt,_that.exitReason,_that.activeSessions,_that.activeAgents,_that.busy,_that.version,_that.platformsConnected,_that.platformsConfigured);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool running,  String? state,  DateTime? updatedAt,  String? exitReason,  int activeSessions,  int activeAgents,  bool busy,  String? version,  int? platformsConnected,  int? platformsConfigured)?  $default,) {final _that = this;
switch (_that) {
case _GatewayRuntime() when $default != null:
return $default(_that.running,_that.state,_that.updatedAt,_that.exitReason,_that.activeSessions,_that.activeAgents,_that.busy,_that.version,_that.platformsConnected,_that.platformsConfigured);case _:
  return null;

}
}

}

/// @nodoc


class _GatewayRuntime extends GatewayRuntime {
  const _GatewayRuntime({this.running = false, this.state, this.updatedAt, this.exitReason, this.activeSessions = 0, this.activeAgents = 0, this.busy = false, this.version, this.platformsConnected, this.platformsConfigured}): super._();
  

@override@JsonKey() final  bool running;
@override final  String? state;
@override final  DateTime? updatedAt;
@override final  String? exitReason;
@override@JsonKey() final  int activeSessions;
@override@JsonKey() final  int activeAgents;
/// Há turno em andamento: reiniciar agora interrompe alguém.
@override@JsonKey() final  bool busy;
/// Versão do Dashboard que respondeu.
@override final  String? version;
@override final  int? platformsConnected;
@override final  int? platformsConfigured;

/// Create a copy of GatewayRuntime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GatewayRuntimeCopyWith<_GatewayRuntime> get copyWith => __$GatewayRuntimeCopyWithImpl<_GatewayRuntime>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GatewayRuntime&&(identical(other.running, running) || other.running == running)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.exitReason, exitReason) || other.exitReason == exitReason)&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&(identical(other.activeAgents, activeAgents) || other.activeAgents == activeAgents)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.version, version) || other.version == version)&&(identical(other.platformsConnected, platformsConnected) || other.platformsConnected == platformsConnected)&&(identical(other.platformsConfigured, platformsConfigured) || other.platformsConfigured == platformsConfigured));
}


@override
int get hashCode => Object.hash(runtimeType,running,state,updatedAt,exitReason,activeSessions,activeAgents,busy,version,platformsConnected,platformsConfigured);

@override
String toString() {
  return 'GatewayRuntime(running: $running, state: $state, updatedAt: $updatedAt, exitReason: $exitReason, activeSessions: $activeSessions, activeAgents: $activeAgents, busy: $busy, version: $version, platformsConnected: $platformsConnected, platformsConfigured: $platformsConfigured)';
}


}

/// @nodoc
abstract mixin class _$GatewayRuntimeCopyWith<$Res> implements $GatewayRuntimeCopyWith<$Res> {
  factory _$GatewayRuntimeCopyWith(_GatewayRuntime value, $Res Function(_GatewayRuntime) _then) = __$GatewayRuntimeCopyWithImpl;
@override @useResult
$Res call({
 bool running, String? state, DateTime? updatedAt, String? exitReason, int activeSessions, int activeAgents, bool busy, String? version, int? platformsConnected, int? platformsConfigured
});




}
/// @nodoc
class __$GatewayRuntimeCopyWithImpl<$Res>
    implements _$GatewayRuntimeCopyWith<$Res> {
  __$GatewayRuntimeCopyWithImpl(this._self, this._then);

  final _GatewayRuntime _self;
  final $Res Function(_GatewayRuntime) _then;

/// Create a copy of GatewayRuntime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? running = null,Object? state = freezed,Object? updatedAt = freezed,Object? exitReason = freezed,Object? activeSessions = null,Object? activeAgents = null,Object? busy = null,Object? version = freezed,Object? platformsConnected = freezed,Object? platformsConfigured = freezed,}) {
  return _then(_GatewayRuntime(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exitReason: freezed == exitReason ? _self.exitReason : exitReason // ignore: cast_nullable_to_non_nullable
as String?,activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,activeAgents: null == activeAgents ? _self.activeAgents : activeAgents // ignore: cast_nullable_to_non_nullable
as int,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,platformsConnected: freezed == platformsConnected ? _self.platformsConnected : platformsConnected // ignore: cast_nullable_to_non_nullable
as int?,platformsConfigured: freezed == platformsConfigured ? _self.platformsConfigured : platformsConfigured // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$HostStats {

 String? get hostname; String? get hermesVersion; double? get cpuPercent; double? get memoryPercent; int? get memoryUsedBytes; int? get memoryTotalBytes; double? get diskPercent; int? get diskUsedBytes; int? get diskTotalBytes;/// Tempo desde o boot da máquina, não do gateway.
 int? get uptimeSeconds;
/// Create a copy of HostStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostStatsCopyWith<HostStats> get copyWith => _$HostStatsCopyWithImpl<HostStats>(this as HostStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostStats&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.hermesVersion, hermesVersion) || other.hermesVersion == hermesVersion)&&(identical(other.cpuPercent, cpuPercent) || other.cpuPercent == cpuPercent)&&(identical(other.memoryPercent, memoryPercent) || other.memoryPercent == memoryPercent)&&(identical(other.memoryUsedBytes, memoryUsedBytes) || other.memoryUsedBytes == memoryUsedBytes)&&(identical(other.memoryTotalBytes, memoryTotalBytes) || other.memoryTotalBytes == memoryTotalBytes)&&(identical(other.diskPercent, diskPercent) || other.diskPercent == diskPercent)&&(identical(other.diskUsedBytes, diskUsedBytes) || other.diskUsedBytes == diskUsedBytes)&&(identical(other.diskTotalBytes, diskTotalBytes) || other.diskTotalBytes == diskTotalBytes)&&(identical(other.uptimeSeconds, uptimeSeconds) || other.uptimeSeconds == uptimeSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,hostname,hermesVersion,cpuPercent,memoryPercent,memoryUsedBytes,memoryTotalBytes,diskPercent,diskUsedBytes,diskTotalBytes,uptimeSeconds);

@override
String toString() {
  return 'HostStats(hostname: $hostname, hermesVersion: $hermesVersion, cpuPercent: $cpuPercent, memoryPercent: $memoryPercent, memoryUsedBytes: $memoryUsedBytes, memoryTotalBytes: $memoryTotalBytes, diskPercent: $diskPercent, diskUsedBytes: $diskUsedBytes, diskTotalBytes: $diskTotalBytes, uptimeSeconds: $uptimeSeconds)';
}


}

/// @nodoc
abstract mixin class $HostStatsCopyWith<$Res>  {
  factory $HostStatsCopyWith(HostStats value, $Res Function(HostStats) _then) = _$HostStatsCopyWithImpl;
@useResult
$Res call({
 String? hostname, String? hermesVersion, double? cpuPercent, double? memoryPercent, int? memoryUsedBytes, int? memoryTotalBytes, double? diskPercent, int? diskUsedBytes, int? diskTotalBytes, int? uptimeSeconds
});




}
/// @nodoc
class _$HostStatsCopyWithImpl<$Res>
    implements $HostStatsCopyWith<$Res> {
  _$HostStatsCopyWithImpl(this._self, this._then);

  final HostStats _self;
  final $Res Function(HostStats) _then;

/// Create a copy of HostStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hostname = freezed,Object? hermesVersion = freezed,Object? cpuPercent = freezed,Object? memoryPercent = freezed,Object? memoryUsedBytes = freezed,Object? memoryTotalBytes = freezed,Object? diskPercent = freezed,Object? diskUsedBytes = freezed,Object? diskTotalBytes = freezed,Object? uptimeSeconds = freezed,}) {
  return _then(_self.copyWith(
hostname: freezed == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String?,hermesVersion: freezed == hermesVersion ? _self.hermesVersion : hermesVersion // ignore: cast_nullable_to_non_nullable
as String?,cpuPercent: freezed == cpuPercent ? _self.cpuPercent : cpuPercent // ignore: cast_nullable_to_non_nullable
as double?,memoryPercent: freezed == memoryPercent ? _self.memoryPercent : memoryPercent // ignore: cast_nullable_to_non_nullable
as double?,memoryUsedBytes: freezed == memoryUsedBytes ? _self.memoryUsedBytes : memoryUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,memoryTotalBytes: freezed == memoryTotalBytes ? _self.memoryTotalBytes : memoryTotalBytes // ignore: cast_nullable_to_non_nullable
as int?,diskPercent: freezed == diskPercent ? _self.diskPercent : diskPercent // ignore: cast_nullable_to_non_nullable
as double?,diskUsedBytes: freezed == diskUsedBytes ? _self.diskUsedBytes : diskUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,diskTotalBytes: freezed == diskTotalBytes ? _self.diskTotalBytes : diskTotalBytes // ignore: cast_nullable_to_non_nullable
as int?,uptimeSeconds: freezed == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HostStats].
extension HostStatsPatterns on HostStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostStats value)  $default,){
final _that = this;
switch (_that) {
case _HostStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostStats value)?  $default,){
final _that = this;
switch (_that) {
case _HostStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? hostname,  String? hermesVersion,  double? cpuPercent,  double? memoryPercent,  int? memoryUsedBytes,  int? memoryTotalBytes,  double? diskPercent,  int? diskUsedBytes,  int? diskTotalBytes,  int? uptimeSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostStats() when $default != null:
return $default(_that.hostname,_that.hermesVersion,_that.cpuPercent,_that.memoryPercent,_that.memoryUsedBytes,_that.memoryTotalBytes,_that.diskPercent,_that.diskUsedBytes,_that.diskTotalBytes,_that.uptimeSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? hostname,  String? hermesVersion,  double? cpuPercent,  double? memoryPercent,  int? memoryUsedBytes,  int? memoryTotalBytes,  double? diskPercent,  int? diskUsedBytes,  int? diskTotalBytes,  int? uptimeSeconds)  $default,) {final _that = this;
switch (_that) {
case _HostStats():
return $default(_that.hostname,_that.hermesVersion,_that.cpuPercent,_that.memoryPercent,_that.memoryUsedBytes,_that.memoryTotalBytes,_that.diskPercent,_that.diskUsedBytes,_that.diskTotalBytes,_that.uptimeSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? hostname,  String? hermesVersion,  double? cpuPercent,  double? memoryPercent,  int? memoryUsedBytes,  int? memoryTotalBytes,  double? diskPercent,  int? diskUsedBytes,  int? diskTotalBytes,  int? uptimeSeconds)?  $default,) {final _that = this;
switch (_that) {
case _HostStats() when $default != null:
return $default(_that.hostname,_that.hermesVersion,_that.cpuPercent,_that.memoryPercent,_that.memoryUsedBytes,_that.memoryTotalBytes,_that.diskPercent,_that.diskUsedBytes,_that.diskTotalBytes,_that.uptimeSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _HostStats implements HostStats {
  const _HostStats({this.hostname, this.hermesVersion, this.cpuPercent, this.memoryPercent, this.memoryUsedBytes, this.memoryTotalBytes, this.diskPercent, this.diskUsedBytes, this.diskTotalBytes, this.uptimeSeconds});
  

@override final  String? hostname;
@override final  String? hermesVersion;
@override final  double? cpuPercent;
@override final  double? memoryPercent;
@override final  int? memoryUsedBytes;
@override final  int? memoryTotalBytes;
@override final  double? diskPercent;
@override final  int? diskUsedBytes;
@override final  int? diskTotalBytes;
/// Tempo desde o boot da máquina, não do gateway.
@override final  int? uptimeSeconds;

/// Create a copy of HostStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostStatsCopyWith<_HostStats> get copyWith => __$HostStatsCopyWithImpl<_HostStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostStats&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.hermesVersion, hermesVersion) || other.hermesVersion == hermesVersion)&&(identical(other.cpuPercent, cpuPercent) || other.cpuPercent == cpuPercent)&&(identical(other.memoryPercent, memoryPercent) || other.memoryPercent == memoryPercent)&&(identical(other.memoryUsedBytes, memoryUsedBytes) || other.memoryUsedBytes == memoryUsedBytes)&&(identical(other.memoryTotalBytes, memoryTotalBytes) || other.memoryTotalBytes == memoryTotalBytes)&&(identical(other.diskPercent, diskPercent) || other.diskPercent == diskPercent)&&(identical(other.diskUsedBytes, diskUsedBytes) || other.diskUsedBytes == diskUsedBytes)&&(identical(other.diskTotalBytes, diskTotalBytes) || other.diskTotalBytes == diskTotalBytes)&&(identical(other.uptimeSeconds, uptimeSeconds) || other.uptimeSeconds == uptimeSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,hostname,hermesVersion,cpuPercent,memoryPercent,memoryUsedBytes,memoryTotalBytes,diskPercent,diskUsedBytes,diskTotalBytes,uptimeSeconds);

@override
String toString() {
  return 'HostStats(hostname: $hostname, hermesVersion: $hermesVersion, cpuPercent: $cpuPercent, memoryPercent: $memoryPercent, memoryUsedBytes: $memoryUsedBytes, memoryTotalBytes: $memoryTotalBytes, diskPercent: $diskPercent, diskUsedBytes: $diskUsedBytes, diskTotalBytes: $diskTotalBytes, uptimeSeconds: $uptimeSeconds)';
}


}

/// @nodoc
abstract mixin class _$HostStatsCopyWith<$Res> implements $HostStatsCopyWith<$Res> {
  factory _$HostStatsCopyWith(_HostStats value, $Res Function(_HostStats) _then) = __$HostStatsCopyWithImpl;
@override @useResult
$Res call({
 String? hostname, String? hermesVersion, double? cpuPercent, double? memoryPercent, int? memoryUsedBytes, int? memoryTotalBytes, double? diskPercent, int? diskUsedBytes, int? diskTotalBytes, int? uptimeSeconds
});




}
/// @nodoc
class __$HostStatsCopyWithImpl<$Res>
    implements _$HostStatsCopyWith<$Res> {
  __$HostStatsCopyWithImpl(this._self, this._then);

  final _HostStats _self;
  final $Res Function(_HostStats) _then;

/// Create a copy of HostStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hostname = freezed,Object? hermesVersion = freezed,Object? cpuPercent = freezed,Object? memoryPercent = freezed,Object? memoryUsedBytes = freezed,Object? memoryTotalBytes = freezed,Object? diskPercent = freezed,Object? diskUsedBytes = freezed,Object? diskTotalBytes = freezed,Object? uptimeSeconds = freezed,}) {
  return _then(_HostStats(
hostname: freezed == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String?,hermesVersion: freezed == hermesVersion ? _self.hermesVersion : hermesVersion // ignore: cast_nullable_to_non_nullable
as String?,cpuPercent: freezed == cpuPercent ? _self.cpuPercent : cpuPercent // ignore: cast_nullable_to_non_nullable
as double?,memoryPercent: freezed == memoryPercent ? _self.memoryPercent : memoryPercent // ignore: cast_nullable_to_non_nullable
as double?,memoryUsedBytes: freezed == memoryUsedBytes ? _self.memoryUsedBytes : memoryUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,memoryTotalBytes: freezed == memoryTotalBytes ? _self.memoryTotalBytes : memoryTotalBytes // ignore: cast_nullable_to_non_nullable
as int?,diskPercent: freezed == diskPercent ? _self.diskPercent : diskPercent // ignore: cast_nullable_to_non_nullable
as double?,diskUsedBytes: freezed == diskUsedBytes ? _self.diskUsedBytes : diskUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,diskTotalBytes: freezed == diskTotalBytes ? _self.diskTotalBytes : diskTotalBytes // ignore: cast_nullable_to_non_nullable
as int?,uptimeSeconds: freezed == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$ReadinessCheck {

 String get name; String get status; String? get detail;
/// Create a copy of ReadinessCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadinessCheckCopyWith<ReadinessCheck> get copyWith => _$ReadinessCheckCopyWithImpl<ReadinessCheck>(this as ReadinessCheck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadinessCheck&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,name,status,detail);

@override
String toString() {
  return 'ReadinessCheck(name: $name, status: $status, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $ReadinessCheckCopyWith<$Res>  {
  factory $ReadinessCheckCopyWith(ReadinessCheck value, $Res Function(ReadinessCheck) _then) = _$ReadinessCheckCopyWithImpl;
@useResult
$Res call({
 String name, String status, String? detail
});




}
/// @nodoc
class _$ReadinessCheckCopyWithImpl<$Res>
    implements $ReadinessCheckCopyWith<$Res> {
  _$ReadinessCheckCopyWithImpl(this._self, this._then);

  final ReadinessCheck _self;
  final $Res Function(ReadinessCheck) _then;

/// Create a copy of ReadinessCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? status = null,Object? detail = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadinessCheck].
extension ReadinessCheckPatterns on ReadinessCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadinessCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadinessCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadinessCheck value)  $default,){
final _that = this;
switch (_that) {
case _ReadinessCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadinessCheck value)?  $default,){
final _that = this;
switch (_that) {
case _ReadinessCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String status,  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadinessCheck() when $default != null:
return $default(_that.name,_that.status,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String status,  String? detail)  $default,) {final _that = this;
switch (_that) {
case _ReadinessCheck():
return $default(_that.name,_that.status,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String status,  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _ReadinessCheck() when $default != null:
return $default(_that.name,_that.status,_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class _ReadinessCheck extends ReadinessCheck {
  const _ReadinessCheck({required this.name, required this.status, this.detail}): super._();
  

@override final  String name;
@override final  String status;
@override final  String? detail;

/// Create a copy of ReadinessCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadinessCheckCopyWith<_ReadinessCheck> get copyWith => __$ReadinessCheckCopyWithImpl<_ReadinessCheck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadinessCheck&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,name,status,detail);

@override
String toString() {
  return 'ReadinessCheck(name: $name, status: $status, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$ReadinessCheckCopyWith<$Res> implements $ReadinessCheckCopyWith<$Res> {
  factory _$ReadinessCheckCopyWith(_ReadinessCheck value, $Res Function(_ReadinessCheck) _then) = __$ReadinessCheckCopyWithImpl;
@override @useResult
$Res call({
 String name, String status, String? detail
});




}
/// @nodoc
class __$ReadinessCheckCopyWithImpl<$Res>
    implements _$ReadinessCheckCopyWith<$Res> {
  __$ReadinessCheckCopyWithImpl(this._self, this._then);

  final _ReadinessCheck _self;
  final $Res Function(_ReadinessCheck) _then;

/// Create a copy of ReadinessCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? status = null,Object? detail = freezed,}) {
  return _then(_ReadinessCheck(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ServerReadiness {

 String get status; List<ReadinessCheck> get checks; String? get version; int get activeRuns; int? get requestsToday; int? get tokensToday; int? get latencyP95Ms;
/// Create a copy of ServerReadiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerReadinessCopyWith<ServerReadiness> get copyWith => _$ServerReadinessCopyWithImpl<ServerReadiness>(this as ServerReadiness, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerReadiness&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.checks, checks)&&(identical(other.version, version) || other.version == version)&&(identical(other.activeRuns, activeRuns) || other.activeRuns == activeRuns)&&(identical(other.requestsToday, requestsToday) || other.requestsToday == requestsToday)&&(identical(other.tokensToday, tokensToday) || other.tokensToday == tokensToday)&&(identical(other.latencyP95Ms, latencyP95Ms) || other.latencyP95Ms == latencyP95Ms));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(checks),version,activeRuns,requestsToday,tokensToday,latencyP95Ms);

@override
String toString() {
  return 'ServerReadiness(status: $status, checks: $checks, version: $version, activeRuns: $activeRuns, requestsToday: $requestsToday, tokensToday: $tokensToday, latencyP95Ms: $latencyP95Ms)';
}


}

/// @nodoc
abstract mixin class $ServerReadinessCopyWith<$Res>  {
  factory $ServerReadinessCopyWith(ServerReadiness value, $Res Function(ServerReadiness) _then) = _$ServerReadinessCopyWithImpl;
@useResult
$Res call({
 String status, List<ReadinessCheck> checks, String? version, int activeRuns, int? requestsToday, int? tokensToday, int? latencyP95Ms
});




}
/// @nodoc
class _$ServerReadinessCopyWithImpl<$Res>
    implements $ServerReadinessCopyWith<$Res> {
  _$ServerReadinessCopyWithImpl(this._self, this._then);

  final ServerReadiness _self;
  final $Res Function(ServerReadiness) _then;

/// Create a copy of ServerReadiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? checks = null,Object? version = freezed,Object? activeRuns = null,Object? requestsToday = freezed,Object? tokensToday = freezed,Object? latencyP95Ms = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as List<ReadinessCheck>,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,activeRuns: null == activeRuns ? _self.activeRuns : activeRuns // ignore: cast_nullable_to_non_nullable
as int,requestsToday: freezed == requestsToday ? _self.requestsToday : requestsToday // ignore: cast_nullable_to_non_nullable
as int?,tokensToday: freezed == tokensToday ? _self.tokensToday : tokensToday // ignore: cast_nullable_to_non_nullable
as int?,latencyP95Ms: freezed == latencyP95Ms ? _self.latencyP95Ms : latencyP95Ms // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerReadiness].
extension ServerReadinessPatterns on ServerReadiness {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerReadiness value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerReadiness() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerReadiness value)  $default,){
final _that = this;
switch (_that) {
case _ServerReadiness():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerReadiness value)?  $default,){
final _that = this;
switch (_that) {
case _ServerReadiness() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  List<ReadinessCheck> checks,  String? version,  int activeRuns,  int? requestsToday,  int? tokensToday,  int? latencyP95Ms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerReadiness() when $default != null:
return $default(_that.status,_that.checks,_that.version,_that.activeRuns,_that.requestsToday,_that.tokensToday,_that.latencyP95Ms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  List<ReadinessCheck> checks,  String? version,  int activeRuns,  int? requestsToday,  int? tokensToday,  int? latencyP95Ms)  $default,) {final _that = this;
switch (_that) {
case _ServerReadiness():
return $default(_that.status,_that.checks,_that.version,_that.activeRuns,_that.requestsToday,_that.tokensToday,_that.latencyP95Ms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  List<ReadinessCheck> checks,  String? version,  int activeRuns,  int? requestsToday,  int? tokensToday,  int? latencyP95Ms)?  $default,) {final _that = this;
switch (_that) {
case _ServerReadiness() when $default != null:
return $default(_that.status,_that.checks,_that.version,_that.activeRuns,_that.requestsToday,_that.tokensToday,_that.latencyP95Ms);case _:
  return null;

}
}

}

/// @nodoc


class _ServerReadiness extends ServerReadiness {
  const _ServerReadiness({this.status = 'unknown', final  List<ReadinessCheck> checks = const <ReadinessCheck>[], this.version, this.activeRuns = 0, this.requestsToday, this.tokensToday, this.latencyP95Ms}): _checks = checks,super._();
  

@override@JsonKey() final  String status;
 final  List<ReadinessCheck> _checks;
@override@JsonKey() List<ReadinessCheck> get checks {
  if (_checks is EqualUnmodifiableListView) return _checks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checks);
}

@override final  String? version;
@override@JsonKey() final  int activeRuns;
@override final  int? requestsToday;
@override final  int? tokensToday;
@override final  int? latencyP95Ms;

/// Create a copy of ServerReadiness
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerReadinessCopyWith<_ServerReadiness> get copyWith => __$ServerReadinessCopyWithImpl<_ServerReadiness>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerReadiness&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._checks, _checks)&&(identical(other.version, version) || other.version == version)&&(identical(other.activeRuns, activeRuns) || other.activeRuns == activeRuns)&&(identical(other.requestsToday, requestsToday) || other.requestsToday == requestsToday)&&(identical(other.tokensToday, tokensToday) || other.tokensToday == tokensToday)&&(identical(other.latencyP95Ms, latencyP95Ms) || other.latencyP95Ms == latencyP95Ms));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_checks),version,activeRuns,requestsToday,tokensToday,latencyP95Ms);

@override
String toString() {
  return 'ServerReadiness(status: $status, checks: $checks, version: $version, activeRuns: $activeRuns, requestsToday: $requestsToday, tokensToday: $tokensToday, latencyP95Ms: $latencyP95Ms)';
}


}

/// @nodoc
abstract mixin class _$ServerReadinessCopyWith<$Res> implements $ServerReadinessCopyWith<$Res> {
  factory _$ServerReadinessCopyWith(_ServerReadiness value, $Res Function(_ServerReadiness) _then) = __$ServerReadinessCopyWithImpl;
@override @useResult
$Res call({
 String status, List<ReadinessCheck> checks, String? version, int activeRuns, int? requestsToday, int? tokensToday, int? latencyP95Ms
});




}
/// @nodoc
class __$ServerReadinessCopyWithImpl<$Res>
    implements _$ServerReadinessCopyWith<$Res> {
  __$ServerReadinessCopyWithImpl(this._self, this._then);

  final _ServerReadiness _self;
  final $Res Function(_ServerReadiness) _then;

/// Create a copy of ServerReadiness
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? checks = null,Object? version = freezed,Object? activeRuns = null,Object? requestsToday = freezed,Object? tokensToday = freezed,Object? latencyP95Ms = freezed,}) {
  return _then(_ServerReadiness(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checks: null == checks ? _self._checks : checks // ignore: cast_nullable_to_non_nullable
as List<ReadinessCheck>,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,activeRuns: null == activeRuns ? _self.activeRuns : activeRuns // ignore: cast_nullable_to_non_nullable
as int,requestsToday: freezed == requestsToday ? _self.requestsToday : requestsToday // ignore: cast_nullable_to_non_nullable
as int?,tokensToday: freezed == tokensToday ? _self.tokensToday : tokensToday // ignore: cast_nullable_to_non_nullable
as int?,latencyP95Ms: freezed == latencyP95Ms ? _self.latencyP95Ms : latencyP95Ms // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$GatewayActionStatus {

 bool get running; int? get exitCode; List<String> get lines;
/// Create a copy of GatewayActionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GatewayActionStatusCopyWith<GatewayActionStatus> get copyWith => _$GatewayActionStatusCopyWithImpl<GatewayActionStatus>(this as GatewayActionStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GatewayActionStatus&&(identical(other.running, running) || other.running == running)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&const DeepCollectionEquality().equals(other.lines, lines));
}


@override
int get hashCode => Object.hash(runtimeType,running,exitCode,const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'GatewayActionStatus(running: $running, exitCode: $exitCode, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $GatewayActionStatusCopyWith<$Res>  {
  factory $GatewayActionStatusCopyWith(GatewayActionStatus value, $Res Function(GatewayActionStatus) _then) = _$GatewayActionStatusCopyWithImpl;
@useResult
$Res call({
 bool running, int? exitCode, List<String> lines
});




}
/// @nodoc
class _$GatewayActionStatusCopyWithImpl<$Res>
    implements $GatewayActionStatusCopyWith<$Res> {
  _$GatewayActionStatusCopyWithImpl(this._self, this._then);

  final GatewayActionStatus _self;
  final $Res Function(GatewayActionStatus) _then;

/// Create a copy of GatewayActionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? running = null,Object? exitCode = freezed,Object? lines = null,}) {
  return _then(_self.copyWith(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [GatewayActionStatus].
extension GatewayActionStatusPatterns on GatewayActionStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GatewayActionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GatewayActionStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GatewayActionStatus value)  $default,){
final _that = this;
switch (_that) {
case _GatewayActionStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GatewayActionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _GatewayActionStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool running,  int? exitCode,  List<String> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GatewayActionStatus() when $default != null:
return $default(_that.running,_that.exitCode,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool running,  int? exitCode,  List<String> lines)  $default,) {final _that = this;
switch (_that) {
case _GatewayActionStatus():
return $default(_that.running,_that.exitCode,_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool running,  int? exitCode,  List<String> lines)?  $default,) {final _that = this;
switch (_that) {
case _GatewayActionStatus() when $default != null:
return $default(_that.running,_that.exitCode,_that.lines);case _:
  return null;

}
}

}

/// @nodoc


class _GatewayActionStatus implements GatewayActionStatus {
  const _GatewayActionStatus({this.running = false, this.exitCode, final  List<String> lines = const <String>[]}): _lines = lines;
  

@override@JsonKey() final  bool running;
@override final  int? exitCode;
 final  List<String> _lines;
@override@JsonKey() List<String> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of GatewayActionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GatewayActionStatusCopyWith<_GatewayActionStatus> get copyWith => __$GatewayActionStatusCopyWithImpl<_GatewayActionStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GatewayActionStatus&&(identical(other.running, running) || other.running == running)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&const DeepCollectionEquality().equals(other._lines, _lines));
}


@override
int get hashCode => Object.hash(runtimeType,running,exitCode,const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'GatewayActionStatus(running: $running, exitCode: $exitCode, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$GatewayActionStatusCopyWith<$Res> implements $GatewayActionStatusCopyWith<$Res> {
  factory _$GatewayActionStatusCopyWith(_GatewayActionStatus value, $Res Function(_GatewayActionStatus) _then) = __$GatewayActionStatusCopyWithImpl;
@override @useResult
$Res call({
 bool running, int? exitCode, List<String> lines
});




}
/// @nodoc
class __$GatewayActionStatusCopyWithImpl<$Res>
    implements _$GatewayActionStatusCopyWith<$Res> {
  __$GatewayActionStatusCopyWithImpl(this._self, this._then);

  final _GatewayActionStatus _self;
  final $Res Function(_GatewayActionStatus) _then;

/// Create a copy of GatewayActionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? running = null,Object? exitCode = freezed,Object? lines = null,}) {
  return _then(_GatewayActionStatus(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_tools.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToolsetSetting {

 String get name; String get label; String get description; bool get enabled;/// As credenciais que o toolset pede estão presentes.
 bool get configured; int get toolCount; String get platform;
/// Create a copy of ToolsetSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolsetSettingCopyWith<ToolsetSetting> get copyWith => _$ToolsetSettingCopyWithImpl<ToolsetSetting>(this as ToolsetSetting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolsetSetting&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.configured, configured) || other.configured == configured)&&(identical(other.toolCount, toolCount) || other.toolCount == toolCount)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,name,label,description,enabled,configured,toolCount,platform);

@override
String toString() {
  return 'ToolsetSetting(name: $name, label: $label, description: $description, enabled: $enabled, configured: $configured, toolCount: $toolCount, platform: $platform)';
}


}

/// @nodoc
abstract mixin class $ToolsetSettingCopyWith<$Res>  {
  factory $ToolsetSettingCopyWith(ToolsetSetting value, $Res Function(ToolsetSetting) _then) = _$ToolsetSettingCopyWithImpl;
@useResult
$Res call({
 String name, String label, String description, bool enabled, bool configured, int toolCount, String platform
});




}
/// @nodoc
class _$ToolsetSettingCopyWithImpl<$Res>
    implements $ToolsetSettingCopyWith<$Res> {
  _$ToolsetSettingCopyWithImpl(this._self, this._then);

  final ToolsetSetting _self;
  final $Res Function(ToolsetSetting) _then;

/// Create a copy of ToolsetSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? label = null,Object? description = null,Object? enabled = null,Object? configured = null,Object? toolCount = null,Object? platform = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,toolCount: null == toolCount ? _self.toolCount : toolCount // ignore: cast_nullable_to_non_nullable
as int,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolsetSetting].
extension ToolsetSettingPatterns on ToolsetSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolsetSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolsetSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolsetSetting value)  $default,){
final _that = this;
switch (_that) {
case _ToolsetSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolsetSetting value)?  $default,){
final _that = this;
switch (_that) {
case _ToolsetSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String label,  String description,  bool enabled,  bool configured,  int toolCount,  String platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolsetSetting() when $default != null:
return $default(_that.name,_that.label,_that.description,_that.enabled,_that.configured,_that.toolCount,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String label,  String description,  bool enabled,  bool configured,  int toolCount,  String platform)  $default,) {final _that = this;
switch (_that) {
case _ToolsetSetting():
return $default(_that.name,_that.label,_that.description,_that.enabled,_that.configured,_that.toolCount,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String label,  String description,  bool enabled,  bool configured,  int toolCount,  String platform)?  $default,) {final _that = this;
switch (_that) {
case _ToolsetSetting() when $default != null:
return $default(_that.name,_that.label,_that.description,_that.enabled,_that.configured,_that.toolCount,_that.platform);case _:
  return null;

}
}

}

/// @nodoc


class _ToolsetSetting implements ToolsetSetting {
  const _ToolsetSetting({required this.name, required this.label, this.description = '', this.enabled = false, this.configured = true, this.toolCount = 0, this.platform = 'cli'});
  

@override final  String name;
@override final  String label;
@override@JsonKey() final  String description;
@override@JsonKey() final  bool enabled;
/// As credenciais que o toolset pede estão presentes.
@override@JsonKey() final  bool configured;
@override@JsonKey() final  int toolCount;
@override@JsonKey() final  String platform;

/// Create a copy of ToolsetSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolsetSettingCopyWith<_ToolsetSetting> get copyWith => __$ToolsetSettingCopyWithImpl<_ToolsetSetting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolsetSetting&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.configured, configured) || other.configured == configured)&&(identical(other.toolCount, toolCount) || other.toolCount == toolCount)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,name,label,description,enabled,configured,toolCount,platform);

@override
String toString() {
  return 'ToolsetSetting(name: $name, label: $label, description: $description, enabled: $enabled, configured: $configured, toolCount: $toolCount, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$ToolsetSettingCopyWith<$Res> implements $ToolsetSettingCopyWith<$Res> {
  factory _$ToolsetSettingCopyWith(_ToolsetSetting value, $Res Function(_ToolsetSetting) _then) = __$ToolsetSettingCopyWithImpl;
@override @useResult
$Res call({
 String name, String label, String description, bool enabled, bool configured, int toolCount, String platform
});




}
/// @nodoc
class __$ToolsetSettingCopyWithImpl<$Res>
    implements _$ToolsetSettingCopyWith<$Res> {
  __$ToolsetSettingCopyWithImpl(this._self, this._then);

  final _ToolsetSetting _self;
  final $Res Function(_ToolsetSetting) _then;

/// Create a copy of ToolsetSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? label = null,Object? description = null,Object? enabled = null,Object? configured = null,Object? toolCount = null,Object? platform = null,}) {
  return _then(_ToolsetSetting(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,toolCount: null == toolCount ? _self.toolCount : toolCount // ignore: cast_nullable_to_non_nullable
as int,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$McpServerSetting {

 String get name;/// `stdio`, `http` ou `unknown`.
 String get transport;/// `oauth`, `header` ou nulo.
 String? get auth; bool get enabled;/// Plugin que fornece o servidor; esses não podem ser alterados.
 String? get plugin;
/// Create a copy of McpServerSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerSettingCopyWith<McpServerSetting> get copyWith => _$McpServerSettingCopyWithImpl<McpServerSetting>(this as McpServerSetting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerSetting&&(identical(other.name, name) || other.name == name)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.auth, auth) || other.auth == auth)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.plugin, plugin) || other.plugin == plugin));
}


@override
int get hashCode => Object.hash(runtimeType,name,transport,auth,enabled,plugin);

@override
String toString() {
  return 'McpServerSetting(name: $name, transport: $transport, auth: $auth, enabled: $enabled, plugin: $plugin)';
}


}

/// @nodoc
abstract mixin class $McpServerSettingCopyWith<$Res>  {
  factory $McpServerSettingCopyWith(McpServerSetting value, $Res Function(McpServerSetting) _then) = _$McpServerSettingCopyWithImpl;
@useResult
$Res call({
 String name, String transport, String? auth, bool enabled, String? plugin
});




}
/// @nodoc
class _$McpServerSettingCopyWithImpl<$Res>
    implements $McpServerSettingCopyWith<$Res> {
  _$McpServerSettingCopyWithImpl(this._self, this._then);

  final McpServerSetting _self;
  final $Res Function(McpServerSetting) _then;

/// Create a copy of McpServerSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? transport = null,Object? auth = freezed,Object? enabled = null,Object? plugin = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as String,auth: freezed == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,plugin: freezed == plugin ? _self.plugin : plugin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [McpServerSetting].
extension McpServerSettingPatterns on McpServerSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerSetting value)  $default,){
final _that = this;
switch (_that) {
case _McpServerSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerSetting value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String transport,  String? auth,  bool enabled,  String? plugin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerSetting() when $default != null:
return $default(_that.name,_that.transport,_that.auth,_that.enabled,_that.plugin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String transport,  String? auth,  bool enabled,  String? plugin)  $default,) {final _that = this;
switch (_that) {
case _McpServerSetting():
return $default(_that.name,_that.transport,_that.auth,_that.enabled,_that.plugin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String transport,  String? auth,  bool enabled,  String? plugin)?  $default,) {final _that = this;
switch (_that) {
case _McpServerSetting() when $default != null:
return $default(_that.name,_that.transport,_that.auth,_that.enabled,_that.plugin);case _:
  return null;

}
}

}

/// @nodoc


class _McpServerSetting extends McpServerSetting {
  const _McpServerSetting({required this.name, this.transport = 'unknown', this.auth, this.enabled = true, this.plugin}): super._();
  

@override final  String name;
/// `stdio`, `http` ou `unknown`.
@override@JsonKey() final  String transport;
/// `oauth`, `header` ou nulo.
@override final  String? auth;
@override@JsonKey() final  bool enabled;
/// Plugin que fornece o servidor; esses não podem ser alterados.
@override final  String? plugin;

/// Create a copy of McpServerSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerSettingCopyWith<_McpServerSetting> get copyWith => __$McpServerSettingCopyWithImpl<_McpServerSetting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerSetting&&(identical(other.name, name) || other.name == name)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.auth, auth) || other.auth == auth)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.plugin, plugin) || other.plugin == plugin));
}


@override
int get hashCode => Object.hash(runtimeType,name,transport,auth,enabled,plugin);

@override
String toString() {
  return 'McpServerSetting(name: $name, transport: $transport, auth: $auth, enabled: $enabled, plugin: $plugin)';
}


}

/// @nodoc
abstract mixin class _$McpServerSettingCopyWith<$Res> implements $McpServerSettingCopyWith<$Res> {
  factory _$McpServerSettingCopyWith(_McpServerSetting value, $Res Function(_McpServerSetting) _then) = __$McpServerSettingCopyWithImpl;
@override @useResult
$Res call({
 String name, String transport, String? auth, bool enabled, String? plugin
});




}
/// @nodoc
class __$McpServerSettingCopyWithImpl<$Res>
    implements _$McpServerSettingCopyWith<$Res> {
  __$McpServerSettingCopyWithImpl(this._self, this._then);

  final _McpServerSetting _self;
  final $Res Function(_McpServerSetting) _then;

/// Create a copy of McpServerSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? transport = null,Object? auth = freezed,Object? enabled = null,Object? plugin = freezed,}) {
  return _then(_McpServerSetting(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as String,auth: freezed == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,plugin: freezed == plugin ? _self.plugin : plugin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$McpProbe {

 bool get ok; String? get error; List<String> get tools;
/// Create a copy of McpProbe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpProbeCopyWith<McpProbe> get copyWith => _$McpProbeCopyWithImpl<McpProbe>(this as McpProbe, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpProbe&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.tools, tools));
}


@override
int get hashCode => Object.hash(runtimeType,ok,error,const DeepCollectionEquality().hash(tools));

@override
String toString() {
  return 'McpProbe(ok: $ok, error: $error, tools: $tools)';
}


}

/// @nodoc
abstract mixin class $McpProbeCopyWith<$Res>  {
  factory $McpProbeCopyWith(McpProbe value, $Res Function(McpProbe) _then) = _$McpProbeCopyWithImpl;
@useResult
$Res call({
 bool ok, String? error, List<String> tools
});




}
/// @nodoc
class _$McpProbeCopyWithImpl<$Res>
    implements $McpProbeCopyWith<$Res> {
  _$McpProbeCopyWithImpl(this._self, this._then);

  final McpProbe _self;
  final $Res Function(McpProbe) _then;

/// Create a copy of McpProbe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? error = freezed,Object? tools = null,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [McpProbe].
extension McpProbePatterns on McpProbe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpProbe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpProbe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpProbe value)  $default,){
final _that = this;
switch (_that) {
case _McpProbe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpProbe value)?  $default,){
final _that = this;
switch (_that) {
case _McpProbe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  String? error,  List<String> tools)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpProbe() when $default != null:
return $default(_that.ok,_that.error,_that.tools);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  String? error,  List<String> tools)  $default,) {final _that = this;
switch (_that) {
case _McpProbe():
return $default(_that.ok,_that.error,_that.tools);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  String? error,  List<String> tools)?  $default,) {final _that = this;
switch (_that) {
case _McpProbe() when $default != null:
return $default(_that.ok,_that.error,_that.tools);case _:
  return null;

}
}

}

/// @nodoc


class _McpProbe implements McpProbe {
  const _McpProbe({required this.ok, this.error, final  List<String> tools = const <String>[]}): _tools = tools;
  

@override final  bool ok;
@override final  String? error;
 final  List<String> _tools;
@override@JsonKey() List<String> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}


/// Create a copy of McpProbe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpProbeCopyWith<_McpProbe> get copyWith => __$McpProbeCopyWithImpl<_McpProbe>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpProbe&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._tools, _tools));
}


@override
int get hashCode => Object.hash(runtimeType,ok,error,const DeepCollectionEquality().hash(_tools));

@override
String toString() {
  return 'McpProbe(ok: $ok, error: $error, tools: $tools)';
}


}

/// @nodoc
abstract mixin class _$McpProbeCopyWith<$Res> implements $McpProbeCopyWith<$Res> {
  factory _$McpProbeCopyWith(_McpProbe value, $Res Function(_McpProbe) _then) = __$McpProbeCopyWithImpl;
@override @useResult
$Res call({
 bool ok, String? error, List<String> tools
});




}
/// @nodoc
class __$McpProbeCopyWithImpl<$Res>
    implements _$McpProbeCopyWith<$Res> {
  __$McpProbeCopyWithImpl(this._self, this._then);

  final _McpProbe _self;
  final $Res Function(_McpProbe) _then;

/// Create a copy of McpProbe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? error = freezed,Object? tools = null,}) {
  return _then(_McpProbe(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

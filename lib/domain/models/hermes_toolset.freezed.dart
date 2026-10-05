// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hermes_toolset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HermesToolset {

 String get name; String get label; String get description; bool get enabled; bool get configured; List<String> get tools;
/// Create a copy of HermesToolset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HermesToolsetCopyWith<HermesToolset> get copyWith => _$HermesToolsetCopyWithImpl<HermesToolset>(this as HermesToolset, _$identity);

  /// Serializes this HermesToolset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HermesToolset&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.configured, configured) || other.configured == configured)&&const DeepCollectionEquality().equals(other.tools, tools));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,label,description,enabled,configured,const DeepCollectionEquality().hash(tools));

@override
String toString() {
  return 'HermesToolset(name: $name, label: $label, description: $description, enabled: $enabled, configured: $configured, tools: $tools)';
}


}

/// @nodoc
abstract mixin class $HermesToolsetCopyWith<$Res>  {
  factory $HermesToolsetCopyWith(HermesToolset value, $Res Function(HermesToolset) _then) = _$HermesToolsetCopyWithImpl;
@useResult
$Res call({
 String name, String label, String description, bool enabled, bool configured, List<String> tools
});




}
/// @nodoc
class _$HermesToolsetCopyWithImpl<$Res>
    implements $HermesToolsetCopyWith<$Res> {
  _$HermesToolsetCopyWithImpl(this._self, this._then);

  final HermesToolset _self;
  final $Res Function(HermesToolset) _then;

/// Create a copy of HermesToolset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? label = null,Object? description = null,Object? enabled = null,Object? configured = null,Object? tools = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [HermesToolset].
extension HermesToolsetPatterns on HermesToolset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HermesToolset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HermesToolset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HermesToolset value)  $default,){
final _that = this;
switch (_that) {
case _HermesToolset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HermesToolset value)?  $default,){
final _that = this;
switch (_that) {
case _HermesToolset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String label,  String description,  bool enabled,  bool configured,  List<String> tools)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HermesToolset() when $default != null:
return $default(_that.name,_that.label,_that.description,_that.enabled,_that.configured,_that.tools);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String label,  String description,  bool enabled,  bool configured,  List<String> tools)  $default,) {final _that = this;
switch (_that) {
case _HermesToolset():
return $default(_that.name,_that.label,_that.description,_that.enabled,_that.configured,_that.tools);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String label,  String description,  bool enabled,  bool configured,  List<String> tools)?  $default,) {final _that = this;
switch (_that) {
case _HermesToolset() when $default != null:
return $default(_that.name,_that.label,_that.description,_that.enabled,_that.configured,_that.tools);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HermesToolset implements HermesToolset {
  const _HermesToolset({required this.name, this.label = '', this.description = '', this.enabled = false, this.configured = false, final  List<String> tools = const <String>[]}): _tools = tools;
  factory _HermesToolset.fromJson(Map<String, dynamic> json) => _$HermesToolsetFromJson(json);

@override final  String name;
@override@JsonKey() final  String label;
@override@JsonKey() final  String description;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool configured;
 final  List<String> _tools;
@override@JsonKey() List<String> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}


/// Create a copy of HermesToolset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HermesToolsetCopyWith<_HermesToolset> get copyWith => __$HermesToolsetCopyWithImpl<_HermesToolset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HermesToolsetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HermesToolset&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.configured, configured) || other.configured == configured)&&const DeepCollectionEquality().equals(other._tools, _tools));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,label,description,enabled,configured,const DeepCollectionEquality().hash(_tools));

@override
String toString() {
  return 'HermesToolset(name: $name, label: $label, description: $description, enabled: $enabled, configured: $configured, tools: $tools)';
}


}

/// @nodoc
abstract mixin class _$HermesToolsetCopyWith<$Res> implements $HermesToolsetCopyWith<$Res> {
  factory _$HermesToolsetCopyWith(_HermesToolset value, $Res Function(_HermesToolset) _then) = __$HermesToolsetCopyWithImpl;
@override @useResult
$Res call({
 String name, String label, String description, bool enabled, bool configured, List<String> tools
});




}
/// @nodoc
class __$HermesToolsetCopyWithImpl<$Res>
    implements _$HermesToolsetCopyWith<$Res> {
  __$HermesToolsetCopyWithImpl(this._self, this._then);

  final _HermesToolset _self;
  final $Res Function(_HermesToolset) _then;

/// Create a copy of HermesToolset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? label = null,Object? description = null,Object? enabled = null,Object? configured = null,Object? tools = null,}) {
  return _then(_HermesToolset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'turn_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TurnActivity {

 String get id;
/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnActivityCopyWith<TurnActivity> get copyWith => _$TurnActivityCopyWithImpl<TurnActivity>(this as TurnActivity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnActivity&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'TurnActivity(id: $id)';
}


}

/// @nodoc
abstract mixin class $TurnActivityCopyWith<$Res>  {
  factory $TurnActivityCopyWith(TurnActivity value, $Res Function(TurnActivity) _then) = _$TurnActivityCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$TurnActivityCopyWithImpl<$Res>
    implements $TurnActivityCopyWith<$Res> {
  _$TurnActivityCopyWithImpl(this._self, this._then);

  final TurnActivity _self;
  final $Res Function(TurnActivity) _then;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TurnActivity].
extension TurnActivityPatterns on TurnActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TurnActivityPreview value)?  activity,TResult Function( TurnReasoning value)?  reasoning,TResult Function( TurnToolActivity value)?  tool,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TurnActivityPreview() when activity != null:
return activity(_that);case TurnReasoning() when reasoning != null:
return reasoning(_that);case TurnToolActivity() when tool != null:
return tool(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TurnActivityPreview value)  activity,required TResult Function( TurnReasoning value)  reasoning,required TResult Function( TurnToolActivity value)  tool,}){
final _that = this;
switch (_that) {
case TurnActivityPreview():
return activity(_that);case TurnReasoning():
return reasoning(_that);case TurnToolActivity():
return tool(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TurnActivityPreview value)?  activity,TResult? Function( TurnReasoning value)?  reasoning,TResult? Function( TurnToolActivity value)?  tool,}){
final _that = this;
switch (_that) {
case TurnActivityPreview() when activity != null:
return activity(_that);case TurnReasoning() when reasoning != null:
return reasoning(_that);case TurnToolActivity() when tool != null:
return tool(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String text)?  activity,TResult Function( String id,  String text)?  reasoning,TResult Function( String id,  ToolCall tool)?  tool,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TurnActivityPreview() when activity != null:
return activity(_that.id,_that.text);case TurnReasoning() when reasoning != null:
return reasoning(_that.id,_that.text);case TurnToolActivity() when tool != null:
return tool(_that.id,_that.tool);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String text)  activity,required TResult Function( String id,  String text)  reasoning,required TResult Function( String id,  ToolCall tool)  tool,}) {final _that = this;
switch (_that) {
case TurnActivityPreview():
return activity(_that.id,_that.text);case TurnReasoning():
return reasoning(_that.id,_that.text);case TurnToolActivity():
return tool(_that.id,_that.tool);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String text)?  activity,TResult? Function( String id,  String text)?  reasoning,TResult? Function( String id,  ToolCall tool)?  tool,}) {final _that = this;
switch (_that) {
case TurnActivityPreview() when activity != null:
return activity(_that.id,_that.text);case TurnReasoning() when reasoning != null:
return reasoning(_that.id,_that.text);case TurnToolActivity() when tool != null:
return tool(_that.id,_that.tool);case _:
  return null;

}
}

}

/// @nodoc


class TurnActivityPreview implements TurnActivity {
  const TurnActivityPreview({required this.id, required this.text});
  

@override final  String id;
 final  String text;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnActivityPreviewCopyWith<TurnActivityPreview> get copyWith => _$TurnActivityPreviewCopyWithImpl<TurnActivityPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnActivityPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'TurnActivity.activity(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $TurnActivityPreviewCopyWith<$Res> implements $TurnActivityCopyWith<$Res> {
  factory $TurnActivityPreviewCopyWith(TurnActivityPreview value, $Res Function(TurnActivityPreview) _then) = _$TurnActivityPreviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class _$TurnActivityPreviewCopyWithImpl<$Res>
    implements $TurnActivityPreviewCopyWith<$Res> {
  _$TurnActivityPreviewCopyWithImpl(this._self, this._then);

  final TurnActivityPreview _self;
  final $Res Function(TurnActivityPreview) _then;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,}) {
  return _then(TurnActivityPreview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TurnReasoning implements TurnActivity {
  const TurnReasoning({required this.id, required this.text});
  

@override final  String id;
 final  String text;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnReasoningCopyWith<TurnReasoning> get copyWith => _$TurnReasoningCopyWithImpl<TurnReasoning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnReasoning&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'TurnActivity.reasoning(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $TurnReasoningCopyWith<$Res> implements $TurnActivityCopyWith<$Res> {
  factory $TurnReasoningCopyWith(TurnReasoning value, $Res Function(TurnReasoning) _then) = _$TurnReasoningCopyWithImpl;
@override @useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class _$TurnReasoningCopyWithImpl<$Res>
    implements $TurnReasoningCopyWith<$Res> {
  _$TurnReasoningCopyWithImpl(this._self, this._then);

  final TurnReasoning _self;
  final $Res Function(TurnReasoning) _then;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,}) {
  return _then(TurnReasoning(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TurnToolActivity implements TurnActivity {
  const TurnToolActivity({required this.id, required this.tool});
  

@override final  String id;
 final  ToolCall tool;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnToolActivityCopyWith<TurnToolActivity> get copyWith => _$TurnToolActivityCopyWithImpl<TurnToolActivity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnToolActivity&&(identical(other.id, id) || other.id == id)&&(identical(other.tool, tool) || other.tool == tool));
}


@override
int get hashCode => Object.hash(runtimeType,id,tool);

@override
String toString() {
  return 'TurnActivity.tool(id: $id, tool: $tool)';
}


}

/// @nodoc
abstract mixin class $TurnToolActivityCopyWith<$Res> implements $TurnActivityCopyWith<$Res> {
  factory $TurnToolActivityCopyWith(TurnToolActivity value, $Res Function(TurnToolActivity) _then) = _$TurnToolActivityCopyWithImpl;
@override @useResult
$Res call({
 String id, ToolCall tool
});


$ToolCallCopyWith<$Res> get tool;

}
/// @nodoc
class _$TurnToolActivityCopyWithImpl<$Res>
    implements $TurnToolActivityCopyWith<$Res> {
  _$TurnToolActivityCopyWithImpl(this._self, this._then);

  final TurnToolActivity _self;
  final $Res Function(TurnToolActivity) _then;

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tool = null,}) {
  return _then(TurnToolActivity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as ToolCall,
  ));
}

/// Create a copy of TurnActivity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallCopyWith<$Res> get tool {
  
  return $ToolCallCopyWith<$Res>(_self.tool, (value) {
    return _then(_self.copyWith(tool: value));
  });
}
}

// dart format on

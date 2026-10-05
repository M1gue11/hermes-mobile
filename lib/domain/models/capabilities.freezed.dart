// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capabilities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CapabilityFeatures {

@JsonKey(name: 'chat_completions') bool get chatCompletions;@JsonKey(name: 'chat_completions_streaming') bool get chatCompletionsStreaming;@JsonKey(name: 'responses_api') bool get responsesApi;@JsonKey(name: 'responses_streaming') bool get responsesStreaming;@JsonKey(name: 'run_submission') bool get runSubmission;@JsonKey(name: 'run_status') bool get runStatus;@JsonKey(name: 'run_events_sse') bool get runEventsSse;@JsonKey(name: 'run_stop') bool get runStop;@JsonKey(name: 'run_approval_response') bool get runApprovalResponse;@JsonKey(name: 'tool_progress_events') bool get toolProgressEvents;@JsonKey(name: 'approval_events') bool get approvalEvents;@JsonKey(name: 'session_resources') bool get sessionResources;@JsonKey(name: 'session_chat') bool get sessionChat;@JsonKey(name: 'session_chat_streaming') bool get sessionChatStreaming;@JsonKey(name: 'session_fork') bool get sessionFork;@JsonKey(name: 'skills_api') bool get skillsApi;@JsonKey(name: 'memory_write_api') bool get memoryWriteApi;@JsonKey(name: 'admin_config_rw') bool get adminConfigRw;@JsonKey(name: 'jobs_admin') bool get jobsAdmin;@JsonKey(name: 'audio_api') bool get audioApi;@JsonKey(name: 'realtime_voice') bool get realtimeVoice; bool get cors;@JsonKey(name: 'session_continuity_header') String? get sessionContinuityHeader;@JsonKey(name: 'session_key_header') String? get sessionKeyHeader;
/// Create a copy of CapabilityFeatures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapabilityFeaturesCopyWith<CapabilityFeatures> get copyWith => _$CapabilityFeaturesCopyWithImpl<CapabilityFeatures>(this as CapabilityFeatures, _$identity);

  /// Serializes this CapabilityFeatures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapabilityFeatures&&(identical(other.chatCompletions, chatCompletions) || other.chatCompletions == chatCompletions)&&(identical(other.chatCompletionsStreaming, chatCompletionsStreaming) || other.chatCompletionsStreaming == chatCompletionsStreaming)&&(identical(other.responsesApi, responsesApi) || other.responsesApi == responsesApi)&&(identical(other.responsesStreaming, responsesStreaming) || other.responsesStreaming == responsesStreaming)&&(identical(other.runSubmission, runSubmission) || other.runSubmission == runSubmission)&&(identical(other.runStatus, runStatus) || other.runStatus == runStatus)&&(identical(other.runEventsSse, runEventsSse) || other.runEventsSse == runEventsSse)&&(identical(other.runStop, runStop) || other.runStop == runStop)&&(identical(other.runApprovalResponse, runApprovalResponse) || other.runApprovalResponse == runApprovalResponse)&&(identical(other.toolProgressEvents, toolProgressEvents) || other.toolProgressEvents == toolProgressEvents)&&(identical(other.approvalEvents, approvalEvents) || other.approvalEvents == approvalEvents)&&(identical(other.sessionResources, sessionResources) || other.sessionResources == sessionResources)&&(identical(other.sessionChat, sessionChat) || other.sessionChat == sessionChat)&&(identical(other.sessionChatStreaming, sessionChatStreaming) || other.sessionChatStreaming == sessionChatStreaming)&&(identical(other.sessionFork, sessionFork) || other.sessionFork == sessionFork)&&(identical(other.skillsApi, skillsApi) || other.skillsApi == skillsApi)&&(identical(other.memoryWriteApi, memoryWriteApi) || other.memoryWriteApi == memoryWriteApi)&&(identical(other.adminConfigRw, adminConfigRw) || other.adminConfigRw == adminConfigRw)&&(identical(other.jobsAdmin, jobsAdmin) || other.jobsAdmin == jobsAdmin)&&(identical(other.audioApi, audioApi) || other.audioApi == audioApi)&&(identical(other.realtimeVoice, realtimeVoice) || other.realtimeVoice == realtimeVoice)&&(identical(other.cors, cors) || other.cors == cors)&&(identical(other.sessionContinuityHeader, sessionContinuityHeader) || other.sessionContinuityHeader == sessionContinuityHeader)&&(identical(other.sessionKeyHeader, sessionKeyHeader) || other.sessionKeyHeader == sessionKeyHeader));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,chatCompletions,chatCompletionsStreaming,responsesApi,responsesStreaming,runSubmission,runStatus,runEventsSse,runStop,runApprovalResponse,toolProgressEvents,approvalEvents,sessionResources,sessionChat,sessionChatStreaming,sessionFork,skillsApi,memoryWriteApi,adminConfigRw,jobsAdmin,audioApi,realtimeVoice,cors,sessionContinuityHeader,sessionKeyHeader]);

@override
String toString() {
  return 'CapabilityFeatures(chatCompletions: $chatCompletions, chatCompletionsStreaming: $chatCompletionsStreaming, responsesApi: $responsesApi, responsesStreaming: $responsesStreaming, runSubmission: $runSubmission, runStatus: $runStatus, runEventsSse: $runEventsSse, runStop: $runStop, runApprovalResponse: $runApprovalResponse, toolProgressEvents: $toolProgressEvents, approvalEvents: $approvalEvents, sessionResources: $sessionResources, sessionChat: $sessionChat, sessionChatStreaming: $sessionChatStreaming, sessionFork: $sessionFork, skillsApi: $skillsApi, memoryWriteApi: $memoryWriteApi, adminConfigRw: $adminConfigRw, jobsAdmin: $jobsAdmin, audioApi: $audioApi, realtimeVoice: $realtimeVoice, cors: $cors, sessionContinuityHeader: $sessionContinuityHeader, sessionKeyHeader: $sessionKeyHeader)';
}


}

/// @nodoc
abstract mixin class $CapabilityFeaturesCopyWith<$Res>  {
  factory $CapabilityFeaturesCopyWith(CapabilityFeatures value, $Res Function(CapabilityFeatures) _then) = _$CapabilityFeaturesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'chat_completions') bool chatCompletions,@JsonKey(name: 'chat_completions_streaming') bool chatCompletionsStreaming,@JsonKey(name: 'responses_api') bool responsesApi,@JsonKey(name: 'responses_streaming') bool responsesStreaming,@JsonKey(name: 'run_submission') bool runSubmission,@JsonKey(name: 'run_status') bool runStatus,@JsonKey(name: 'run_events_sse') bool runEventsSse,@JsonKey(name: 'run_stop') bool runStop,@JsonKey(name: 'run_approval_response') bool runApprovalResponse,@JsonKey(name: 'tool_progress_events') bool toolProgressEvents,@JsonKey(name: 'approval_events') bool approvalEvents,@JsonKey(name: 'session_resources') bool sessionResources,@JsonKey(name: 'session_chat') bool sessionChat,@JsonKey(name: 'session_chat_streaming') bool sessionChatStreaming,@JsonKey(name: 'session_fork') bool sessionFork,@JsonKey(name: 'skills_api') bool skillsApi,@JsonKey(name: 'memory_write_api') bool memoryWriteApi,@JsonKey(name: 'admin_config_rw') bool adminConfigRw,@JsonKey(name: 'jobs_admin') bool jobsAdmin,@JsonKey(name: 'audio_api') bool audioApi,@JsonKey(name: 'realtime_voice') bool realtimeVoice, bool cors,@JsonKey(name: 'session_continuity_header') String? sessionContinuityHeader,@JsonKey(name: 'session_key_header') String? sessionKeyHeader
});




}
/// @nodoc
class _$CapabilityFeaturesCopyWithImpl<$Res>
    implements $CapabilityFeaturesCopyWith<$Res> {
  _$CapabilityFeaturesCopyWithImpl(this._self, this._then);

  final CapabilityFeatures _self;
  final $Res Function(CapabilityFeatures) _then;

/// Create a copy of CapabilityFeatures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chatCompletions = null,Object? chatCompletionsStreaming = null,Object? responsesApi = null,Object? responsesStreaming = null,Object? runSubmission = null,Object? runStatus = null,Object? runEventsSse = null,Object? runStop = null,Object? runApprovalResponse = null,Object? toolProgressEvents = null,Object? approvalEvents = null,Object? sessionResources = null,Object? sessionChat = null,Object? sessionChatStreaming = null,Object? sessionFork = null,Object? skillsApi = null,Object? memoryWriteApi = null,Object? adminConfigRw = null,Object? jobsAdmin = null,Object? audioApi = null,Object? realtimeVoice = null,Object? cors = null,Object? sessionContinuityHeader = freezed,Object? sessionKeyHeader = freezed,}) {
  return _then(_self.copyWith(
chatCompletions: null == chatCompletions ? _self.chatCompletions : chatCompletions // ignore: cast_nullable_to_non_nullable
as bool,chatCompletionsStreaming: null == chatCompletionsStreaming ? _self.chatCompletionsStreaming : chatCompletionsStreaming // ignore: cast_nullable_to_non_nullable
as bool,responsesApi: null == responsesApi ? _self.responsesApi : responsesApi // ignore: cast_nullable_to_non_nullable
as bool,responsesStreaming: null == responsesStreaming ? _self.responsesStreaming : responsesStreaming // ignore: cast_nullable_to_non_nullable
as bool,runSubmission: null == runSubmission ? _self.runSubmission : runSubmission // ignore: cast_nullable_to_non_nullable
as bool,runStatus: null == runStatus ? _self.runStatus : runStatus // ignore: cast_nullable_to_non_nullable
as bool,runEventsSse: null == runEventsSse ? _self.runEventsSse : runEventsSse // ignore: cast_nullable_to_non_nullable
as bool,runStop: null == runStop ? _self.runStop : runStop // ignore: cast_nullable_to_non_nullable
as bool,runApprovalResponse: null == runApprovalResponse ? _self.runApprovalResponse : runApprovalResponse // ignore: cast_nullable_to_non_nullable
as bool,toolProgressEvents: null == toolProgressEvents ? _self.toolProgressEvents : toolProgressEvents // ignore: cast_nullable_to_non_nullable
as bool,approvalEvents: null == approvalEvents ? _self.approvalEvents : approvalEvents // ignore: cast_nullable_to_non_nullable
as bool,sessionResources: null == sessionResources ? _self.sessionResources : sessionResources // ignore: cast_nullable_to_non_nullable
as bool,sessionChat: null == sessionChat ? _self.sessionChat : sessionChat // ignore: cast_nullable_to_non_nullable
as bool,sessionChatStreaming: null == sessionChatStreaming ? _self.sessionChatStreaming : sessionChatStreaming // ignore: cast_nullable_to_non_nullable
as bool,sessionFork: null == sessionFork ? _self.sessionFork : sessionFork // ignore: cast_nullable_to_non_nullable
as bool,skillsApi: null == skillsApi ? _self.skillsApi : skillsApi // ignore: cast_nullable_to_non_nullable
as bool,memoryWriteApi: null == memoryWriteApi ? _self.memoryWriteApi : memoryWriteApi // ignore: cast_nullable_to_non_nullable
as bool,adminConfigRw: null == adminConfigRw ? _self.adminConfigRw : adminConfigRw // ignore: cast_nullable_to_non_nullable
as bool,jobsAdmin: null == jobsAdmin ? _self.jobsAdmin : jobsAdmin // ignore: cast_nullable_to_non_nullable
as bool,audioApi: null == audioApi ? _self.audioApi : audioApi // ignore: cast_nullable_to_non_nullable
as bool,realtimeVoice: null == realtimeVoice ? _self.realtimeVoice : realtimeVoice // ignore: cast_nullable_to_non_nullable
as bool,cors: null == cors ? _self.cors : cors // ignore: cast_nullable_to_non_nullable
as bool,sessionContinuityHeader: freezed == sessionContinuityHeader ? _self.sessionContinuityHeader : sessionContinuityHeader // ignore: cast_nullable_to_non_nullable
as String?,sessionKeyHeader: freezed == sessionKeyHeader ? _self.sessionKeyHeader : sessionKeyHeader // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CapabilityFeatures].
extension CapabilityFeaturesPatterns on CapabilityFeatures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapabilityFeatures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapabilityFeatures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapabilityFeatures value)  $default,){
final _that = this;
switch (_that) {
case _CapabilityFeatures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapabilityFeatures value)?  $default,){
final _that = this;
switch (_that) {
case _CapabilityFeatures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'chat_completions')  bool chatCompletions, @JsonKey(name: 'chat_completions_streaming')  bool chatCompletionsStreaming, @JsonKey(name: 'responses_api')  bool responsesApi, @JsonKey(name: 'responses_streaming')  bool responsesStreaming, @JsonKey(name: 'run_submission')  bool runSubmission, @JsonKey(name: 'run_status')  bool runStatus, @JsonKey(name: 'run_events_sse')  bool runEventsSse, @JsonKey(name: 'run_stop')  bool runStop, @JsonKey(name: 'run_approval_response')  bool runApprovalResponse, @JsonKey(name: 'tool_progress_events')  bool toolProgressEvents, @JsonKey(name: 'approval_events')  bool approvalEvents, @JsonKey(name: 'session_resources')  bool sessionResources, @JsonKey(name: 'session_chat')  bool sessionChat, @JsonKey(name: 'session_chat_streaming')  bool sessionChatStreaming, @JsonKey(name: 'session_fork')  bool sessionFork, @JsonKey(name: 'skills_api')  bool skillsApi, @JsonKey(name: 'memory_write_api')  bool memoryWriteApi, @JsonKey(name: 'admin_config_rw')  bool adminConfigRw, @JsonKey(name: 'jobs_admin')  bool jobsAdmin, @JsonKey(name: 'audio_api')  bool audioApi, @JsonKey(name: 'realtime_voice')  bool realtimeVoice,  bool cors, @JsonKey(name: 'session_continuity_header')  String? sessionContinuityHeader, @JsonKey(name: 'session_key_header')  String? sessionKeyHeader)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapabilityFeatures() when $default != null:
return $default(_that.chatCompletions,_that.chatCompletionsStreaming,_that.responsesApi,_that.responsesStreaming,_that.runSubmission,_that.runStatus,_that.runEventsSse,_that.runStop,_that.runApprovalResponse,_that.toolProgressEvents,_that.approvalEvents,_that.sessionResources,_that.sessionChat,_that.sessionChatStreaming,_that.sessionFork,_that.skillsApi,_that.memoryWriteApi,_that.adminConfigRw,_that.jobsAdmin,_that.audioApi,_that.realtimeVoice,_that.cors,_that.sessionContinuityHeader,_that.sessionKeyHeader);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'chat_completions')  bool chatCompletions, @JsonKey(name: 'chat_completions_streaming')  bool chatCompletionsStreaming, @JsonKey(name: 'responses_api')  bool responsesApi, @JsonKey(name: 'responses_streaming')  bool responsesStreaming, @JsonKey(name: 'run_submission')  bool runSubmission, @JsonKey(name: 'run_status')  bool runStatus, @JsonKey(name: 'run_events_sse')  bool runEventsSse, @JsonKey(name: 'run_stop')  bool runStop, @JsonKey(name: 'run_approval_response')  bool runApprovalResponse, @JsonKey(name: 'tool_progress_events')  bool toolProgressEvents, @JsonKey(name: 'approval_events')  bool approvalEvents, @JsonKey(name: 'session_resources')  bool sessionResources, @JsonKey(name: 'session_chat')  bool sessionChat, @JsonKey(name: 'session_chat_streaming')  bool sessionChatStreaming, @JsonKey(name: 'session_fork')  bool sessionFork, @JsonKey(name: 'skills_api')  bool skillsApi, @JsonKey(name: 'memory_write_api')  bool memoryWriteApi, @JsonKey(name: 'admin_config_rw')  bool adminConfigRw, @JsonKey(name: 'jobs_admin')  bool jobsAdmin, @JsonKey(name: 'audio_api')  bool audioApi, @JsonKey(name: 'realtime_voice')  bool realtimeVoice,  bool cors, @JsonKey(name: 'session_continuity_header')  String? sessionContinuityHeader, @JsonKey(name: 'session_key_header')  String? sessionKeyHeader)  $default,) {final _that = this;
switch (_that) {
case _CapabilityFeatures():
return $default(_that.chatCompletions,_that.chatCompletionsStreaming,_that.responsesApi,_that.responsesStreaming,_that.runSubmission,_that.runStatus,_that.runEventsSse,_that.runStop,_that.runApprovalResponse,_that.toolProgressEvents,_that.approvalEvents,_that.sessionResources,_that.sessionChat,_that.sessionChatStreaming,_that.sessionFork,_that.skillsApi,_that.memoryWriteApi,_that.adminConfigRw,_that.jobsAdmin,_that.audioApi,_that.realtimeVoice,_that.cors,_that.sessionContinuityHeader,_that.sessionKeyHeader);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'chat_completions')  bool chatCompletions, @JsonKey(name: 'chat_completions_streaming')  bool chatCompletionsStreaming, @JsonKey(name: 'responses_api')  bool responsesApi, @JsonKey(name: 'responses_streaming')  bool responsesStreaming, @JsonKey(name: 'run_submission')  bool runSubmission, @JsonKey(name: 'run_status')  bool runStatus, @JsonKey(name: 'run_events_sse')  bool runEventsSse, @JsonKey(name: 'run_stop')  bool runStop, @JsonKey(name: 'run_approval_response')  bool runApprovalResponse, @JsonKey(name: 'tool_progress_events')  bool toolProgressEvents, @JsonKey(name: 'approval_events')  bool approvalEvents, @JsonKey(name: 'session_resources')  bool sessionResources, @JsonKey(name: 'session_chat')  bool sessionChat, @JsonKey(name: 'session_chat_streaming')  bool sessionChatStreaming, @JsonKey(name: 'session_fork')  bool sessionFork, @JsonKey(name: 'skills_api')  bool skillsApi, @JsonKey(name: 'memory_write_api')  bool memoryWriteApi, @JsonKey(name: 'admin_config_rw')  bool adminConfigRw, @JsonKey(name: 'jobs_admin')  bool jobsAdmin, @JsonKey(name: 'audio_api')  bool audioApi, @JsonKey(name: 'realtime_voice')  bool realtimeVoice,  bool cors, @JsonKey(name: 'session_continuity_header')  String? sessionContinuityHeader, @JsonKey(name: 'session_key_header')  String? sessionKeyHeader)?  $default,) {final _that = this;
switch (_that) {
case _CapabilityFeatures() when $default != null:
return $default(_that.chatCompletions,_that.chatCompletionsStreaming,_that.responsesApi,_that.responsesStreaming,_that.runSubmission,_that.runStatus,_that.runEventsSse,_that.runStop,_that.runApprovalResponse,_that.toolProgressEvents,_that.approvalEvents,_that.sessionResources,_that.sessionChat,_that.sessionChatStreaming,_that.sessionFork,_that.skillsApi,_that.memoryWriteApi,_that.adminConfigRw,_that.jobsAdmin,_that.audioApi,_that.realtimeVoice,_that.cors,_that.sessionContinuityHeader,_that.sessionKeyHeader);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CapabilityFeatures implements CapabilityFeatures {
  const _CapabilityFeatures({@JsonKey(name: 'chat_completions') this.chatCompletions = false, @JsonKey(name: 'chat_completions_streaming') this.chatCompletionsStreaming = false, @JsonKey(name: 'responses_api') this.responsesApi = false, @JsonKey(name: 'responses_streaming') this.responsesStreaming = false, @JsonKey(name: 'run_submission') this.runSubmission = false, @JsonKey(name: 'run_status') this.runStatus = false, @JsonKey(name: 'run_events_sse') this.runEventsSse = false, @JsonKey(name: 'run_stop') this.runStop = false, @JsonKey(name: 'run_approval_response') this.runApprovalResponse = false, @JsonKey(name: 'tool_progress_events') this.toolProgressEvents = false, @JsonKey(name: 'approval_events') this.approvalEvents = false, @JsonKey(name: 'session_resources') this.sessionResources = false, @JsonKey(name: 'session_chat') this.sessionChat = false, @JsonKey(name: 'session_chat_streaming') this.sessionChatStreaming = false, @JsonKey(name: 'session_fork') this.sessionFork = false, @JsonKey(name: 'skills_api') this.skillsApi = false, @JsonKey(name: 'memory_write_api') this.memoryWriteApi = false, @JsonKey(name: 'admin_config_rw') this.adminConfigRw = false, @JsonKey(name: 'jobs_admin') this.jobsAdmin = false, @JsonKey(name: 'audio_api') this.audioApi = false, @JsonKey(name: 'realtime_voice') this.realtimeVoice = false, this.cors = false, @JsonKey(name: 'session_continuity_header') this.sessionContinuityHeader, @JsonKey(name: 'session_key_header') this.sessionKeyHeader});
  factory _CapabilityFeatures.fromJson(Map<String, dynamic> json) => _$CapabilityFeaturesFromJson(json);

@override@JsonKey(name: 'chat_completions') final  bool chatCompletions;
@override@JsonKey(name: 'chat_completions_streaming') final  bool chatCompletionsStreaming;
@override@JsonKey(name: 'responses_api') final  bool responsesApi;
@override@JsonKey(name: 'responses_streaming') final  bool responsesStreaming;
@override@JsonKey(name: 'run_submission') final  bool runSubmission;
@override@JsonKey(name: 'run_status') final  bool runStatus;
@override@JsonKey(name: 'run_events_sse') final  bool runEventsSse;
@override@JsonKey(name: 'run_stop') final  bool runStop;
@override@JsonKey(name: 'run_approval_response') final  bool runApprovalResponse;
@override@JsonKey(name: 'tool_progress_events') final  bool toolProgressEvents;
@override@JsonKey(name: 'approval_events') final  bool approvalEvents;
@override@JsonKey(name: 'session_resources') final  bool sessionResources;
@override@JsonKey(name: 'session_chat') final  bool sessionChat;
@override@JsonKey(name: 'session_chat_streaming') final  bool sessionChatStreaming;
@override@JsonKey(name: 'session_fork') final  bool sessionFork;
@override@JsonKey(name: 'skills_api') final  bool skillsApi;
@override@JsonKey(name: 'memory_write_api') final  bool memoryWriteApi;
@override@JsonKey(name: 'admin_config_rw') final  bool adminConfigRw;
@override@JsonKey(name: 'jobs_admin') final  bool jobsAdmin;
@override@JsonKey(name: 'audio_api') final  bool audioApi;
@override@JsonKey(name: 'realtime_voice') final  bool realtimeVoice;
@override@JsonKey() final  bool cors;
@override@JsonKey(name: 'session_continuity_header') final  String? sessionContinuityHeader;
@override@JsonKey(name: 'session_key_header') final  String? sessionKeyHeader;

/// Create a copy of CapabilityFeatures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapabilityFeaturesCopyWith<_CapabilityFeatures> get copyWith => __$CapabilityFeaturesCopyWithImpl<_CapabilityFeatures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CapabilityFeaturesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapabilityFeatures&&(identical(other.chatCompletions, chatCompletions) || other.chatCompletions == chatCompletions)&&(identical(other.chatCompletionsStreaming, chatCompletionsStreaming) || other.chatCompletionsStreaming == chatCompletionsStreaming)&&(identical(other.responsesApi, responsesApi) || other.responsesApi == responsesApi)&&(identical(other.responsesStreaming, responsesStreaming) || other.responsesStreaming == responsesStreaming)&&(identical(other.runSubmission, runSubmission) || other.runSubmission == runSubmission)&&(identical(other.runStatus, runStatus) || other.runStatus == runStatus)&&(identical(other.runEventsSse, runEventsSse) || other.runEventsSse == runEventsSse)&&(identical(other.runStop, runStop) || other.runStop == runStop)&&(identical(other.runApprovalResponse, runApprovalResponse) || other.runApprovalResponse == runApprovalResponse)&&(identical(other.toolProgressEvents, toolProgressEvents) || other.toolProgressEvents == toolProgressEvents)&&(identical(other.approvalEvents, approvalEvents) || other.approvalEvents == approvalEvents)&&(identical(other.sessionResources, sessionResources) || other.sessionResources == sessionResources)&&(identical(other.sessionChat, sessionChat) || other.sessionChat == sessionChat)&&(identical(other.sessionChatStreaming, sessionChatStreaming) || other.sessionChatStreaming == sessionChatStreaming)&&(identical(other.sessionFork, sessionFork) || other.sessionFork == sessionFork)&&(identical(other.skillsApi, skillsApi) || other.skillsApi == skillsApi)&&(identical(other.memoryWriteApi, memoryWriteApi) || other.memoryWriteApi == memoryWriteApi)&&(identical(other.adminConfigRw, adminConfigRw) || other.adminConfigRw == adminConfigRw)&&(identical(other.jobsAdmin, jobsAdmin) || other.jobsAdmin == jobsAdmin)&&(identical(other.audioApi, audioApi) || other.audioApi == audioApi)&&(identical(other.realtimeVoice, realtimeVoice) || other.realtimeVoice == realtimeVoice)&&(identical(other.cors, cors) || other.cors == cors)&&(identical(other.sessionContinuityHeader, sessionContinuityHeader) || other.sessionContinuityHeader == sessionContinuityHeader)&&(identical(other.sessionKeyHeader, sessionKeyHeader) || other.sessionKeyHeader == sessionKeyHeader));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,chatCompletions,chatCompletionsStreaming,responsesApi,responsesStreaming,runSubmission,runStatus,runEventsSse,runStop,runApprovalResponse,toolProgressEvents,approvalEvents,sessionResources,sessionChat,sessionChatStreaming,sessionFork,skillsApi,memoryWriteApi,adminConfigRw,jobsAdmin,audioApi,realtimeVoice,cors,sessionContinuityHeader,sessionKeyHeader]);

@override
String toString() {
  return 'CapabilityFeatures(chatCompletions: $chatCompletions, chatCompletionsStreaming: $chatCompletionsStreaming, responsesApi: $responsesApi, responsesStreaming: $responsesStreaming, runSubmission: $runSubmission, runStatus: $runStatus, runEventsSse: $runEventsSse, runStop: $runStop, runApprovalResponse: $runApprovalResponse, toolProgressEvents: $toolProgressEvents, approvalEvents: $approvalEvents, sessionResources: $sessionResources, sessionChat: $sessionChat, sessionChatStreaming: $sessionChatStreaming, sessionFork: $sessionFork, skillsApi: $skillsApi, memoryWriteApi: $memoryWriteApi, adminConfigRw: $adminConfigRw, jobsAdmin: $jobsAdmin, audioApi: $audioApi, realtimeVoice: $realtimeVoice, cors: $cors, sessionContinuityHeader: $sessionContinuityHeader, sessionKeyHeader: $sessionKeyHeader)';
}


}

/// @nodoc
abstract mixin class _$CapabilityFeaturesCopyWith<$Res> implements $CapabilityFeaturesCopyWith<$Res> {
  factory _$CapabilityFeaturesCopyWith(_CapabilityFeatures value, $Res Function(_CapabilityFeatures) _then) = __$CapabilityFeaturesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'chat_completions') bool chatCompletions,@JsonKey(name: 'chat_completions_streaming') bool chatCompletionsStreaming,@JsonKey(name: 'responses_api') bool responsesApi,@JsonKey(name: 'responses_streaming') bool responsesStreaming,@JsonKey(name: 'run_submission') bool runSubmission,@JsonKey(name: 'run_status') bool runStatus,@JsonKey(name: 'run_events_sse') bool runEventsSse,@JsonKey(name: 'run_stop') bool runStop,@JsonKey(name: 'run_approval_response') bool runApprovalResponse,@JsonKey(name: 'tool_progress_events') bool toolProgressEvents,@JsonKey(name: 'approval_events') bool approvalEvents,@JsonKey(name: 'session_resources') bool sessionResources,@JsonKey(name: 'session_chat') bool sessionChat,@JsonKey(name: 'session_chat_streaming') bool sessionChatStreaming,@JsonKey(name: 'session_fork') bool sessionFork,@JsonKey(name: 'skills_api') bool skillsApi,@JsonKey(name: 'memory_write_api') bool memoryWriteApi,@JsonKey(name: 'admin_config_rw') bool adminConfigRw,@JsonKey(name: 'jobs_admin') bool jobsAdmin,@JsonKey(name: 'audio_api') bool audioApi,@JsonKey(name: 'realtime_voice') bool realtimeVoice, bool cors,@JsonKey(name: 'session_continuity_header') String? sessionContinuityHeader,@JsonKey(name: 'session_key_header') String? sessionKeyHeader
});




}
/// @nodoc
class __$CapabilityFeaturesCopyWithImpl<$Res>
    implements _$CapabilityFeaturesCopyWith<$Res> {
  __$CapabilityFeaturesCopyWithImpl(this._self, this._then);

  final _CapabilityFeatures _self;
  final $Res Function(_CapabilityFeatures) _then;

/// Create a copy of CapabilityFeatures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chatCompletions = null,Object? chatCompletionsStreaming = null,Object? responsesApi = null,Object? responsesStreaming = null,Object? runSubmission = null,Object? runStatus = null,Object? runEventsSse = null,Object? runStop = null,Object? runApprovalResponse = null,Object? toolProgressEvents = null,Object? approvalEvents = null,Object? sessionResources = null,Object? sessionChat = null,Object? sessionChatStreaming = null,Object? sessionFork = null,Object? skillsApi = null,Object? memoryWriteApi = null,Object? adminConfigRw = null,Object? jobsAdmin = null,Object? audioApi = null,Object? realtimeVoice = null,Object? cors = null,Object? sessionContinuityHeader = freezed,Object? sessionKeyHeader = freezed,}) {
  return _then(_CapabilityFeatures(
chatCompletions: null == chatCompletions ? _self.chatCompletions : chatCompletions // ignore: cast_nullable_to_non_nullable
as bool,chatCompletionsStreaming: null == chatCompletionsStreaming ? _self.chatCompletionsStreaming : chatCompletionsStreaming // ignore: cast_nullable_to_non_nullable
as bool,responsesApi: null == responsesApi ? _self.responsesApi : responsesApi // ignore: cast_nullable_to_non_nullable
as bool,responsesStreaming: null == responsesStreaming ? _self.responsesStreaming : responsesStreaming // ignore: cast_nullable_to_non_nullable
as bool,runSubmission: null == runSubmission ? _self.runSubmission : runSubmission // ignore: cast_nullable_to_non_nullable
as bool,runStatus: null == runStatus ? _self.runStatus : runStatus // ignore: cast_nullable_to_non_nullable
as bool,runEventsSse: null == runEventsSse ? _self.runEventsSse : runEventsSse // ignore: cast_nullable_to_non_nullable
as bool,runStop: null == runStop ? _self.runStop : runStop // ignore: cast_nullable_to_non_nullable
as bool,runApprovalResponse: null == runApprovalResponse ? _self.runApprovalResponse : runApprovalResponse // ignore: cast_nullable_to_non_nullable
as bool,toolProgressEvents: null == toolProgressEvents ? _self.toolProgressEvents : toolProgressEvents // ignore: cast_nullable_to_non_nullable
as bool,approvalEvents: null == approvalEvents ? _self.approvalEvents : approvalEvents // ignore: cast_nullable_to_non_nullable
as bool,sessionResources: null == sessionResources ? _self.sessionResources : sessionResources // ignore: cast_nullable_to_non_nullable
as bool,sessionChat: null == sessionChat ? _self.sessionChat : sessionChat // ignore: cast_nullable_to_non_nullable
as bool,sessionChatStreaming: null == sessionChatStreaming ? _self.sessionChatStreaming : sessionChatStreaming // ignore: cast_nullable_to_non_nullable
as bool,sessionFork: null == sessionFork ? _self.sessionFork : sessionFork // ignore: cast_nullable_to_non_nullable
as bool,skillsApi: null == skillsApi ? _self.skillsApi : skillsApi // ignore: cast_nullable_to_non_nullable
as bool,memoryWriteApi: null == memoryWriteApi ? _self.memoryWriteApi : memoryWriteApi // ignore: cast_nullable_to_non_nullable
as bool,adminConfigRw: null == adminConfigRw ? _self.adminConfigRw : adminConfigRw // ignore: cast_nullable_to_non_nullable
as bool,jobsAdmin: null == jobsAdmin ? _self.jobsAdmin : jobsAdmin // ignore: cast_nullable_to_non_nullable
as bool,audioApi: null == audioApi ? _self.audioApi : audioApi // ignore: cast_nullable_to_non_nullable
as bool,realtimeVoice: null == realtimeVoice ? _self.realtimeVoice : realtimeVoice // ignore: cast_nullable_to_non_nullable
as bool,cors: null == cors ? _self.cors : cors // ignore: cast_nullable_to_non_nullable
as bool,sessionContinuityHeader: freezed == sessionContinuityHeader ? _self.sessionContinuityHeader : sessionContinuityHeader // ignore: cast_nullable_to_non_nullable
as String?,sessionKeyHeader: freezed == sessionKeyHeader ? _self.sessionKeyHeader : sessionKeyHeader // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Capabilities {

 String? get platform; String? get model; CapabilityFeatures get features; CapabilityAuth get auth;
/// Create a copy of Capabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapabilitiesCopyWith<Capabilities> get copyWith => _$CapabilitiesCopyWithImpl<Capabilities>(this as Capabilities, _$identity);

  /// Serializes this Capabilities to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Capabilities&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.model, model) || other.model == model)&&(identical(other.features, features) || other.features == features)&&(identical(other.auth, auth) || other.auth == auth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,model,features,auth);

@override
String toString() {
  return 'Capabilities(platform: $platform, model: $model, features: $features, auth: $auth)';
}


}

/// @nodoc
abstract mixin class $CapabilitiesCopyWith<$Res>  {
  factory $CapabilitiesCopyWith(Capabilities value, $Res Function(Capabilities) _then) = _$CapabilitiesCopyWithImpl;
@useResult
$Res call({
 String? platform, String? model, CapabilityFeatures features, CapabilityAuth auth
});


$CapabilityFeaturesCopyWith<$Res> get features;

}
/// @nodoc
class _$CapabilitiesCopyWithImpl<$Res>
    implements $CapabilitiesCopyWith<$Res> {
  _$CapabilitiesCopyWithImpl(this._self, this._then);

  final Capabilities _self;
  final $Res Function(Capabilities) _then;

/// Create a copy of Capabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = freezed,Object? model = freezed,Object? features = null,Object? auth = null,}) {
  return _then(_self.copyWith(
platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as CapabilityFeatures,auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as CapabilityAuth,
  ));
}
/// Create a copy of Capabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityFeaturesCopyWith<$Res> get features {
  
  return $CapabilityFeaturesCopyWith<$Res>(_self.features, (value) {
    return _then(_self.copyWith(features: value));
  });
}
}


/// Adds pattern-matching-related methods to [Capabilities].
extension CapabilitiesPatterns on Capabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Capabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Capabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Capabilities value)  $default,){
final _that = this;
switch (_that) {
case _Capabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Capabilities value)?  $default,){
final _that = this;
switch (_that) {
case _Capabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? platform,  String? model,  CapabilityFeatures features,  CapabilityAuth auth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Capabilities() when $default != null:
return $default(_that.platform,_that.model,_that.features,_that.auth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? platform,  String? model,  CapabilityFeatures features,  CapabilityAuth auth)  $default,) {final _that = this;
switch (_that) {
case _Capabilities():
return $default(_that.platform,_that.model,_that.features,_that.auth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? platform,  String? model,  CapabilityFeatures features,  CapabilityAuth auth)?  $default,) {final _that = this;
switch (_that) {
case _Capabilities() when $default != null:
return $default(_that.platform,_that.model,_that.features,_that.auth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Capabilities implements Capabilities {
  const _Capabilities({this.platform, this.model, this.features = const CapabilityFeatures(), this.auth = const CapabilityAuth()});
  factory _Capabilities.fromJson(Map<String, dynamic> json) => _$CapabilitiesFromJson(json);

@override final  String? platform;
@override final  String? model;
@override@JsonKey() final  CapabilityFeatures features;
@override@JsonKey() final  CapabilityAuth auth;

/// Create a copy of Capabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapabilitiesCopyWith<_Capabilities> get copyWith => __$CapabilitiesCopyWithImpl<_Capabilities>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CapabilitiesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Capabilities&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.model, model) || other.model == model)&&(identical(other.features, features) || other.features == features)&&(identical(other.auth, auth) || other.auth == auth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,model,features,auth);

@override
String toString() {
  return 'Capabilities(platform: $platform, model: $model, features: $features, auth: $auth)';
}


}

/// @nodoc
abstract mixin class _$CapabilitiesCopyWith<$Res> implements $CapabilitiesCopyWith<$Res> {
  factory _$CapabilitiesCopyWith(_Capabilities value, $Res Function(_Capabilities) _then) = __$CapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 String? platform, String? model, CapabilityFeatures features, CapabilityAuth auth
});


@override $CapabilityFeaturesCopyWith<$Res> get features;

}
/// @nodoc
class __$CapabilitiesCopyWithImpl<$Res>
    implements _$CapabilitiesCopyWith<$Res> {
  __$CapabilitiesCopyWithImpl(this._self, this._then);

  final _Capabilities _self;
  final $Res Function(_Capabilities) _then;

/// Create a copy of Capabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = freezed,Object? model = freezed,Object? features = null,Object? auth = null,}) {
  return _then(_Capabilities(
platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as CapabilityFeatures,auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as CapabilityAuth,
  ));
}

/// Create a copy of Capabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityFeaturesCopyWith<$Res> get features {
  
  return $CapabilityFeaturesCopyWith<$Res>(_self.features, (value) {
    return _then(_self.copyWith(features: value));
  });
}
}

// dart format on

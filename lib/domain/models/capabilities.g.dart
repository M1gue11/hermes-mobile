// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CapabilityFeatures _$CapabilityFeaturesFromJson(Map<String, dynamic> json) =>
    _CapabilityFeatures(
      chatCompletions: json['chat_completions'] as bool? ?? false,
      chatCompletionsStreaming:
          json['chat_completions_streaming'] as bool? ?? false,
      responsesApi: json['responses_api'] as bool? ?? false,
      responsesStreaming: json['responses_streaming'] as bool? ?? false,
      runSubmission: json['run_submission'] as bool? ?? false,
      runStatus: json['run_status'] as bool? ?? false,
      runEventsSse: json['run_events_sse'] as bool? ?? false,
      runStop: json['run_stop'] as bool? ?? false,
      runApprovalResponse: json['run_approval_response'] as bool? ?? false,
      toolProgressEvents: json['tool_progress_events'] as bool? ?? false,
      approvalEvents: json['approval_events'] as bool? ?? false,
      sessionResources: json['session_resources'] as bool? ?? false,
      sessionChat: json['session_chat'] as bool? ?? false,
      sessionChatStreaming: json['session_chat_streaming'] as bool? ?? false,
      sessionFork: json['session_fork'] as bool? ?? false,
      skillsApi: json['skills_api'] as bool? ?? false,
      memoryWriteApi: json['memory_write_api'] as bool? ?? false,
      adminConfigRw: json['admin_config_rw'] as bool? ?? false,
      jobsAdmin: json['jobs_admin'] as bool? ?? false,
      audioApi: json['audio_api'] as bool? ?? false,
      realtimeVoice: json['realtime_voice'] as bool? ?? false,
      cors: json['cors'] as bool? ?? false,
      sessionContinuityHeader: json['session_continuity_header'] as String?,
      sessionKeyHeader: json['session_key_header'] as String?,
    );

Map<String, dynamic> _$CapabilityFeaturesToJson(_CapabilityFeatures instance) =>
    <String, dynamic>{
      'chat_completions': instance.chatCompletions,
      'chat_completions_streaming': instance.chatCompletionsStreaming,
      'responses_api': instance.responsesApi,
      'responses_streaming': instance.responsesStreaming,
      'run_submission': instance.runSubmission,
      'run_status': instance.runStatus,
      'run_events_sse': instance.runEventsSse,
      'run_stop': instance.runStop,
      'run_approval_response': instance.runApprovalResponse,
      'tool_progress_events': instance.toolProgressEvents,
      'approval_events': instance.approvalEvents,
      'session_resources': instance.sessionResources,
      'session_chat': instance.sessionChat,
      'session_chat_streaming': instance.sessionChatStreaming,
      'session_fork': instance.sessionFork,
      'skills_api': instance.skillsApi,
      'memory_write_api': instance.memoryWriteApi,
      'admin_config_rw': instance.adminConfigRw,
      'jobs_admin': instance.jobsAdmin,
      'audio_api': instance.audioApi,
      'realtime_voice': instance.realtimeVoice,
      'cors': instance.cors,
      'session_continuity_header': instance.sessionContinuityHeader,
      'session_key_header': instance.sessionKeyHeader,
    };

_Capabilities _$CapabilitiesFromJson(Map<String, dynamic> json) =>
    _Capabilities(
      platform: json['platform'] as String?,
      model: json['model'] as String?,
      features: json['features'] == null
          ? const CapabilityFeatures()
          : CapabilityFeatures.fromJson(
              json['features'] as Map<String, dynamic>,
            ),
      auth: json['auth'] == null
          ? const CapabilityAuth()
          : CapabilityAuth.fromJson(json['auth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CapabilitiesToJson(_Capabilities instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'model': instance.model,
      'features': instance.features,
      'auth': instance.auth,
    };

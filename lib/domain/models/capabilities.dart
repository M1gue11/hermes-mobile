import 'package:freezed_annotation/freezed_annotation.dart';

part 'capabilities.freezed.dart';
part 'capabilities.g.dart';

/// Features expostas por `GET /v1/capabilities`. Decidem o que a UI habilita
/// (ex.: só mostrar botão cancelar se [runStop] for true).
@freezed
abstract class CapabilityFeatures with _$CapabilityFeatures {
  const factory CapabilityFeatures({
    @JsonKey(name: 'chat_completions') @Default(false) bool chatCompletions,
    @JsonKey(name: 'chat_completions_streaming')
    @Default(false)
    bool chatCompletionsStreaming,
    @JsonKey(name: 'responses_api') @Default(false) bool responsesApi,
    @JsonKey(name: 'responses_streaming') @Default(false) bool responsesStreaming,
    @JsonKey(name: 'run_submission') @Default(false) bool runSubmission,
    @JsonKey(name: 'run_status') @Default(false) bool runStatus,
    @JsonKey(name: 'run_events_sse') @Default(false) bool runEventsSse,
    @JsonKey(name: 'run_stop') @Default(false) bool runStop,
    @JsonKey(name: 'run_approval_response')
    @Default(false)
    bool runApprovalResponse,
    @JsonKey(name: 'tool_progress_events')
    @Default(false)
    bool toolProgressEvents,
    @JsonKey(name: 'approval_events') @Default(false) bool approvalEvents,
    @JsonKey(name: 'session_resources') @Default(false) bool sessionResources,
    @JsonKey(name: 'session_chat') @Default(false) bool sessionChat,
    @JsonKey(name: 'session_chat_streaming')
    @Default(false)
    bool sessionChatStreaming,
    @JsonKey(name: 'session_fork') @Default(false) bool sessionFork,
    @JsonKey(name: 'skills_api') @Default(false) bool skillsApi,
    @JsonKey(name: 'memory_write_api') @Default(false) bool memoryWriteApi,
    @JsonKey(name: 'admin_config_rw') @Default(false) bool adminConfigRw,
    @JsonKey(name: 'jobs_admin') @Default(false) bool jobsAdmin,
    @JsonKey(name: 'audio_api') @Default(false) bool audioApi,
    @JsonKey(name: 'realtime_voice') @Default(false) bool realtimeVoice,
    @Default(false) bool cors,
    @JsonKey(name: 'session_continuity_header') String? sessionContinuityHeader,
    @JsonKey(name: 'session_key_header') String? sessionKeyHeader,
  }) = _CapabilityFeatures;

  factory CapabilityFeatures.fromJson(Map<String, dynamic> json) =>
      _$CapabilityFeaturesFromJson(json);
}

/// Requisitos de autenticação anunciados por `GET /v1/capabilities`.
class CapabilityAuth {
  const CapabilityAuth({this.type, this.required = false});

  factory CapabilityAuth.fromJson(Map<String, dynamic> json) => CapabilityAuth(
        type: json['type'] as String?,
        required: json['required'] as bool? ?? false,
      );

  final String? type;
  final bool required;

  Map<String, dynamic> toJson() => {'type': type, 'required': required};
}

/// Resposta de `GET /v1/capabilities`.
@freezed
abstract class Capabilities with _$Capabilities {
  const factory Capabilities({
    String? platform,
    String? model,
    @Default(CapabilityFeatures()) CapabilityFeatures features,
    @Default(CapabilityAuth()) CapabilityAuth auth,
  }) = _Capabilities;

  factory Capabilities.fromJson(Map<String, dynamic> json) =>
      _$CapabilitiesFromJson(json);
}

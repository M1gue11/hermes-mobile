import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_timestamp.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Uma sessão persistida no Hermes, exibida na tela "Conversas".
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    @Default('Nova conversa') String title,
    @Default('') String preview,
    String? model,
    String? provider,
    @JsonKey(
      name: 'last_active',
      fromJson: apiTimestampFromJson,
      toJson: apiTimestampToJson,
    )
    DateTime? lastActive,
    @JsonKey(
      name: 'started_at',
      fromJson: apiTimestampFromJson,
      toJson: apiTimestampToJson,
    )
    DateTime? startedAt,
    @JsonKey(name: 'message_count') @Default(0) num messageCount,
    @JsonKey(name: 'tool_call_count') @Default(0) num toolCallCount,
    String? source,
    @JsonKey(name: 'parent_session_id') String? parentSessionId,
    @JsonKey(name: 'end_reason') String? endReason,
    @JsonKey(name: 'input_tokens') @Default(0) num inputTokens,
    @JsonKey(name: 'output_tokens') @Default(0) num outputTokens,
    @JsonKey(name: 'estimated_cost_usd') num? estimatedCostUsd,
    @JsonKey(name: 'actual_cost_usd') num? actualCostUsd,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

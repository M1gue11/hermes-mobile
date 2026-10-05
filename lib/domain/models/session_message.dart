import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_timestamp.dart';

part 'session_message.freezed.dart';
part 'session_message.g.dart';

/// Mensagem persistida por `GET /api/sessions/{id}/messages`.
///
/// O gateway também pode devolver mensagens de ferramenta. A camada de
/// apresentação decide quais papéis fazem sentido para a timeline do chat.
@freezed
abstract class SessionMessage with _$SessionMessage {
  const factory SessionMessage({
    required String id,
    required String role,
    @Default('') String content,
    @JsonKey(fromJson: apiTimestampFromJson, toJson: apiTimestampToJson) DateTime? timestamp,
    String? reasoning,
    @JsonKey(name: 'reasoning_content') String? reasoningContent,
    @JsonKey(name: 'tool_name') String? toolName,
    @JsonKey(name: 'tool_call_id') String? toolCallId,
    @JsonKey(name: 'tool_calls') Object? toolCalls,
    @JsonKey(name: 'token_count') num? tokenCount,
    @JsonKey(name: 'finish_reason') String? finishReason,
  }) = _SessionMessage;

  factory SessionMessage.fromJson(Map<String, dynamic> json) =>
      _$SessionMessageFromJson(json);
}

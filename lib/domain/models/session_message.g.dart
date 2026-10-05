// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionMessage _$SessionMessageFromJson(Map<String, dynamic> json) =>
    _SessionMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      timestamp: apiTimestampFromJson(json['timestamp']),
      reasoning: json['reasoning'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolName: json['tool_name'] as String?,
      toolCallId: json['tool_call_id'] as String?,
      toolCalls: json['tool_calls'],
      tokenCount: json['token_count'] as num?,
      finishReason: json['finish_reason'] as String?,
    );

Map<String, dynamic> _$SessionMessageToJson(_SessionMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'timestamp': apiTimestampToJson(instance.timestamp),
      'reasoning': instance.reasoning,
      'reasoning_content': instance.reasoningContent,
      'tool_name': instance.toolName,
      'tool_call_id': instance.toolCallId,
      'tool_calls': instance.toolCalls,
      'token_count': instance.tokenCount,
      'finish_reason': instance.finishReason,
    };

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
      rowId: (json['row_id'] as num?)?.toInt(),
      displayKind: json['display_kind'] as String?,
      displayMetadata: json['display_metadata'] as Map<String, dynamic>?,
      displayCommentary:
          (json['display_commentary'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      timestamp: apiTimestampFromJson(json['timestamp']),
      reasoning: json['reasoning'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolName: json['tool_name'] as String?,
      toolContext: json['context'] as String?,
      toolArgs: json['args'] as Map<String, dynamic>?,
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
      'row_id': instance.rowId,
      'display_kind': instance.displayKind,
      'display_metadata': instance.displayMetadata,
      'display_commentary': instance.displayCommentary,
      'timestamp': apiTimestampToJson(instance.timestamp),
      'reasoning': instance.reasoning,
      'reasoning_content': instance.reasoningContent,
      'tool_name': instance.toolName,
      'context': instance.toolContext,
      'args': instance.toolArgs,
      'tool_call_id': instance.toolCallId,
      'tool_calls': instance.toolCalls,
      'token_count': instance.tokenCount,
      'finish_reason': instance.finishReason,
    };

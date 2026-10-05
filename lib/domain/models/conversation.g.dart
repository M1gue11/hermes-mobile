// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Nova conversa',
      preview: json['preview'] as String? ?? '',
      model: json['model'] as String?,
      provider: json['provider'] as String?,
      lastActive: apiTimestampFromJson(json['last_active']),
      startedAt: apiTimestampFromJson(json['started_at']),
      messageCount: json['message_count'] as num? ?? 0,
      toolCallCount: json['tool_call_count'] as num? ?? 0,
      source: json['source'] as String?,
      parentSessionId: json['parent_session_id'] as String?,
      endReason: json['end_reason'] as String?,
      inputTokens: json['input_tokens'] as num? ?? 0,
      outputTokens: json['output_tokens'] as num? ?? 0,
      estimatedCostUsd: json['estimated_cost_usd'] as num?,
      actualCostUsd: json['actual_cost_usd'] as num?,
    );

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'preview': instance.preview,
      'model': instance.model,
      'provider': instance.provider,
      'last_active': apiTimestampToJson(instance.lastActive),
      'started_at': apiTimestampToJson(instance.startedAt),
      'message_count': instance.messageCount,
      'tool_call_count': instance.toolCallCount,
      'source': instance.source,
      'parent_session_id': instance.parentSessionId,
      'end_reason': instance.endReason,
      'input_tokens': instance.inputTokens,
      'output_tokens': instance.outputTokens,
      'estimated_cost_usd': instance.estimatedCostUsd,
      'actual_cost_usd': instance.actualCostUsd,
    };

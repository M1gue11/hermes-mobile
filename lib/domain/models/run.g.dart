// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Usage _$UsageFromJson(Map<String, dynamic> json) => _Usage(
  inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
  outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
  totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UsageToJson(_Usage instance) => <String, dynamic>{
  'input_tokens': instance.inputTokens,
  'output_tokens': instance.outputTokens,
  'total_tokens': instance.totalTokens,
};

_Run _$RunFromJson(Map<String, dynamic> json) => _Run(
  runId: json['run_id'] as String,
  status:
      $enumDecodeNullable(
        _$RunStatusEnumMap,
        json['status'],
        unknownValue: RunStatus.unknown,
      ) ??
      RunStatus.unknown,
  sessionId: json['session_id'] as String?,
  model: json['model'] as String?,
  output: json['output'] as String?,
  error: json['error'] as String?,
  usage: json['usage'] == null
      ? null
      : Usage.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RunToJson(_Run instance) => <String, dynamic>{
  'run_id': instance.runId,
  'status': _$RunStatusEnumMap[instance.status]!,
  'session_id': instance.sessionId,
  'model': instance.model,
  'output': instance.output,
  'error': instance.error,
  'usage': instance.usage,
};

const _$RunStatusEnumMap = {
  RunStatus.started: 'started',
  RunStatus.queued: 'queued',
  RunStatus.running: 'running',
  RunStatus.inProgress: 'in_progress',
  RunStatus.stopping: 'stopping',
  RunStatus.completed: 'completed',
  RunStatus.failed: 'failed',
  RunStatus.cancelled: 'cancelled',
  RunStatus.unknown: 'unknown',
};

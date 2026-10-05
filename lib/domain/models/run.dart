import 'package:freezed_annotation/freezed_annotation.dart';

part 'run.freezed.dart';
part 'run.g.dart';

/// Estados de uma run. Os terminais documentados são completed/failed/cancelled;
/// os demais cobrem o ciclo de vida (started na criação, stopping após stop).
/// `unknown` é o fallback para qualquer string não reconhecida vinda do servidor.
enum RunStatus {
  @JsonValue('started')
  started,
  @JsonValue('queued')
  queued,
  @JsonValue('running')
  running,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('stopping')
  stopping,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  unknown,
}

/// Contagem de tokens retornada pela run.
@freezed
abstract class Usage with _$Usage {
  const factory Usage({
    @JsonKey(name: 'input_tokens') @Default(0) int inputTokens,
    @JsonKey(name: 'output_tokens') @Default(0) int outputTokens,
    @JsonKey(name: 'total_tokens') @Default(0) int totalTokens,
  }) = _Usage;

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);
}

/// Uma execução de agente (`GET /v1/runs/{run_id}`). Usada para reconciliar o
/// estado da conversa em reconexão/reload.
@freezed
abstract class Run with _$Run {
  const Run._();

  const factory Run({
    @JsonKey(name: 'run_id') required String runId,
    @JsonKey(unknownEnumValue: RunStatus.unknown)
    @Default(RunStatus.unknown)
    RunStatus status,
    @JsonKey(name: 'session_id') String? sessionId,
    String? model,
    String? output,
    String? error,
    Usage? usage,
  }) = _Run;

  factory Run.fromJson(Map<String, dynamic> json) => _$RunFromJson(json);

  /// Estados finais: não haverá mais eventos.
  bool get isTerminal =>
      status == RunStatus.completed ||
      status == RunStatus.failed ||
      status == RunStatus.cancelled;

  /// Ainda em andamento (mostrar barra de streaming / botão cancelar).
  bool get isActive =>
      status == RunStatus.started ||
      status == RunStatus.queued ||
      status == RunStatus.running ||
      status == RunStatus.inProgress;
}

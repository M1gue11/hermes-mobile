import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_health.freezed.dart';

/// Fase do gateway, resolvida de `gateway_state` do `/api/status`.
enum GatewayPhase {
  running,
  starting,
  degraded,
  draining,
  stopping,
  stopped,
  failed,
  unknown,
}

/// Estado do processo do gateway, lido de `GET /api/status` do Dashboard.
///
/// O Dashboard avulso (porta 9119) segue de pé quando o gateway reinicia; é
/// por ele que o app acompanha a volta. O servidor não informa tempo de
/// atividade do gateway, só o instante da última mudança de estado.
@freezed
abstract class GatewayRuntime with _$GatewayRuntime {
  const GatewayRuntime._();

  const factory GatewayRuntime({
    @Default(false) bool running,
    String? state,
    DateTime? updatedAt,
    String? exitReason,
    @Default(0) int activeSessions,
    @Default(0) int activeAgents,

    /// Há turno em andamento: reiniciar agora interrompe alguém.
    @Default(false) bool busy,

    /// Versão do Dashboard que respondeu.
    String? version,
    int? platformsConnected,
    int? platformsConfigured,
  }) = _GatewayRuntime;

  GatewayPhase get phase => switch (state) {
    'running' => GatewayPhase.running,
    'starting' => GatewayPhase.starting,
    'degraded' => GatewayPhase.degraded,
    'draining' => GatewayPhase.draining,
    'stopping' => GatewayPhase.stopping,
    'stopped' => GatewayPhase.stopped,
    'startup_failed' => GatewayPhase.failed,
    _ => running ? GatewayPhase.running : GatewayPhase.unknown,
  };

  /// Voltou de um reinício pedido quando o gateway estava em [before]: rodando
  /// e com um estado gravado depois daquele. Compara dois instantes do
  /// servidor, nunca o relógio do celular. Sem `updated_at` dos dois lados,
  /// quem chama precisa ter visto o gateway fora do ar ([sawDown]).
  bool settledSince(GatewayRuntime before, {required bool sawDown}) {
    if (phase != GatewayPhase.running) return false;
    final antes = before.updatedAt;
    final agora = updatedAt;
    if (antes != null && agora != null) return agora.isAfter(antes);
    return sawDown;
  }
}

/// Medidas da máquina do servidor, de `GET /api/system/stats`.
///
/// Cada medida pode faltar: o servidor sem `psutil` só manda a identificação,
/// e cada sonda que falha some sozinha.
@freezed
abstract class HostStats with _$HostStats {
  const factory HostStats({
    String? hostname,
    String? hermesVersion,
    double? cpuPercent,
    double? memoryPercent,
    int? memoryUsedBytes,
    int? memoryTotalBytes,
    double? diskPercent,
    int? diskUsedBytes,
    int? diskTotalBytes,

    /// Tempo desde o boot da máquina, não do gateway.
    int? uptimeSeconds,
  }) = _HostStats;
}

/// Uma verificação de prontidão do API Server (`state_db`, `model`, `disk`…).
@freezed
abstract class ReadinessCheck with _$ReadinessCheck {
  const ReadinessCheck._();

  const factory ReadinessCheck({
    required String name,
    required String status,
    String? detail,
  }) = _ReadinessCheck;

  bool get ok => status == 'ok';
}

/// Prontidão e uso do dia do API Server, de `GET /health/detailed` (Bearer).
@freezed
abstract class ServerReadiness with _$ServerReadiness {
  const ServerReadiness._();

  const factory ServerReadiness({
    @Default('unknown') String status,
    @Default(<ReadinessCheck>[]) List<ReadinessCheck> checks,
    String? version,
    @Default(0) int activeRuns,
    int? requestsToday,
    int? tokensToday,
    int? latencyP95Ms,
  }) = _ServerReadiness;

  bool get ok => status == 'ok';

  List<ReadinessCheck> get failing => [
    for (final check in checks)
      if (!check.ok) check,
  ];
}

/// Andamento de uma ação do Dashboard, de `GET /api/actions/{name}/status`.
///
/// `exitCode` zero só diz que o reinício foi entregue ao sistema, não que o
/// gateway voltou; depois de um reinício o Dashboard pode também ter perdido o
/// registro em memória e devolver `exitCode` nulo.
@freezed
abstract class GatewayActionStatus with _$GatewayActionStatus {
  const factory GatewayActionStatus({
    @Default(false) bool running,
    int? exitCode,
    @Default(<String>[]) List<String> lines,
  }) = _GatewayActionStatus;
}

/// Arquivos de log que o app oferece. O servidor tem outros (`gui`,
/// `desktop`, `update`…), que não dizem respeito ao gateway.
enum GatewayLogFile {
  agent('agent'),
  errors('errors'),
  gateway('gateway');

  const GatewayLogFile(this.wire);
  final String wire;
}

/// Nível mínimo do filtro de `/api/logs`. O servidor só reconhece maiúsculas;
/// qualquer outro valor vira "sem filtro".
enum GatewayLogLevel {
  all('ALL'),
  info('INFO'),
  warning('WARNING'),
  error('ERROR');

  const GatewayLogLevel(this.wire);
  final String wire;
}

/// Uma entrada de log já separada para leitura.
///
/// O servidor devolve linhas cruas (`2026-11-02 10:00:01,123 INFO nome:
/// mensagem`). Linha sem carimbo, como um quadro de traceback, continua o
/// registro anterior: [continuation] liga as duas na tela.
typedef LogLine = ({
  String raw,
  DateTime? at,
  String? level,
  String? source,
  String message,
  bool continuation,
});

final _logHeader = RegExp(
  r'^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})(?:,(\d{1,3}))? '
  r'(DEBUG|INFO|WARNING|ERROR|CRITICAL)(?: \[[^\]]*\])? ([^:\s]+): ?(.*)$',
  dotAll: true,
);

/// Um registro de log com as linhas de continuação já coladas.
typedef LogEntry = ({
  DateTime? at,
  String? level,
  String? source,
  String message,
});

/// Junta as linhas cruas (em ordem cronológica) em registros. Uma linha sem
/// carimbo antes de qualquer registro vira registro próprio, sem nível.
List<LogEntry> logEntriesFrom(Iterable<String> lines) {
  final entries = <LogEntry>[];
  for (final raw in lines) {
    final line = parseLogLine(raw);
    if (line.continuation && entries.isNotEmpty) {
      final last = entries.removeLast();
      entries.add((
        at: last.at,
        level: last.level,
        source: last.source,
        message: '${last.message}\n${line.message}',
      ));
      continue;
    }
    entries.add((
      at: line.at,
      level: line.level,
      source: line.source,
      message: line.message,
    ));
  }
  return entries;
}

LogLine parseLogLine(String raw) {
  final line = raw.endsWith('\n') ? raw.substring(0, raw.length - 1) : raw;
  final match = _logHeader.firstMatch(line);
  if (match == null) {
    return (
      raw: line,
      at: null,
      level: null,
      source: null,
      message: line,
      continuation: true,
    );
  }
  final millis = (match[3] ?? '0').padRight(3, '0');
  return (
    raw: line,
    at: DateTime.tryParse('${match[1]}T${match[2]}.$millis'),
    level: match[4],
    source: match[5],
    message: match[6] ?? '',
    continuation: false,
  );
}

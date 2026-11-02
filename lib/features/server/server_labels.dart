import '../../domain/models/server_health.dart';

String gatewayPhaseLabel(GatewayPhase phase) => switch (phase) {
  GatewayPhase.running => 'Gateway rodando',
  GatewayPhase.starting => 'Gateway subindo',
  GatewayPhase.degraded => 'Gateway com falhas',
  GatewayPhase.draining => 'Gateway encerrando turnos',
  GatewayPhase.stopping => 'Gateway parando',
  GatewayPhase.stopped => 'Gateway parado',
  GatewayPhase.failed => 'Gateway não subiu',
  GatewayPhase.unknown => 'Estado desconhecido',
};

/// Linha de medida sob o estado: sessões, turnos e plataformas.
String gatewayRuntimeMeta(GatewayRuntime runtime) {
  final partes = <String>[
    switch (runtime.activeSessions) {
      0 => 'nenhuma sessão',
      1 => '1 sessão',
      final n => '$n sessões',
    },
    switch (runtime.activeAgents) {
      0 => 'nenhum turno em andamento',
      1 => '1 turno em andamento',
      final n => '$n turnos em andamento',
    },
    if (runtime.platformsConfigured case final total? when total > 0)
      '${runtime.platformsConnected ?? 0} de $total plataformas',
  ];
  return partes.join(' · ');
}

/// Nome legível de uma verificação de prontidão do API Server.
String readinessCheckLabel(String name) => switch (name) {
  'state_db' => 'Banco de sessões',
  'session_store' => 'Armazenamento de sessões',
  'config' => 'Configuração',
  'model' => 'Modelo',
  'disk' => 'Disco',
  'gateway' => 'Gateway',
  'background_queues' => 'Filas em segundo plano',
  _ => name.replaceAll('_', ' '),
};

/// Bytes em unidades decimais, como o sistema operacional mostra o disco.
String byteLabel(int bytes) {
  const unidades = ['B', 'KB', 'MB', 'GB', 'TB'];
  var valor = bytes.toDouble();
  var i = 0;
  while (valor >= 1000 && i < unidades.length - 1) {
    valor /= 1000;
    i++;
  }
  final texto = valor >= 100 || i == 0
      ? valor.round().toString()
      : valor.toStringAsFixed(1).replaceAll('.', ',');
  return '$texto ${unidades[i]}';
}

String uptimeLabel(int seconds) {
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays} d ${d.inHours % 24} h';
  if (d.inHours > 0) return '${d.inHours} h ${d.inMinutes % 60} min';
  return '${d.inMinutes} min';
}

/// Contagem curta: 38.200 vira 38,2 mil.
String compactCount(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) {
    return '${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  }
  return '${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
}

String latencyLabel(int millis) => millis < 1000
    ? '$millis ms'
    : '${(millis / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';

import '../../domain/models/cron_job.dart';
import '../../domain/models/hermes_failure.dart';

const _months = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

/// Momento curto de uma rotina: `hoje 09:00`, `amanhã 07:30`, `3 nov 09:00`.
String jobMomentLabel(DateTime when, DateTime now) {
  final local = when.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final days = day.difference(today).inDays;
  final date = switch (days) {
    0 => 'hoje',
    1 => 'amanhã',
    -1 => 'ontem',
    _ =>
      '${local.day} ${_months[local.month - 1]}'
          '${local.year == now.year ? '' : ' ${local.year}'}',
  };
  return '$date $time';
}

/// Linha de situação da rotina na lista.
String jobStatusLabel(CronJob job, DateTime now) => switch (job.status) {
  CronJobStatus.running => 'Rodando agora',
  CronJobStatus.scheduled => switch (job.nextRunAt) {
    final next? => 'Próxima: ${jobMomentLabel(next, now)}',
    null => 'Ativa',
  },
  CronJobStatus.paused => 'Pausada',
  CronJobStatus.completed => 'Concluída',
  CronJobStatus.failed => 'Agenda com erro',
};

/// Resultado da última execução, ou nulo antes da primeira.
String? jobLastRunLabel(CronJob job, DateTime now) {
  final last = job.lastRunAt;
  if (last == null) return null;
  final result = switch (job.lastStatus) {
    'ok' => 'ok',
    'error' => 'falhou',
    'delivery_failed' => 'entrega falhou',
    'cancelled' => 'cancelada',
    final other? => other,
    null => null,
  };
  final moment = jobMomentLabel(last, now);
  return result == null ? 'Última: $moment' : 'Última: $moment · $result';
}

/// O servidor sem o módulo de cron responde `501`.
bool jobsUnavailable(Object? error) =>
    error is HermesFailure && error.statusCode == 501;

/// Causa de uma recusa do servidor, com a mensagem dele quando existe.
String jobFailureText(Object error) {
  final failure = hermesFailureFrom(error);
  final message = failure.serverMessage?.trim();
  return message == null || message.isEmpty ? failure.title : message;
}

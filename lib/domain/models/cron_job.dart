import 'package:freezed_annotation/freezed_annotation.dart';

part 'cron_job.freezed.dart';

/// Situação de uma rotina, já resolvida para a interface.
enum CronJobStatus { running, scheduled, paused, completed, failed }

/// Rotina agendada do agente, lida de `/api/jobs` do API Server.
///
/// No servidor, pausar grava `enabled: false` e `state: paused`; `completed` e
/// `error` são terminais (uma execução única que já rodou, ou agenda que não
/// calcula a próxima data).
@freezed
abstract class CronJob with _$CronJob {
  const CronJob._();

  const factory CronJob({
    required String id,
    required String name,
    @Default('') String prompt,

    /// Agenda como o servidor a descreve (`every 30m`, `0 9 * * *`).
    @Default('') String schedule,
    @Default(true) bool enabled,
    @Default('scheduled') String state,
    String? pausedReason,
    DateTime? nextRunAt,
    DateTime? lastRunAt,

    /// `ok`, `error`, `delivery_failed`, `cancelled` ou nulo antes da primeira.
    String? lastStatus,
    String? lastError,

    /// Há uma execução reivindicada ou rodando agora.
    @Default(false) bool running,
    int? repeatTimes,
    @Default(0) int repeatCompleted,
  }) = _CronJob;

  CronJobStatus get status {
    if (running) return CronJobStatus.running;
    return switch (state) {
      'paused' => CronJobStatus.paused,
      'completed' => CronJobStatus.completed,
      'error' => CronJobStatus.failed,
      _ => enabled ? CronJobStatus.scheduled : CronJobStatus.paused,
    };
  }

  /// Disparar uma rotina pausada a reativa no servidor, então só é oferecido
  /// para as ativas.
  bool get canRunNow => status == CronJobStatus.scheduled;

  bool get canPause => status == CronJobStatus.scheduled;

  bool get canResume => status == CronJobStatus.paused;
}

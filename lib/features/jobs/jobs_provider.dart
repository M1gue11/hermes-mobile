import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/cron_job.dart';

part 'jobs_provider.g.dart';

/// Rotinas agendadas do agente (A95), das que rodam ou vão rodar primeiro
/// para as pausadas e encerradas.
@riverpod
Future<List<CronJob>> cronJobs(Ref ref) async {
  final jobs = await ref.watch(hermesRepositoryProvider).jobs();
  return List<CronJob>.of(jobs)..sort(_byRelevance);
}

int _byRelevance(CronJob a, CronJob b) {
  final byStatus = a.status.index.compareTo(b.status.index);
  if (byStatus != 0) return byStatus;
  final aNext = a.nextRunAt;
  final bNext = b.nextRunAt;
  if (aNext != null && bNext != null && aNext != bNext) {
    return aNext.compareTo(bNext);
  }
  if ((aNext == null) != (bNext == null)) return aNext == null ? 1 : -1;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Mutações de rotinas. Mantém REST fora dos widgets e atualiza a lista.
@Riverpod(keepAlive: true)
class CronJobActions extends _$CronJobActions {
  @override
  FutureOr<void> build() {}

  Future<CronJob> create({
    required String name,
    required String schedule,
    required String prompt,
  }) async {
    final job = await ref
        .read(hermesRepositoryProvider)
        .createJob(name: name, schedule: schedule, prompt: prompt);
    ref.invalidate(cronJobsProvider);
    return job;
  }

  Future<void> pause(String id) =>
      _mutate(() => ref.read(hermesRepositoryProvider).pauseJob(id));

  Future<void> resume(String id) =>
      _mutate(() => ref.read(hermesRepositoryProvider).resumeJob(id));

  Future<void> runNow(String id) =>
      _mutate(() => ref.read(hermesRepositoryProvider).runJobNow(id));

  Future<void> delete(String id) =>
      _mutate(() => ref.read(hermesRepositoryProvider).deleteJob(id));

  Future<void> _mutate(Future<Object?> Function() call) async {
    await call();
    ref.invalidate(cronJobsProvider);
  }
}

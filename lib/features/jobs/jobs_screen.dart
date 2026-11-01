import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/code_surface.dart';
import '../../core/widgets/failure_state.dart';
import '../../core/widgets/hermes_sheet.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../domain/models/cron_job.dart';
import '../../domain/models/hermes_failure.dart';
import 'job_labels.dart';
import 'jobs_provider.dart';

/// Rotinas agendadas do agente (A95), pelo API Server.
class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final jobs = ref.watch(cronJobsProvider);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Agendamentos',
                  subtitle: 'ROTINAS QUE O AGENTE EXECUTA SOZINHO',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('jobs-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: () => ref.invalidate(cronJobsProvider),
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                    if (!jobsUnavailable(jobs.error))
                      IconButton(
                        key: const ValueKey('jobs-new'),
                        tooltip: 'Nova rotina',
                        onPressed: () => context.push('/jobs/new'),
                        icon: Icon(Icons.add_rounded, size: 23, color: t.ink),
                      ),
                  ],
                ),
                Expanded(
                  child: switch (jobs) {
                    AsyncValue(:final value?) => _JobsList(jobs: value),
                    AsyncError(:final error) when jobsUnavailable(error) =>
                      const _JobsMessage(
                        key: ValueKey('jobs-unavailable'),
                        icon: Icons.event_busy_outlined,
                        title: 'Agendamentos indisponíveis',
                        body:
                            'Este servidor não tem o módulo de agendamentos '
                            'ativo.',
                      ),
                    AsyncError(:final error) => FailureState(
                      failure: hermesFailureFrom(error),
                      keyPrefix: 'jobs',
                      onRetry: () => ref.invalidate(cronJobsProvider),
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsList extends ConsumerWidget {
  const _JobsList({required this.jobs});

  final List<CronJob> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    if (jobs.isEmpty) {
      return const _JobsMessage(
        key: ValueKey('jobs-empty'),
        icon: Icons.schedule_outlined,
        title: 'Nenhuma rotina agendada',
        body:
            'Crie uma rotina para o agente executar um pedido sozinho, '
            'de tempos em tempos ou numa data marcada.',
      );
    }
    final now = DateTime.now();
    return RefreshIndicator(
      color: t.accent,
      backgroundColor: t.bg2,
      onRefresh: () => ref.refresh(cronJobsProvider.future),
      child: ListView.separated(
        key: const ValueKey('jobs-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        itemCount: jobs.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: t.line),
        itemBuilder: (context, index) => _JobRow(job: jobs[index], now: now),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.now});

  final CronJob job;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final inactive =
        job.status == CronJobStatus.paused ||
        job.status == CronJobStatus.completed;
    final failed =
        job.status == CronJobStatus.failed || job.lastStatus == 'error';
    final status = jobStatusLabel(job, now);
    return Semantics(
      button: true,
      label: '${job.name}. ${job.schedule}. $status. Abrir detalhes.',
      child: InkWell(
        key: ValueKey('job-row-${job.id}'),
        onTap: () => _showJobDetails(context, job),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  switch (job.status) {
                    CronJobStatus.running => Icons.play_circle_outline,
                    CronJobStatus.paused => Icons.pause_circle_outline,
                    CronJobStatus.completed => Icons.check_circle_outline,
                    CronJobStatus.failed => Icons.error_outline,
                    CronJobStatus.scheduled => Icons.schedule_outlined,
                  },
                  size: 19,
                  color: switch (job.status) {
                    CronJobStatus.running => t.positive,
                    CronJobStatus.failed => t.accentInk,
                    _ when inactive => t.faint,
                    _ => t.dim,
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: t
                          .serifIn(FontWeight.w500)
                          .copyWith(
                            fontSize: 16,
                            color: inactive ? t.dim : t.ink,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.schedule,
                      style: t.mono.copyWith(fontSize: 11, color: t.dim),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status,
                      style: t.serif.copyWith(
                        fontSize: 13.5,
                        color: job.status == CronJobStatus.failed
                            ? t.accentInk
                            : t.dim,
                      ),
                    ),
                    if (jobLastRunLabel(job, now) case final last?)
                      Text(
                        last,
                        style: t.serif.copyWith(
                          fontSize: 13,
                          color: failed ? t.accentInk : t.faint,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: t.faint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobsMessage extends StatelessWidget {
  const _JobsMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: t.faint),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t
                  .serifIn(FontWeight.w500)
                  .copyWith(fontSize: 18, color: t.ink),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showJobDetails(BuildContext context, CronJob job) =>
    showHermesSheet(
      context,
      title: job.name,
      tag: '',
      child: _JobDetails(jobId: job.id),
    );

/// Detalhe e ações de uma rotina. Lê a rotina do provider para refletir o
/// estado depois de cada ação.
class _JobDetails extends ConsumerStatefulWidget {
  const _JobDetails({required this.jobId});

  final String jobId;

  @override
  ConsumerState<_JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends ConsumerState<_JobDetails> {
  var _busy = false;
  String? _error;

  Future<void> _act(
    Future<void> Function(CronJobActions actions) action,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(cronJobActionsProvider.notifier));
    } catch (error) {
      if (mounted) setState(() => _error = jobFailureText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CronJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir rotina?'),
        content: Text(
          '“${job.name}” deixa de rodar e some da lista. Isso não pode ser '
          'desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('job-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _act((actions) => actions.delete(job.id));
    if (mounted && _error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final job = ref
        .watch(cronJobsProvider)
        .value
        ?.where((item) => item.id == widget.jobId)
        .firstOrNull;
    if (job == null) {
      return Text(
        'Esta rotina não está mais na lista.',
        style: t.serif.copyWith(fontSize: 15, color: t.dim),
      );
    }
    final now = DateTime.now();
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.4, color: t.dim),
      ),
    );
    return Column(
      key: ValueKey('job-details-${job.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jobStatusLabel(job, now),
          style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
        ),
        if (job.pausedReason case final reason?)
          Text(reason, style: t.serif.copyWith(fontSize: 13, color: t.dim)),
        if (jobLastRunLabel(job, now) case final last?)
          Text(last, style: t.serif.copyWith(fontSize: 13, color: t.dim)),
        if (job.lastError case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error,
              style: t.serif.copyWith(fontSize: 13, color: t.accentInk),
            ),
          ),
        const SizedBox(height: 18),
        label('AGENDA'),
        SelectableText(
          job.schedule,
          style: t.mono.copyWith(fontSize: 12, color: t.ink),
        ),
        if (job.repeatTimes case final times?) ...[
          const SizedBox(height: 4),
          Text(
            '${job.repeatCompleted} de $times execuções',
            style: t.serif.copyWith(fontSize: 13, color: t.dim),
          ),
        ],
        const SizedBox(height: 18),
        label('PEDIDO'),
        CodeSurface(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              job.prompt.isEmpty ? '(sem pedido)' : job.prompt,
              style: t.mono.copyWith(fontSize: 11.5, height: 1.5, color: t.ink),
            ),
          ),
        ),
        if (_error case final error?)
          Padding(
            key: const ValueKey('job-action-error'),
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              error,
              style: t.serif.copyWith(fontSize: 14, color: t.accentInk),
            ),
          ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (job.canRunNow)
              FilledButton.icon(
                key: const ValueKey('job-run'),
                onPressed: _busy
                    ? null
                    : () => _act((actions) => actions.runNow(job.id)),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Executar agora'),
              ),
            if (job.canPause)
              OutlinedButton.icon(
                key: const ValueKey('job-pause'),
                onPressed: _busy
                    ? null
                    : () => _act((actions) => actions.pause(job.id)),
                icon: const Icon(Icons.pause_rounded, size: 18),
                label: const Text('Pausar'),
              ),
            if (job.canResume)
              FilledButton.icon(
                key: const ValueKey('job-resume'),
                onPressed: _busy
                    ? null
                    : () => _act((actions) => actions.resume(job.id)),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Retomar'),
              ),
            TextButton.icon(
              key: const ValueKey('job-delete'),
              onPressed: _busy ? null : () => _delete(job),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Excluir'),
            ),
          ],
        ),
      ],
    );
  }
}

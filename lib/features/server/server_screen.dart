import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_radius.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../core/widgets/unicode_spinner.dart';
import '../../domain/models/server_health.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'server_labels.dart';
import 'server_provider.dart';

/// Saúde do servidor (A97): estado do gateway, prontidão do API Server,
/// medidas da máquina, logs e reinício.
class ServerScreen extends ConsumerWidget {
  const ServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    void atualizar() => ref
      ..invalidate(gatewayRuntimeProvider)
      ..invalidate(serverReadinessProvider)
      ..invalidate(hostStatsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Servidor',
                  subtitle: 'SAÚDE, LOGS E REINÍCIO DO GATEWAY',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('server-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: atualizar,
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: t.accent,
                    backgroundColor: t.bg2,
                    onRefresh: () async {
                      atualizar();
                      await ref
                          .read(serverReadinessProvider.future)
                          .catchError((_) => const ServerReadiness());
                    },
                    child: ListView(
                      key: const ValueKey('server-list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
                      children: const [
                        _RuntimeHeader(),
                        SizedBox(height: 30),
                        _ReadinessSection(),
                        SizedBox(height: 30),
                        _HostSection(),
                        SizedBox(height: 30),
                        _LogsLink(),
                        SizedBox(height: 30),
                        _RestartPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(HermesTokens t, String label) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(
    label.toUpperCase(),
    style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.6, color: t.faint),
  ),
);

/// Mensagem curta de seção que não carregou. A seção some do resto da tela
/// sem levar as outras junto.
Widget _sectionNote(HermesTokens t, String text, {Key? key}) => Text(
  text,
  key: key,
  style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
);

String _dashboardMotivo(Object error) => switch (error) {
  StateError() => 'Conecte o Dashboard para ver o estado do gateway.',
  GatewayAuthenticationRequired() => 'Entre no Dashboard para ver o gateway.',
  GatewayOperationException(:final message) => message,
  _ => 'Não foi possível ler o Dashboard.',
};

class _RuntimeHeader extends ConsumerWidget {
  const _RuntimeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final runtime = ref.watch(gatewayRuntimeProvider);
    final restart = ref.watch(gatewayRestartProvider);
    final reiniciando = switch (restart.stage) {
      RestartStage.requesting ||
      RestartStage.stopping ||
      RestartStage.starting => true,
      _ => false,
    };

    final (titulo, meta, cor, vivo) = switch (runtime) {
      _ when reiniciando => (
        'Gateway reiniciando',
        'acompanhando a volta pelo Dashboard',
        t.accent,
        true,
      ),
      AsyncData(:final value) => (
        gatewayPhaseLabel(value.phase),
        gatewayRuntimeMeta(value),
        switch (value.phase) {
          GatewayPhase.running => t.positive,
          GatewayPhase.degraded || GatewayPhase.failed => t.accentInk,
          GatewayPhase.stopped || GatewayPhase.unknown => t.faint,
          _ => t.accent,
        },
        switch (value.phase) {
          GatewayPhase.starting ||
          GatewayPhase.stopping ||
          GatewayPhase.draining => true,
          _ => false,
        },
      ),
      AsyncError(:final error) => (
        'Gateway sem leitura',
        _dashboardMotivo(error),
        t.faint,
        false,
      ),
      _ => ('Lendo o gateway…', '', t.faint, false),
    };

    return Semantics(
      key: const ValueKey('server-runtime'),
      container: true,
      liveRegion: true,
      label: meta.isEmpty ? titulo : '$titulo. $meta',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(color: cor, live: vivo),
              const SizedBox(width: 11),
              Flexible(
                child: AnimatedSwitcher(
                  duration: motionOf(context, HermesMotion.estado),
                  child: Text(
                    titulo,
                    key: ValueKey(titulo),
                    style: t
                        .serifIn(FontWeight.w500)
                        .copyWith(fontSize: 23, height: 1.25, color: t.ink),
                  ),
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                meta,
                style: t.serif.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: t.dim,
                ),
              ),
            ),
          ],
          if (runtime.value case GatewayRuntime(
            :final exitReason?,
          ) when exitReason.isNotEmpty && !reiniciando) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                exitReason,
                style: t.mono.copyWith(fontSize: 11, color: t.accentInk),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ponto de estado. Só pulsa enquanto algo está mudando, e nunca para quem
/// pediu menos movimento.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.live});

  final Color color;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final dot = AnimatedContainer(
      duration: motionOf(context, HermesMotion.estado),
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (!live || reduceMotionOf(context)) return dot;
    return dot
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(
          begin: 1,
          end: 0.35,
          duration: HermesMotion.tinta,
          curve: HermesMotion.curvaPadrao,
        );
  }
}

class _ReadinessSection extends ConsumerWidget {
  const _ReadinessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final readiness = ref.watch(serverReadinessProvider);
    return Column(
      key: const ValueKey('server-readiness'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(t, 'API Server'),
        switch (readiness) {
          AsyncData(:final value) => _ReadinessBody(readiness: value),
          AsyncError() => _sectionNote(
            t,
            'O API Server não respondeu. Durante um reinício isso é '
            'esperado por alguns segundos.',
          ),
          _ => _sectionNote(t, 'Lendo…'),
        },
      ],
    );
  }
}

class _ReadinessBody extends StatelessWidget {
  const _ReadinessBody({required this.readiness});

  final ServerReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final uso = [
      if (readiness.requestsToday case final n?) '${compactCount(n)} pedidos',
      if (readiness.tokensToday case final n?) '${compactCount(n)} tokens',
      if (readiness.latencyP95Ms case final ms?) 'p95 ${latencyLabel(ms)}',
    ];
    final falhas = readiness.failing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          readiness.ok
              ? 'Pronto para atender'
              : falhas.isEmpty
              ? 'Estado incerto'
              : falhas.length == 1
              ? '1 verificação com problema'
              : '${falhas.length} verificações com problema',
          style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
        ),
        if (uso.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Hoje: ${uso.join(' · ')}',
            style: t.mono.copyWith(fontSize: 11, height: 1.5, color: t.dim),
          ),
        ],
        if (readiness.activeRuns > 0) ...[
          const SizedBox(height: 2),
          Text(
            readiness.activeRuns == 1
                ? '1 execução em andamento'
                : '${readiness.activeRuns} execuções em andamento',
            style: t.mono.copyWith(fontSize: 11, color: t.dim),
          ),
        ],
        const SizedBox(height: 10),
        for (final check in readiness.checks) _CheckRow(check: check),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final ReadinessCheck check;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              check.ok
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              size: 16,
              color: check.ok ? t.positive : t.accentInk,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              readinessCheckLabel(check.name),
              style: t.serif.copyWith(fontSize: 14, color: t.ink),
            ),
          ),
          const SizedBox(width: 12),
          // O rótulo fica com a largura; o estado só ocupa o que precisa,
          // até um teto para um `detail` longo não empurrar o nome.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              check.ok ? 'ok' : (check.detail ?? check.status),
              textAlign: TextAlign.end,
              style: t.mono.copyWith(
                fontSize: 11,
                color: check.ok ? t.faint : t.accentInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostSection extends ConsumerWidget {
  const _HostSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final stats = ref.watch(hostStatsProvider);
    return Column(
      key: const ValueKey('server-host'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(t, 'Máquina'),
        switch (stats) {
          AsyncData(:final value) => _HostBody(stats: value),
          // O motivo de não haver Dashboard já está no topo da tela.
          AsyncError(:final error) => _sectionNote(
            t,
            error is StateError || error is GatewayAuthenticationRequired
                ? 'Aparece com o Dashboard conectado.'
                : _dashboardMotivo(error),
          ),
          _ => _sectionNote(t, 'Lendo…'),
        },
      ],
    );
  }
}

class _HostBody extends StatelessWidget {
  const _HostBody({required this.stats});

  final HostStats stats;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    String? capacidade(int? usado, int? total) => usado != null && total != null
        ? '${byteLabel(usado)} de ${byteLabel(total)}'
        : null;
    final identificacao = [
      ?stats.hostname,
      if (stats.hermesVersion case final v?) 'Hermes $v',
      if (stats.uptimeSeconds case final s?) 'ligada há ${uptimeLabel(s)}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (identificacao.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              identificacao.join(' · '),
              style: t.mono.copyWith(fontSize: 11, height: 1.5, color: t.dim),
            ),
          ),
        if (stats.cpuPercent case final cpu?)
          _Meter(label: 'Processador', percent: cpu),
        if (stats.memoryPercent case final memoria?)
          _Meter(
            label: 'Memória',
            percent: memoria,
            detail: capacidade(stats.memoryUsedBytes, stats.memoryTotalBytes),
          ),
        if (stats.diskPercent case final disco?)
          _Meter(
            label: 'Disco do Hermes',
            percent: disco,
            detail: capacidade(stats.diskUsedBytes, stats.diskTotalBytes),
          ),
        if (stats.cpuPercent == null &&
            stats.memoryPercent == null &&
            stats.diskPercent == null)
          _sectionNote(t, 'O servidor não mede uso de recursos (sem psutil).'),
      ],
    );
  }
}

/// Medida de capacidade com filete proporcional. Acima de 90% o filete sai do
/// neutro: é o ponto em que vale agir.
class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.percent, this.detail});

  final String label;
  final double percent;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final fracao = (percent / 100).clamp(0.0, 1.0);
    final alto = percent >= 90;
    return Semantics(
      label:
          '$label: ${percent.round()} por cento${detail == null ? '' : ', $detail'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: t.serif.copyWith(fontSize: 14, color: t.ink),
                  ),
                ),
                if (detail case final detail?)
                  Text(
                    '$detail  ',
                    style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
                  ),
                Text(
                  '${percent.round()}%',
                  style: t.mono.copyWith(
                    fontSize: 11.5,
                    color: alto ? t.accentInk : t.dim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: t.line)),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: fracao),
                      duration: motionOf(context, HermesMotion.revelar),
                      curve: HermesMotion.curvaChegada,
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value,
                        child: ColoredBox(color: alto ? t.accentInk : t.dim),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsLink extends StatelessWidget {
  const _LogsLink();

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(t, 'Logs'),
        InkWell(
          key: const ValueKey('server-logs'),
          onTap: () => context.push('/server/logs'),
          borderRadius: HermesRadius.todos(HermesRadius.cartao),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 19, color: t.dim),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ler os logs',
                        style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
                      ),
                      Text(
                        'Agente, erros e gateway, com filtro e busca',
                        style: t.serif.copyWith(fontSize: 13, color: t.dim),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 19, color: t.faint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RestartPanel extends ConsumerWidget {
  const _RestartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final restart = ref.watch(gatewayRestartProvider);
    final runtime = ref.watch(gatewayRuntimeProvider).value;
    final semDashboard = ref.watch(gatewayRuntimeProvider).hasError;

    final corpo = switch (restart.stage) {
      RestartStage.idle => Column(
        key: const ValueKey('restart-idle'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interrompe os turnos em andamento e deixa o API Server fora do '
            'ar por alguns segundos. O Dashboard continua de pé e o app '
            'acompanha a volta.',
            style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('server-restart'),
            onPressed: semDashboard
                ? null
                : () => _confirmarReinicio(context, ref, runtime),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reiniciar gateway'),
          ),
        ],
      ),
      RestartStage.done => _RestartOutcome(
        key: const ValueKey('restart-done'),
        icon: Icons.check_circle_outline_rounded,
        color: t.positive,
        text: restart.took == null
            ? 'Gateway de volta.'
            : 'Gateway de volta em ${restart.took!.inSeconds} s.',
        onDismiss: () => ref.read(gatewayRestartProvider.notifier).dismiss(),
      ),
      RestartStage.failed => _RestartOutcome(
        key: const ValueKey('restart-failed'),
        icon: Icons.error_outline_rounded,
        color: t.accentInk,
        text: restart.message ?? 'O reinício falhou.',
        onDismiss: () => ref.read(gatewayRestartProvider.notifier).dismiss(),
      ),
      _ => _RestartProgress(
        key: const ValueKey('restart-progress'),
        stage: restart.stage,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(t, 'Reiniciar'),
        AnimatedSize(
          duration: motionOf(context, HermesMotion.revelar),
          curve: HermesMotion.curvaPadrao,
          alignment: Alignment.topLeft,
          child: AnimatedSwitcher(
            duration: motionOf(context, HermesMotion.estado),
            child: corpo,
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmarReinicio(
  BuildContext context,
  WidgetRef ref,
  GatewayRuntime? runtime,
) async {
  final ocupado = runtime?.busy == true || (runtime?.activeAgents ?? 0) > 0;
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reiniciar o gateway?'),
      content: Text(
        ocupado
            ? 'Há turno em andamento agora: ele será interrompido. O API '
                  'Server fica fora do ar até o gateway voltar.'
            : 'O API Server fica fora do ar até o gateway voltar, '
                  'normalmente alguns segundos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('server-restart-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Reiniciar'),
        ),
      ],
    ),
  );
  if (confirmado == true) {
    await ref.read(gatewayRestartProvider.notifier).restart();
  }
}

/// Etapas do reinício como um trilho curto. Só a etapa viva se mexe; as
/// concluídas trocam o símbolo no lugar.
class _RestartProgress extends StatelessWidget {
  const _RestartProgress({super.key, required this.stage});

  final RestartStage stage;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    const etapas = [
      (RestartStage.requesting, 'Pedido enviado ao servidor'),
      (RestartStage.stopping, 'Gateway parando'),
      (RestartStage.starting, 'Gateway subindo'),
    ];
    final atual = etapas.indexWhere((etapa) => etapa.$1 == stage);
    return Semantics(
      liveRegion: true,
      label: etapas[atual].$2,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < etapas.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: Center(
                      child: i < atual
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: t.positive,
                            )
                          : i == atual
                          ? UnicodeSpinner(
                              name: 'helix',
                              size: 16,
                              color: t.accentInk,
                              glow: t.accent,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              size: 9,
                              color: t.faint,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    etapas[i].$2,
                    style: t.serif.copyWith(
                      fontSize: 14.5,
                      color: i <= atual ? t.ink : t.faint,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RestartOutcome extends StatelessWidget {
  const _RestartOutcome({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                text,
                style: t.serif.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: t.ink,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('restart-dismiss'),
            tooltip: 'Fechar aviso',
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 18, color: t.dim),
          ),
        ],
      ),
    );
  }
}

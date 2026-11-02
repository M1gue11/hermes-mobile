import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/quantities.dart';
import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/hermes_chip.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../domain/models/usage_summary.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'usage_provider.dart';

const _meses = [
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

String _diaCurto(DateTime day) => '${day.day} ${_meses[day.month - 1]}';

/// Tokens e custo por período (A98), de todas as origens do servidor.
class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  var _dias = 30;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final usage = ref.watch(usageSummaryProvider(_dias));
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Uso',
                  subtitle: 'TOKENS E CUSTO DE TODAS AS ORIGENS',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('usage-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: () =>
                          ref.invalidate(usageSummaryProvider(_dias)),
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                  child: Row(
                    children: [
                      for (final dias in usagePeriods) ...[
                        if (dias != usagePeriods.first)
                          const SizedBox(width: 7),
                        HermesChip(
                          key: ValueKey('usage-period-$dias'),
                          label: '$dias dias',
                          selected: _dias == dias,
                          minTapHeight: 48,
                          onTap: () => setState(() => _dias = dias),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: switch (usage) {
                    AsyncValue(:final value?) => _UsageBody(
                      key: ValueKey('usage-body-${value.periodDays}'),
                      usage: value,
                      onRefresh: () =>
                          ref.refresh(usageSummaryProvider(_dias).future),
                    ),
                    AsyncError(:final error) => _UsageMessage(
                      text: switch (error) {
                        StateError() =>
                          'Conecte o Dashboard para ver o uso do servidor.',
                        GatewayAuthenticationRequired() =>
                          'Entre no Dashboard para ver o uso.',
                        GatewayOperationException(:final message) => message,
                        _ => 'Não foi possível ler o uso.',
                      },
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

class _UsageBody extends StatelessWidget {
  const _UsageBody({super.key, required this.usage, required this.onRefresh});

  final UsageSummary usage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    if (usage.empty) {
      return _UsageMessage(
        key: const ValueKey('usage-empty'),
        text: 'Nenhuma sessão nos últimos ${usage.periodDays} dias.',
      );
    }
    final custoReal = usage.actualCost > 0;
    final custo = custoReal ? usage.actualCost : usage.estimatedCost;
    // Provedor por assinatura não registra custo: aí o número que conta é o
    // de tokens, e um "US$ 0" grande só enganaria.
    final semCusto = custo <= 0;
    final sessoes = usage.sessions == 1
        ? '1 sessão'
        : '${usage.sessions} sessões';
    // A quebra por modelo inclui chamadas auxiliares (compressão, visão) que
    // os totais não contam; a fatia de cada um é sobre a soma dos modelos.
    final tokensDosModelos = usage.byModel.fold<int>(0, (s, m) => s + m.tokens);
    return RefreshIndicator(
      color: t.accent,
      backgroundColor: t.bg2,
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('usage-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 44),
        children: [
          Text(
            semCusto ? '${compactCount(usage.tokens)} tokens' : usdLabel(custo),
            key: const ValueKey('usage-cost'),
            style: t
                .serifIn(FontWeight.w500)
                .copyWith(fontSize: 34, height: 1.1, color: t.ink),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (semCusto)
                'sem custo registrado pelo provedor'
              else ...[
                custoReal ? 'custo cobrado' : 'custo estimado',
                if (custoReal && usage.estimatedCost > 0)
                  'estimado ${usdLabel(usage.estimatedCost)}',
                '${compactCount(usage.tokens)} tokens',
              ],
              sessoes,
            ].join(' · '),
            style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
          ),
          const SizedBox(height: 28),
          _DailyBars(series: usage.dailySeries(DateTime.now())),
          const SizedBox(height: 30),
          _label(t, 'Tokens'),
          _ValueRow(label: 'Entrada', value: compactCount(usage.inputTokens)),
          _ValueRow(label: 'Saída', value: compactCount(usage.outputTokens)),
          if (usage.cacheReadTokens > 0)
            _ValueRow(
              label: 'Lidos do cache',
              value: compactCount(usage.cacheReadTokens),
            ),
          if (usage.reasoningTokens > 0)
            _ValueRow(
              label: 'Raciocínio',
              value: compactCount(usage.reasoningTokens),
            ),
          if (usage.apiCalls > 0)
            _ValueRow(
              label: 'Chamadas ao provedor',
              value: compactCount(usage.apiCalls),
            ),
          if (usage.byModel.isNotEmpty) ...[
            const SizedBox(height: 30),
            _label(t, 'Por modelo'),
            for (final model in usage.byModel)
              _ModelRow(
                model: model,
                share: tokensDosModelos == 0
                    ? 0
                    : model.tokens / tokensDosModelos,
              ),
          ],
        ],
      ),
    );
  }
}

Widget _label(HermesTokens t, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text.toUpperCase(),
    style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.6, color: t.faint),
  ),
);

/// Tokens por dia, uma barra por dia do período.
///
/// Uma série só: o título nomeia a medida e não há legenda. Tocar ou arrastar
/// sobre as barras escolhe o dia e mostra os números dele na linha de cima;
/// o alvo é a coluna inteira do dia, não só a barra.
class _DailyBars extends StatefulWidget {
  const _DailyBars({required this.series});

  final List<UsageDay> series;

  @override
  State<_DailyBars> createState() => _DailyBarsState();
}

class _DailyBarsState extends State<_DailyBars> {
  static const _altura = 132.0;
  int? _escolhido;

  void _escolher(double dx, double largura) {
    final n = widget.series.length;
    final i = (dx / largura * n).floor().clamp(0, n - 1);
    if (i != _escolhido) setState(() => _escolhido = i);
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final series = widget.series;
    final maximo = series.fold<int>(0, (m, d) => math.max(m, d.tokens));
    final escolhido = _escolhido == null ? null : series[_escolhido!];
    final legenda = escolhido == null
        ? 'Tokens por dia · máximo ${compactCount(maximo)}'
        : [
            _diaCurto(escolhido.day),
            '${compactCount(escolhido.tokens)} tokens',
            if (escolhido.cost > 0) usdLabel(escolhido.cost),
            escolhido.sessions == 1
                ? '1 sessão'
                : '${escolhido.sessions} sessões',
          ].join(' · ');
    // Barras de 90 dias ficam com ~3 px: o raio não pode passar da metade.
    final gap = series.length > 60 ? 1.0 : 2.0;

    return Column(
      key: const ValueKey('usage-daily'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: Text(
            legenda,
            key: const ValueKey('usage-daily-caption'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.mono.copyWith(
              fontSize: 11,
              color: escolhido == null ? t.faint : t.ink,
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final largura = constraints.maxWidth;
            final raio = math.min(4.0, (largura / series.length - gap) / 2);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _escolher(d.localPosition.dx, largura),
              onHorizontalDragUpdate: (d) =>
                  _escolher(d.localPosition.dx, largura),
              child: SizedBox(
                height: _altura,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(height: 1, color: t.line),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < series.length; i++)
                          Expanded(
                            child: Semantics(
                              label:
                                  '${_diaCurto(series[i].day)}: '
                                  '${compactCount(series[i].tokens)} tokens'
                                  '${series[i].cost > 0 ? ', ${usdLabel(series[i].cost)}' : ''}',
                              selected: _escolhido == i,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: gap / 2,
                                ),
                                child: _Bar(
                                  fraction: maximo == 0
                                      ? 0
                                      : series[i].tokens / maximo,
                                  radius: math.max(0, raio),
                                  color: _escolhido == i
                                      ? t.accent
                                      : _escolhido == null
                                      ? t.dim
                                      : t.dim.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _diaCurto(series.first.day),
              style: t.mono.copyWith(fontSize: 10, color: t.faint),
            ),
            const Spacer(),
            Text('hoje', style: t.mono.copyWith(fontSize: 10, color: t.faint)),
          ],
        ),
      ],
    );
  }
}

/// Barra que sobe da linha de base quando o período chega. Dia com uso
/// mínimo ainda aparece com 2 px, para não confundir pouco com nada.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.radius,
    required this.color,
  });

  final double fraction;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (fraction <= 0) return const SizedBox.expand();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: motionOf(context, HermesMotion.revelar),
      curve: HermesMotion.curvaChegada,
      builder: (context, value, _) => LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: motionOf(context, HermesMotion.estado),
            width: double.infinity,
            height: math.max(2, constraints.maxHeight * value),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.serif.copyWith(fontSize: 14.5, color: t.ink),
            ),
          ),
          Text(value, style: t.mono.copyWith(fontSize: 11.5, color: t.dim)),
        ],
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.model, required this.share});

  final ModelUsage model;
  final double share;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final detalhe = [
      '${compactCount(model.tokens)} tokens',
      if (model.estimatedCost > 0) usdLabel(model.estimatedCost),
      model.sessions == 1 ? '1 sessão' : '${model.sessions} sessões',
    ].join(' · ');
    return Semantics(
      label: '${model.model}: $detalhe, ${(share * 100).round()} por cento',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    model.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.mono.copyWith(fontSize: 12, color: t.ink),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(share * 100).round()}%',
                  style: t.mono.copyWith(fontSize: 11.5, color: t.dim),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              detalhe,
              style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: t.line)),
                    FractionallySizedBox(
                      widthFactor: share.clamp(0.0, 1.0),
                      child: ColoredBox(color: t.dim),
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

class _UsageMessage extends StatelessWidget {
  const _UsageMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: t.serif.copyWith(fontSize: 15, height: 1.45, color: t.dim),
        ),
      ),
    );
  }
}

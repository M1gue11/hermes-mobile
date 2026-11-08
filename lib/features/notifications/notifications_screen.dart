import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../domain/models/push_device.dart';
import 'push_controller.dart';

final _ntfyApps = Uri.parse('https://ntfy.sh/docs/subscribe/phone/');

/// Nome que a pessoa reconhece para o pacote do distribuidor.
String distributorLabel(String package) => switch (package) {
  'io.heckel.ntfy' => 'ntfy',
  final other when other.startsWith('io.heckel.ntfy') => 'ntfy',
  final other => other.split('.').last,
};

String testOutcome(PushTestResult result) => switch (result) {
  (gone: true, ok: _, status: _, encrypted: _) =>
    'O endereço deste aparelho expirou. Registrando de novo.',
  (ok: true, gone: _, status: _, encrypted: _) =>
    'Teste enviado. O aviso deve aparecer em alguns segundos.',
  (status: 0, ok: _, gone: _, encrypted: _) =>
    'O Hermes não alcançou o servidor ntfy.',
  (:final status, ok: _, gone: _, encrypted: _) =>
    'O servidor ntfy respondeu $status.',
};

/// Avisos do agente com o app fechado (A60): turno concluído ou com erro, e
/// aprovação, pergunta ou sudo esperando. Cada elo da entrega aparece com o
/// próprio estado, para a pessoa saber qual consertar.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final state = ref.watch(pushControllerProvider);
    final controller = ref.read(pushControllerProvider.notifier);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Notificações',
                  subtitle: 'AVISOS DO AGENTE NESTE APARELHO',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('push-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: () => unawaited(controller.refreshServer()),
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                  ],
                ),
                Expanded(
                  child: state.phase == PushPhase.loading
                      ? const Center(child: CircularProgressIndicator())
                      : _Body(state: state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final PushSetupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final controller = ref.read(pushControllerProvider.notifier);
    final note = t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim);

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: t.mono.copyWith(
          fontSize: 10,
          letterSpacing: 1.6,
          color: t.faint,
        ),
      ),
    );

    return ListView(
      key: const ValueKey('push-list'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
      children: [
        Text(
          'Avisa quando o agente termina um turno, falha ou espera sua '
          'aprovação, mesmo com o app fechado. O aviso diz só o que aconteceu '
          'e em qual conversa; o conteúdo continua no app.',
          style: note,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Receber avisos',
                style: t
                    .serifIn(FontWeight.w500)
                    .copyWith(fontSize: 16.5, color: t.ink),
              ),
            ),
            Switch(
              key: const ValueKey('push-switch'),
              value: state.enabled,
              activeThumbColor: t.bg,
              activeTrackColor: t.accent,
              onChanged: state.busy
                  ? null
                  : (on) => unawaited(
                      on ? controller.enable() : controller.disable(),
                    ),
            ),
          ],
        ),
        if (state.permissionDenied)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'O Android bloqueou as notificações do Hermes. Libere em '
              'Configurações › Apps › Hermes › Notificações e tente de novo.',
              key: const ValueKey('push-permission'),
              style: note.copyWith(color: t.accentInk),
            ),
          ),
        AnimatedSize(
          duration: motionOf(context, HermesMotion.revelar),
          curve: HermesMotion.curvaPadrao,
          alignment: Alignment.topCenter,
          child: state.enabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    label('Entrega'),
                    _StatusLine(
                      title: 'Distribuidor',
                      value: switch (state.distributor) {
                        final d? => distributorLabel(d),
                        _ when state.phase == PushPhase.needsDistributor =>
                          'nenhum instalado',
                        _ => 'não escolhido',
                      },
                      ok: state.distributor != null,
                    ),
                    _StatusLine(
                      title: 'Servidor ntfy',
                      value: state.endpointHost ?? 'sem endereço ainda',
                      ok: state.endpointHost != null,
                    ),
                    _StatusLine(
                      title: 'Plugin no Hermes',
                      value: switch (state.pluginAvailable) {
                        true when state.synced =>
                          'mobile-push, aparelho registrado',
                        true => 'mobile-push ativo',
                        false => 'não encontrado',
                        null => 'não verificado',
                      },
                      ok: state.pluginAvailable == true && state.synced,
                    ),
                    if (state.pluginAvailable == true)
                      _StatusLine(
                        title: 'Conteúdo',
                        value: state.serverEncryption
                            ? 'cifrado até o aparelho'
                            : 'legível pelo servidor ntfy',
                        ok: state.serverEncryption,
                      ),
                    const SizedBox(height: 18),
                    _PhaseDetail(state: state),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.title,
    required this.value,
    required this.ok,
  });

  final String title;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              ok ? Icons.check_rounded : Icons.remove_rounded,
              size: 15,
              color: ok ? t.accent : t.faint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: t.serif.copyWith(fontSize: 15, color: t.ink),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: t.mono.copyWith(
                fontSize: 11.5,
                height: 1.5,
                color: ok ? t.dim : t.faint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseDetail extends ConsumerWidget {
  const _PhaseDetail({required this.state});

  final PushSetupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final controller = ref.read(pushControllerProvider.notifier);
    final note = t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim);
    final busy = state.busy;
    final error = state.error;

    final children = <Widget>[
      if (error != null)
        Text(
          error,
          key: const ValueKey('push-error'),
          style: note.copyWith(color: t.accentInk),
        ),
      ...switch (state.phase) {
        PushPhase.needsDistributor => [
          Text(
            'O Hermes recebe avisos pelo app ntfy, que mantém a conexão com o '
            'seu servidor. Instale o ntfy, aponte o servidor padrão dele para a '
            'sua instância e volte aqui.',
            style: note,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('push-install-ntfy'),
                onPressed: () => unawaited(
                  launchUrl(_ntfyApps, mode: LaunchMode.externalApplication),
                ),
                child: const Text('Instalar o ntfy'),
              ),
              OutlinedButton(
                key: const ValueKey('push-retry'),
                onPressed: busy ? null : () => unawaited(controller.enable()),
                child: const Text('Já instalei'),
              ),
            ],
          ),
        ],
        PushPhase.choosingDistributor => [
          Text('Qual app deve entregar os avisos?', style: note),
          const SizedBox(height: 6),
          for (final distributor in state.distributors)
            ListTile(
              key: ValueKey('push-distributor-$distributor'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                distributorLabel(distributor),
                style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
              ),
              subtitle: Text(
                distributor,
                style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
              ),
              onTap: busy
                  ? null
                  : () => unawaited(controller.chooseDistributor(distributor)),
            ),
        ],
        PushPhase.registering => [
          Text('Registrando este aparelho…', style: note),
        ],
        PushPhase.failed when state.pluginAvailable == false => [
          Text(
            'O plugin mobile-push não respondeu no Hermes. No host do '
            'servidor, copie a pasta server/mobile-push deste repositório para '
            '~/.hermes/plugins/, rode “hermes plugins enable mobile-push” e '
            'reinicie o gateway e o dashboard.',
            key: const ValueKey('push-plugin-missing'),
            style: note,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('push-retry'),
            onPressed: busy ? null : () => unawaited(controller.retry()),
            child: const Text('Tentar de novo'),
          ),
        ],
        PushPhase.failed => [
          const SizedBox(height: 4),
          OutlinedButton(
            key: const ValueKey('push-retry'),
            onPressed: busy ? null : () => unawaited(controller.retry()),
            child: const Text('Tentar de novo'),
          ),
        ],
        PushPhase.active => [
          Text(
            'Pronto. Com a conversa aberta na tela, o aviso dela não aparece.',
            style: note,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('push-test'),
            onPressed: busy ? null : () => unawaited(controller.sendTest()),
            child: const Text('Enviar aviso de teste'),
          ),
          if (state.lastTest case final result?)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                testOutcome(result),
                key: const ValueKey('push-test-result'),
                style: note,
              ),
            ),
        ],
        PushPhase.loading || PushPhase.off => const <Widget>[],
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: child),
      ],
    );
  }
}

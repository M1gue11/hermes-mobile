import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../domain/models/platform_pairing.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'pairing_provider.dart';

String _motivo(Object error) => switch (error) {
  StateError() => 'Conecte o Dashboard para ver os pedidos de acesso.',
  GatewayAuthenticationRequired() => 'Entre no Dashboard para continuar.',
  GatewayOperationException(:final message) => message,
  _ => 'Não foi possível falar com o Dashboard.',
};

String _nome(String userName, String userId) =>
    userName.trim().isNotEmpty ? userName.trim() : 'Pessoa sem nome';

String _idade(int minutes) => switch (minutes) {
  < 1 => 'agora',
  < 60 => 'há $minutes min',
  < 1440 => 'há ${minutes ~/ 60} h',
  _ => 'há ${minutes ~/ 1440} d',
};

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

/// Quem conversa com o agente por plataformas de mensagem (A101).
///
/// Aprovar é dar a uma pessoa de fora acesso ao agente; por isso cada ação
/// pede confirmação dizendo exatamente o que libera ou tira.
class PairingScreen extends ConsumerWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final pairing = ref.watch(pairingProvider);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Acessos',
                  subtitle: 'QUEM CONVERSA COM O AGENTE POR MENSAGEM',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('pairing-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: () => ref.invalidate(pairingProvider),
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                  ],
                ),
                Expanded(
                  child: switch (pairing) {
                    AsyncValue(:final value?) => RefreshIndicator(
                      color: t.accent,
                      backgroundColor: t.bg2,
                      onRefresh: () => ref.refresh(pairingProvider.future),
                      child: _PairingList(state: value),
                    ),
                    AsyncError(:final error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          _motivo(error),
                          textAlign: TextAlign.center,
                          style: t.serif.copyWith(
                            fontSize: 15,
                            height: 1.45,
                            color: t.dim,
                          ),
                        ),
                      ),
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

class _PairingList extends ConsumerWidget {
  const _PairingList({required this.state});

  final PairingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    Widget label(String text, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: t.mono.copyWith(
                fontSize: 10,
                letterSpacing: 1.6,
                color: t.faint,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    Widget nota(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
      ),
    );

    return ListView(
      key: const ValueKey('pairing-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
      children: [
        Text(
          'Quem manda mensagem ao agente por uma plataforma recebe um código '
          'e aparece aqui. Aprovar dá a essa pessoa acesso ao agente.',
          style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
        ),
        const SizedBox(height: 24),
        label(
          state.pending.isEmpty
              ? 'Pedindo acesso'
              : 'Pedindo acesso · ${state.pending.length}',
          trailing: state.pending.isEmpty
              ? null
              : TextButton(
                  key: const ValueKey('pairing-clear'),
                  onPressed: () => _confirmar(
                    context,
                    ref,
                    titulo: 'Recusar todos os pedidos?',
                    corpo:
                        'Os ${state.pending.length} pedidos somem; quem '
                        'quiser acesso precisa pedir de novo.',
                    acao: 'Recusar todos',
                    executar: (actions) => actions.clearPending(),
                  ),
                  child: Text(
                    'Recusar todos',
                    style: t.mono.copyWith(fontSize: 11, color: t.accentInk),
                  ),
                ),
        ),
        AnimatedSize(
          duration: motionOf(context, HermesMotion.revelar),
          curve: HermesMotion.curvaPadrao,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.pending.isEmpty) nota('Nenhum pedido pendente.'),
              for (final request in state.pending)
                _RequestRow(
                  key: ValueKey(
                    'pairing-request-${request.platform}-${request.requestId}-${request.userId}',
                  ),
                  request: request,
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        label('Com acesso'),
        AnimatedSize(
          duration: motionOf(context, HermesMotion.revelar),
          curve: HermesMotion.curvaPadrao,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.approved.isEmpty) nota('Ninguém aprovado ainda.'),
              for (final user in state.approved)
                _ApprovedRow(
                  key: ValueKey('pairing-user-${user.platform}-${user.userId}'),
                  user: user,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmar(
  BuildContext context,
  WidgetRef ref, {
  required String titulo,
  required String corpo,
  required String acao,
  required Future<void> Function(PairingActions actions) executar,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(corpo),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('pairing-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(acao),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await executar(ref.read(pairingActionsProvider));
    unawaited(HapticFeedback.selectionClick());
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(_motivo(error))));
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({super.key, required this.request});

  final PairingRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final nome = _nome(request.userName, request.userId);
    final plataforma = platformLabel(request.platform);
    final meta = [
      plataforma,
      if (request.userId.isNotEmpty) 'id ${request.userId}',
      _idade(request.ageMinutes),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: t
                      .serifIn(FontWeight.w500)
                      .copyWith(fontSize: 16.5, color: t.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
                ),
                if (!request.canApprove)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Pedido antigo: aprove pelo código no computador.',
                      style: t.serif.copyWith(fontSize: 13, color: t.dim),
                    ),
                  ),
              ],
            ),
          ),
          if (request.canApprove) ...[
            const SizedBox(width: 12),
            FilledButton(
              key: ValueKey('pairing-approve-${request.requestId}'),
              onPressed: () => _confirmar(
                context,
                ref,
                titulo: 'Dar acesso a $nome?',
                corpo:
                    '$nome poderá conversar com o agente pelo $plataforma e '
                    'usar as ferramentas liberadas para essa plataforma. Dá '
                    'para revogar depois, nesta tela.',
                acao: 'Aprovar',
                executar: (actions) => actions.approve(request),
              ),
              child: const Text('Aprovar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApprovedRow extends ConsumerWidget {
  const _ApprovedRow({super.key, required this.user});

  final PairedUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final nome = _nome(user.userName, user.userId);
    final plataforma = platformLabel(user.platform);
    final desde = user.approvedAt;
    final meta = [
      plataforma,
      'id ${user.userId}',
      if (desde != null) 'desde ${desde.day} ${_meses[desde.month - 1]}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
                ),
              ],
            ),
          ),
          TextButton(
            key: ValueKey('pairing-revoke-${user.userId}'),
            onPressed: () => _confirmar(
              context,
              ref,
              titulo: 'Revogar o acesso de $nome?',
              corpo:
                  '$nome deixa de conversar com o agente pelo $plataforma. '
                  'Para voltar, precisa pedir acesso de novo.',
              acao: 'Revogar',
              executar: (actions) => actions.revoke(user),
            ),
            child: Text(
              'Revogar',
              style: t.mono.copyWith(fontSize: 11, color: t.accentInk),
            ),
          ),
        ],
      ),
    );
  }
}

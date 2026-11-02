import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/hermes_motion.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/unicode_spinner.dart';
import '../../../data/gateway_repository_provider.dart';
import '../../../domain/repositories/gateway_repository.dart';
import '../read_aloud_controller.dart';

/// "Ouvir" no rodapé da resposta, ao lado das cópias (A102).
///
/// Só aparece com o Dashboard pareado, que é quem sintetiza. Enquanto gera o
/// áudio mostra a marca; tocando, vira "parar" na cor de ação.
class ReadAloudAction extends ConsumerWidget {
  const ReadAloudAction({
    super.key,
    required this.messageId,
    required this.markdown,
  });

  final String messageId;
  final String markdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      ref.watch(gatewayRepositoryProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final t = HermesTokens.of(context);
    final estado = ref.watch(readAloudProvider);
    final fase = estado?.messageId == messageId ? estado!.phase : null;

    Future<void> alternar() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(readAloudProvider.notifier).toggle(messageId, markdown);
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(switch (error) {
              GatewayAuthenticationRequired() =>
                'Entre no Dashboard para ouvir a resposta.',
              GatewayOperationException(:final message) =>
                'Não foi possível gerar o áudio: $message',
              _ => 'Não foi possível tocar o áudio.',
            }),
          ),
        );
      }
    }

    final cor = fase == ReadAloudPhase.playing ? t.accent : t.faint;
    final rotulo = switch (fase) {
      ReadAloudPhase.synthesizing => 'GERANDO ÁUDIO',
      ReadAloudPhase.playing => 'PARAR',
      null => 'OUVIR',
    };
    return Semantics(
      button: true,
      label: switch (fase) {
        ReadAloudPhase.synthesizing =>
          'Gerando áudio da resposta. Toque para cancelar.',
        ReadAloudPhase.playing => 'Parar a leitura da resposta',
        null => 'Ouvir a resposta',
      },
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('ouvir-resposta'),
        onTap: alternar,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 13,
                child: AnimatedSwitcher(
                  duration: motionOf(context, HermesMotion.estado),
                  child: switch (fase) {
                    ReadAloudPhase.synthesizing => UnicodeSpinner(
                      key: const ValueKey('sintetizando'),
                      name: 'helix',
                      size: 12,
                      color: t.accentInk,
                      glow: t.accent,
                    ),
                    ReadAloudPhase.playing => Icon(
                      Icons.stop_rounded,
                      key: const ValueKey('tocando'),
                      size: 13,
                      color: cor,
                    ),
                    null => Icon(
                      Icons.volume_up_outlined,
                      key: const ValueKey('parado'),
                      size: 13,
                      color: cor,
                    ),
                  },
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: motionOf(context, HermesMotion.estado),
                style: t.mono.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.4,
                  color: cor,
                ),
                child: Text(rotulo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

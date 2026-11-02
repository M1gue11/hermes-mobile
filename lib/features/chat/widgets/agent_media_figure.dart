import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/hermes_motion.dart';
import '../../../core/theme/hermes_radius.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../domain/models/agent_media.dart';
import '../../../domain/repositories/gateway_repository.dart';
import '../agent_media_provider.dart';
import 'image_viewer.dart';

/// Altura máxima de uma figura na conversa. Uma captura de celular em pé
/// inteira empurraria o resto da resposta para fora da tela; o detalhe fica
/// para o visualizador.
const _alturaMaxima = 440.0;

/// Arquivo que o agente entregou com `MEDIA:<caminho>`.
///
/// Imagem desenhável vira figura, lida pelo Dashboard. O resto (PDF, SVG,
/// imagem sem Dashboard ou recusada pelo servidor) vira referência com o nome,
/// sem quebrar a mensagem. Enquanto [ready] é falso o caminho ainda pode estar
/// chegando pelo streaming, e nada é pedido ao servidor.
class AgentMediaFigure extends ConsumerStatefulWidget {
  const AgentMediaFigure({super.key, required this.path, this.ready = true});

  final String path;
  final bool ready;

  @override
  ConsumerState<AgentMediaFigure> createState() => _AgentMediaFigureState();
}

class _AgentMediaFigureState extends ConsumerState<AgentMediaFigure> {
  /// A mesma imagem pode aparecer duas vezes numa conversa; o Hero precisa de
  /// uma marca por figura, não por caminho.
  final _heroTag = Object();

  @override
  Widget build(BuildContext context) {
    final name = mediaFileName(widget.path);
    if (!widget.ready) {
      return MediaNotice(
        icon: Icons.image_outlined,
        text: 'Recebendo arquivo…',
        framed: true,
      );
    }
    if (!isInlineImagePath(widget.path)) {
      return MediaReference(
        icon: Icons.insert_drive_file_outlined,
        title: name,
        note: 'Arquivo no servidor',
        path: widget.path,
      );
    }

    final media = ref.watch(agentMediaProvider(widget.path));
    final corpo = switch (media) {
      AsyncData(:final value) => _figura(context, value, name),
      AsyncError(:final error) => MediaReference(
        key: const ValueKey('agent-media-unavailable'),
        icon: Icons.broken_image_outlined,
        title: name,
        note: _motivo(error),
        path: widget.path,
        onRetry: _tentarDeNovo(error)
            ? () => ref.invalidate(agentMediaProvider(widget.path))
            : null,
      ),
      _ => const MediaNotice(
        key: ValueKey('agent-media-loading'),
        icon: Icons.image_outlined,
        text: 'Carregando imagem…',
        framed: true,
      ),
    };
    return AnimatedSize(
      duration: motionOf(context, HermesMotion.revelar),
      curve: HermesMotion.curvaPadrao,
      alignment: Alignment.topLeft,
      child: corpo,
    );
  }

  Widget _figura(BuildContext context, Uint8List bytes, String name) {
    final image = MemoryImage(bytes);
    final rotulo = 'Imagem do agente: $name';
    final figura = MediaFigure(
      key: const ValueKey('agent-media-image'),
      image: image,
      heroTag: _heroTag,
      semanticLabel: rotulo,
      caption: name,
      onOpen: () => openImageViewer(
        context,
        image: image,
        heroTag: _heroTag,
        semanticLabel: rotulo,
        caption: widget.path,
      ),
    );
    if (reduceMotionOf(context)) return figura;
    // A imagem revela como a tinta do agente assenta: desfoque saindo junto
    // com a opacidade, uma vez, quando os bytes chegam.
    return figura
        .animate()
        .fadeIn(duration: HermesMotion.tinta, curve: HermesMotion.curvaTinta)
        .blurXY(
          begin: 6,
          end: 0,
          duration: HermesMotion.tinta,
          curve: HermesMotion.curvaTinta,
        );
  }
}

String _motivo(Object error) => switch (error) {
  StateError() => 'Conecte o Dashboard para ver a imagem.',
  GatewayAuthenticationRequired() => 'Entre no Dashboard para ver a imagem.',
  GatewayOperationException(:final message) => message,
  _ => 'Não foi possível carregar a imagem.',
};

/// Recusas do servidor por caminho, tipo ou tamanho não mudam tentando de
/// novo; falha de rede e de sessão podem mudar.
bool _tentarDeNovo(Object error) => switch (error) {
  StateError() => false,
  GatewayOperationException(:final httpStatus?) => httpStatus >= 500,
  _ => true,
};

/// Imagem emoldurada que abre o visualizador ao toque.
///
/// `.hmd img{max-width:100%;border-radius:11px;border:1px solid var(--line)}`
class MediaFigure extends StatelessWidget {
  const MediaFigure({
    super.key,
    required this.image,
    required this.heroTag,
    required this.semanticLabel,
    required this.onOpen,
    this.caption,
  });

  final ImageProvider image;
  final Object heroTag;
  final String semanticLabel;
  final VoidCallback onOpen;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TapScale(
            onTap: onOpen,
            tooltip: 'Ampliar imagem',
            borderRadius: HermesRadius.todos(HermesRadius.bloco),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: t.line),
                borderRadius: HermesRadius.todos(HermesRadius.bloco),
              ),
              clipBehavior: Clip.antiAlias,
              constraints: const BoxConstraints(maxHeight: _alturaMaxima),
              child: Hero(
                tag: heroTag,
                child: Image(
                  image: image,
                  fit: BoxFit.contain,
                  semanticLabel: semanticLabel,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          if (caption case final caption?)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.mono.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 0.4,
                  color: t.faint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Linha de espera ou de falha no lugar de uma imagem.
class MediaNotice extends StatelessWidget {
  const MediaNotice({
    super.key,
    required this.icon,
    required this.text,
    this.framed = false,
  });

  final IconData icon;
  final String text;

  /// Ocupa a largura da figura que vai chegar, para a troca não pular.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final linha = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        mainAxisSize: framed ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: t.dim),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              text,
              style: t.mono.copyWith(fontSize: 11.5, color: t.dim),
            ),
          ),
        ],
      ),
    );
    if (!framed) return linha;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.line),
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      child: linha,
    );
  }
}

/// Arquivo do servidor que o app não desenha: nome, motivo e caminho, que
/// continua selecionável para quem quiser abri-lo na máquina.
class MediaReference extends StatelessWidget {
  const MediaReference({
    super.key,
    required this.icon,
    required this.title,
    required this.note,
    required this.path,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String note;
  final String path;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.fromLTRB(12, 10, onRetry == null ? 12 : 2, 10),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.line),
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: t.faint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.mono.copyWith(fontSize: 11.5, color: t.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: t.mono.copyWith(
                    fontSize: 10.5,
                    height: 1.35,
                    color: t.dim,
                  ),
                ),
                if (path != title) ...[
                  const SizedBox(height: 3),
                  Text(
                    path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.mono.copyWith(
                      fontSize: 10,
                      height: 1.35,
                      color: t.faint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry case final retry?)
            IconButton(
              key: const ValueKey('agent-media-retry'),
              tooltip: 'Tentar de novo',
              onPressed: retry,
              icon: Icon(Icons.refresh_rounded, size: 18, color: t.dim),
            ),
        ],
      ),
    );
  }
}

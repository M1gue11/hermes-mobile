import 'package:flutter/material.dart';

import '../../../core/theme/hermes_motion.dart';
import '../../../core/theme/hermes_tokens.dart';

/// Abre [image] em tela cheia, saindo da figura da conversa pelo [heroTag].
///
/// Pinça e toque duplo ampliam; arrastar para cima ou para baixo, sem zoom,
/// fecha. O botão Voltar do sistema fecha como qualquer rota.
Future<void> openImageViewer(
  BuildContext context, {
  required ImageProvider image,
  required Object heroTag,
  required String semanticLabel,
  String? caption,
}) {
  final duracao = motionOf(context, HermesMotion.superficie);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: duracao,
      reverseTransitionDuration: HermesMotion.saidaDe(duracao),
      pageBuilder: (context, animation, secondaryAnimation) => _ImageViewer(
        image: image,
        heroTag: heroTag,
        semanticLabel: semanticLabel,
        caption: caption,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: HermesMotion.curvaPadrao,
            ),
            child: child,
          ),
    ),
  );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({
    required this.image,
    required this.heroTag,
    required this.semanticLabel,
    this.caption,
  });

  final ImageProvider image;
  final Object heroTag;
  final String semanticLabel;
  final String? caption;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer>
    with SingleTickerProviderStateMixin {
  /// Distância ou velocidade a partir da qual soltar o arrasto fecha.
  static const _distanciaParaFechar = 120.0;
  static const _velocidadeParaFechar = 900.0;
  static const _zoomDuplo = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoom;
  Animation<Matrix4>? _zoomAnimacao;
  Offset _toqueDuplo = Offset.zero;

  double _arrasto = 0;
  bool _arrastando = false;
  bool _ampliada = false;

  @override
  void initState() {
    super.initState();
    _zoom = AnimationController(vsync: this)
      ..addListener(() {
        final animacao = _zoomAnimacao;
        if (animacao != null) _transform.value = animacao.value;
      });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _alternarZoom() {
    final alvo = _ampliada
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(
              -_toqueDuplo.dx * (_zoomDuplo - 1),
              -_toqueDuplo.dy * (_zoomDuplo - 1),
              0,
              1,
            )
            ..scaleByDouble(_zoomDuplo, _zoomDuplo, 1, 1));
    _zoomAnimacao = Matrix4Tween(
      begin: _transform.value,
      end: alvo,
    ).animate(CurvedAnimation(parent: _zoom, curve: HermesMotion.curvaPadrao));
    _zoom
      ..duration = motionOf(context, HermesMotion.superficie)
      ..forward(from: 0);
    setState(() => _ampliada = !_ampliada);
  }

  void _fimDaInteracao(ScaleEndDetails details) {
    final ampliada = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (!ampliada &&
        (_arrasto.abs() > _distanciaParaFechar ||
            details.velocity.pixelsPerSecond.dy.abs() >
                _velocidadeParaFechar)) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _ampliada = ampliada;
      _arrastando = false;
      _arrasto = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final volta = motionOf(context, HermesMotion.estado);
    final fundo = (1 - _arrasto.abs() / 400).clamp(0.35, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: fundo,
            duration: _arrastando ? Duration.zero : volta,
            child: ColoredBox(color: t.bg),
          ),
          GestureDetector(
            onDoubleTapDown: (details) => _toqueDuplo = details.localPosition,
            onDoubleTap: _alternarZoom,
            child: InteractiveViewer(
              transformationController: _transform,
              panEnabled: _ampliada,
              maxScale: 5,
              onInteractionUpdate: (details) {
                if (_ampliada || details.pointerCount != 1) return;
                setState(() {
                  _arrastando = true;
                  _arrasto += details.focalPointDelta.dy;
                });
              },
              onInteractionEnd: _fimDaInteracao,
              child: AnimatedContainer(
                duration: _arrastando ? Duration.zero : volta,
                curve: HermesMotion.curvaChegada,
                transform: Matrix4.translationValues(0, _arrasto, 0),
                alignment: Alignment.center,
                child: Center(
                  child: Hero(
                    tag: widget.heroTag,
                    child: Image(
                      image: widget.image,
                      fit: BoxFit.contain,
                      semanticLabel: widget.semanticLabel,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  key: const ValueKey('image-viewer-close'),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.close_rounded, color: t.ink),
                ),
              ),
            ),
          ),
          if (widget.caption case final caption?)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: _arrastando ? 0 : 1,
                  duration: volta,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.mono.copyWith(
                        fontSize: 10.5,
                        letterSpacing: 0.4,
                        color: t.dim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

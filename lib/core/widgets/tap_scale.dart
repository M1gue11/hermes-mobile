import 'package:flutter/material.dart';

import '../theme/hermes_motion.dart';

/// Resposta ao dedo, antes de a ação acontecer.
///
/// `design/Hermes.dc.html`, classe `.tap`:
/// `transition:transform .13s cubic-bezier(.2,.8,.2,1)` com
/// `.tap:active{transform:scale(.966)}`. **Todo** alvo tocável do protótipo
/// encolhe um fio sob o dedo.
///
/// Por que isso importa num telefone e não numa tela com mouse: o dedo cobre o
/// próprio alvo. Sem uma reação que aconteça **fora** da área tapada, não há
/// como saber que o toque foi registrado até a tela inteira mudar, e a pessoa
/// toca de novo. O encolhimento move a borda do alvo, que é justamente a parte
/// que o dedo não esconde.
///
/// Substitui o respingo do Material de propósito: este app é editorial e não
/// Material, e o respingo traz o desenho de outra família visual.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.semanticsLabel,
    this.pressedOverlayColor,
    this.borderRadius,
  });

  final Widget child;

  /// Nulo desabilita: sem gesto, sem encolhimento e sem papel de botão.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Vira também o nome do controle para leitor de tela, quando
  /// [semanticsLabel] não é dado.
  final String? tooltip;
  final String? semanticsLabel;

  /// Tinta curta sob o dedo, usada quando só a escala não basta para mostrar
  /// que uma superfície larga recebeu o toque.
  final Color? pressedOverlayColor;
  final BorderRadius? borderRadius;

  /// `.tap:active{transform:scale(.966)}`.
  static const double _pressionado = 0.966;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressionado = false;

  void _marcar(bool valor) {
    if (_pressionado == valor) return;
    setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onTap != null || widget.onLongPress != null;
    final rotulo = widget.semanticsLabel ?? widget.tooltip;

    Widget content = widget.child;
    if (widget.pressedOverlayColor != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: motionOf(context, HermesMotion.toque),
                  curve: HermesMotion.curvaToque,
                  color: _pressionado
                      ? widget.pressedOverlayColor
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget corpo = AnimatedScale(
      scale: _pressionado ? TapScale._pressionado : 1,
      duration: motionOf(context, HermesMotion.toque),
      curve: HermesMotion.curvaToque,
      child: content,
    );

    if (widget.tooltip != null) {
      corpo = Tooltip(message: widget.tooltip!, child: corpo);
    }

    return Semantics(
      button: habilitado ? true : null,
      enabled: habilitado ? true : null,
      label: rotulo,
      excludeSemantics: rotulo != null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        // Opaco para o gesto valer na caixa inteira, e não só onde há pixel
        // desenhado: a marca costuma ser menor que o alvo de toque.
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: habilitado ? (_) => _marcar(true) : null,
        onTapUp: habilitado ? (_) => _marcar(false) : null,
        onTapCancel: habilitado ? () => _marcar(false) : null,
        child: corpo,
      ),
    );
  }
}

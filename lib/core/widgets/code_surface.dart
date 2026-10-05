import 'package:flutter/material.dart';

import '../theme/hermes_radius.dart';
import '../theme/hermes_tokens.dart';

/// A superfície rebaixada onde este app mostra texto pré-formatado.
///
/// O design declara `.hmd pre{background:var(--codeBg);border:none;
/// border-radius:11px;box-shadow:inset 0 1px 5px rgba(0,0,0,.42)}`. Sem borda:
/// a profundidade vem do fundo rebaixado mais a sombra interna.
///
/// Existe como widget próprio porque há **dois** lugares assim, o bloco de
/// código do markdown e o conteúdo do anexo, e duas cópias da mesma sombra
/// divergem na primeira vez que uma delas for ajustada.
class CodeSurface extends StatelessWidget {
  const CodeSurface({
    super.key,
    required this.child,
    this.scale = 1,
    this.shadowKey,
  });

  final Widget child;
  final double scale;

  /// Chave da sombra, para o teste que fixa a altura dela poder achá-la.
  final Key? shadowKey;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.codeBg,
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      child: ClipRRect(
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
        child: Stack(
          children: [
            child,

            // Flutter não tem sombra interna, então o `inset 0 1px 5px` do
            // design é simulado por um degradê no topo.
            //
            // Tem de ter **altura fixa**. A primeira versão usava um degradê
            // sobre a caixa inteira com parada em 5.5% da altura, e num bloco
            // alto 5.5% viram uma faixa preta grossa em vez de sombra: era a
            // barra que o usuário reportou no A22. O `5px` do design é 5px, e
            // não uma fração da caixa.
            Positioned(
              key: shadowKey,
              top: 0,
              left: 0,
              right: 0,
              height: 6 * scale,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x6B000000), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/hermes_tokens.dart';

/// Fundo das telas: uma cor SÓLIDA e uniforme (o mesmo tom quente dos sheets de
/// configuração). Sem gradiente e sem textura de ruído - o usuário pediu o mais
/// simples e harmônico possível.
///
/// (Tentamos reproduzir o grão de papel do `feTurbulence` do design com ruído
/// gerado em runtime e depois um gradiente suave; nenhum ficou bom, então o fundo
/// é chapado.)
///
/// Use como camada de fundo em um [Stack] (é [IgnorePointer]).
class PaperTexture extends StatelessWidget {
  const PaperTexture({super.key, this.grain = 0.55});

  /// Mantido por compatibilidade de API; sem efeito no fundo chapado.
  final double grain;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return IgnorePointer(
      child: ColoredBox(
        color: t.surface,
        child: const SizedBox.expand(),
      ),
    );
  }
}

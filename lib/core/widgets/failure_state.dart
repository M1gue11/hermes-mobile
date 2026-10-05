import 'package:flutter/material.dart';

import '../../domain/models/hermes_failure.dart';
import '../theme/hermes_tokens.dart';

/// Estado de falha, com dignidade: causa, o que fazer, e ação só quando existe.
///
/// Um só componente para a lista, o chat e o seletor de modelos, senão cada
/// tela inventa a sua ideia de erro e o app fica falando três línguas.
///
/// Três regras que este componente carrega:
///
/// 1. **Nunca `toString` de exceção.** O texto vem de [HermesFailure], que só
///    conhece causa, dica e referência pública.
/// 2. **Retry só quando pode dar certo.** Botão de "tentar de novo" num 401 é
///    promessa falsa: sem chave nova o próximo toque falha igual. Quem decide é
///    [HermesFailure.retryable].
/// 3. **A referência técnica é discreta, mas existe.** `HTTP 503 ·
///    gateway_unavailable` numa linha pequena é o que permite ao dono do
///    aparelho relatar o problema sem precisar abrir log.
class FailureState extends StatelessWidget {
  const FailureState({
    super.key,
    required this.failure,
    this.onRetry,
    this.keyPrefix = 'falha',
    this.compact = false,
  });

  final HermesFailure failure;
  final VoidCallback? onRetry;

  /// Prefixo das chaves de widget, para o teste apontar a tela certa.
  final String keyPrefix;

  /// Versão enxuta, para caber dentro de uma folha ou de uma bolha.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final referencia = failure.reference;
    final mostraRetry = onRetry != null && failure.retryable;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              failure.kind == HermesFailureKind.semRede
                  ? Icons.cloud_off_outlined
                  : Icons.error_outline,
              size: compact ? 18 : 22,
              color: t.faint,
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              failure.title,
              key: ValueKey('$keyPrefix-falha-titulo'),
              textAlign: TextAlign.center,
              style: t.serif.copyWith(fontSize: compact ? 15 : 18, color: t.ink),
            ),
            const SizedBox(height: 6),
            Text(
              failure.hint,
              key: ValueKey('$keyPrefix-falha-dica'),
              textAlign: TextAlign.center,
              style: t.serif.copyWith(fontSize: compact ? 13 : 14, color: t.dim, height: 1.45),
            ),
            if (referencia != null) ...[
              const SizedBox(height: 10),
              Text(
                referencia,
                key: ValueKey('$keyPrefix-falha-referencia'),
                textAlign: TextAlign.center,
                style: t.mono.copyWith(fontSize: 10, letterSpacing: 0.8, color: t.faint),
              ),
            ],
            if (mostraRetry) ...[
              SizedBox(height: compact ? 12 : 18),
              OutlinedButton(
                key: ValueKey('$keyPrefix-falha-retry'),
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

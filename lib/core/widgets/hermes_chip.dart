import 'package:flutter/material.dart';

import '../theme/hermes_radius.dart';
import '../theme/hermes_tokens.dart';
import 'tap_scale.dart';

/// A pastilha do design, usada tanto no composer quanto nos filtros da lista.
///
/// `design/Hermes.dc.html`, classe `.chip`: `padding:6px 11px`,
/// `border:1px solid var(--line)`, `border-radius:20px`, fundo `--bg2`, rótulo
/// em mono de 11px. Selecionada, a borda puxa para o âmbar, que é o mesmo
/// tratamento que o mock dá ao estado ativo (`.chip:hover{border-color:
/// color-mix(in oklab, var(--accent) 55%, var(--line))}`).
///
/// Existe como widget compartilhado porque a alternativa era o `ChoiceChip` do
/// Material, que traz cantos, densidade e tique de outra família visual.
class HermesChip extends StatelessWidget {
  const HermesChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.minTapHeight,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;

  /// Altura mínima do **alvo de toque**, sem mexer no desenho da pastilha.
  ///
  /// A pastilha do design tem só 26px de altura, bem abaixo dos 48 do Android
  /// e dos 44 do iOS. Quando um valor é dado aqui, a pastilha continua idêntica
  /// e ganha folga tocável em volta; a folga ocupa o espaço que de qualquer
  /// forma seria margem, então o resultado óptico não muda.
  ///
  /// Fica opcional em vez de valer sempre porque crescer o widget mexe no
  /// layout de quem já o usa, e os filtros da lista de conversas ainda não
  /// foram medidos com isto.
  final double? minTapHeight;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final pastilha = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(
          color: selected ? t.accent.withValues(alpha: 0.55) : t.line,
        ),
        borderRadius: HermesRadius.todos(HermesRadius.pastilha),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: t.accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: t.mono.copyWith(
              fontSize: 11,
              color: selected ? t.ink : t.dim,
            ),
          ),
        ],
      ),
    );

    return TapScale(
      onTap: onTap,
      semanticsLabel: label,
      child: minTapHeight == null
          ? pastilha
          : SizedBox(height: minTapHeight, child: Center(child: pastilha)),
    );
  }
}

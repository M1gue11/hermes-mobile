import 'package:flutter/material.dart';

import '../theme/hermes_tokens.dart';

/// Barra das telas inteiras empilhadas: ação de saída, título, linha técnica
/// e ações. Usada por Skills e Agendamentos.
class ScreenTopBar extends StatelessWidget {
  const ScreenTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onLeading,
    this.leadingIcon = Icons.arrow_back_ios_new_rounded,
    this.leadingTooltip = 'Voltar',
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final VoidCallback onLeading;
  final IconData leadingIcon;
  final String leadingTooltip;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: leadingTooltip,
                onPressed: onLeading,
                icon: Icon(leadingIcon, size: 20, color: t.ink),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t
                          .serifIn(FontWeight.w500)
                          .copyWith(fontSize: 20, color: t.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.mono.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.15,
                        color: t.dim,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

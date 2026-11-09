# Plano de ação - produto e interface

Este arquivo registra a ordem que ainda orienta o trabalho de produto. Contratos
e evidências técnicas ficam em `docs/dashboard-api/` e no histórico Git.

## Prioridade atual

1. Validar em aparelho as implementações recentes: A104, seleção múltipla de
   A78, A79 e A92; roteiros em [USER_TESTING.md](USER_TESTING.md).
2. Medir o ciclo de vida real de B9 antes do refino no molde do Desktop.
3. Preparar A105, com levantamento e desenho único da barra para aprovação:
   voz com texto (A78), envio durante turno (A106) e indicador A98/B10.
4. Retomar A42 quando houver arte ou direção visual aprovada para ícone e splash.

## Contratos de interface que permanecem ativos

- A timeline operacional usa o mesmo modelo nos modos cronológico e consolidado.
  Expansão, posição de leitura, texto ampliado e redução de movimento não podem
  deslocar o cabeçalho tocado.
- O streaming acompanha o fim por intenção. Qualquer rolagem, busca ou divulgação
  pausa o acompanhamento até uma ação explícita de retomada.
- A configuração de persona tem uma fonte única. Nomes técnicos e referências ao
  produto permanecem estáveis quando não forem copy da persona.
- A tela de Skills não deve inventar edição ou ativação enquanto a API móvel não
  persistir essas operações. A primeira fase somente leitura continua sendo a
  base visual de A65.

## Próximas decisões de produto

- A60 foi decidido em 2026-11-08 (UnifiedPush + ntfy self-hosted + plugin
  `server/mobile-push`, payload mínimo) e implementado; falta instalar o plugin
  no servidor e o aceite no aparelho. Arquitetura e limites em
  [NOTIFICATIONS_ARCHITECTURE.md](NOTIFICATIONS_ARCHITECTURE.md).
- A42 precisa de direção visual aprovada; não gerar identidade por conta própria.

## Fora da frente de produto

B0, B10, B9 e B11 permanecem ativos no contrato TUI/runtime, mas não interrompem
esta frente salvo regressão do runtime ou sinal de segurança que exija resposta
imediata.

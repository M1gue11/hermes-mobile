# Plano de ação - produto e interface

Este arquivo registra a ordem que ainda orienta o trabalho de produto. Contratos
e evidências técnicas ficam em `docs/dashboard-api/` e no histórico Git.

## Prioridade atual

1. Fechar A72: aplicar a persona configurada em toda a cópia de produto,
   acessibilidade, estados vazios, mensagens, diálogos e notificações, sem
   renomear ids, providers, modelos, sessões ou o produto Hermes.
2. Fechar o próximo recorte de A65 somente quando o contrato autenticado do
   Dashboard expuser corpo integral, edição protegida, exclusão confirmada,
   ativação/desativação persistida e estado inequívoco.
3. Rodar no aparelho os aceites de A75, A73 e A74 descritos em
   [USER_TESTING.md](USER_TESTING.md).
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

- A60 precisa de decisão sobre ambição de entrega e privacidade antes de qualquer
  fornecedor push, serviço externo ou mudança no Gateway. A arquitetura e seus
  limites estão em [NOTIFICATIONS_ARCHITECTURE.md](NOTIFICATIONS_ARCHITECTURE.md).
- A42 precisa de direção visual aprovada; não gerar identidade por conta própria.

## Fora da frente de produto

B0, B10, B9 e B11 permanecem ativos no contrato TUI/runtime, mas não interrompem
esta frente salvo regressão do runtime ou sinal de segurança que exija resposta
imediata.

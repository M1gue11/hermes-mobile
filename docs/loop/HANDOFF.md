# Passagem de bastão atual

Hermes Mobile é um app Flutter cliente do agente Hermes. Leia
[README.md](../../README.md), [BACKLOG.md](BACKLOG.md) e somente então o código
afetado.

## Checkpoint

- Atualização de streaming de 2026-10-11: análise limpa, 690 testes passaram,
  APK debug compilado e instalado. Rotina remota validada com 10 tools, replay
  de 13 eventos após background, um único submit e reabertura com resposta e
  saída da última tool preservadas. B12/B13 mantêm aceites específicos de
  interim/risco, aprovação, restart e ring expirado. A auditoria 0.21.6 registra
  também a correção de perda de output/risco no snapshot compacto.

- O baseline registrado no último pacote foi `flutter analyze` limpo, suíte de
  testes verde e APK debug compilado.
- O pacote de Ajustes, a lista de conversas, a abertura inicial, a timeline
  operacional, o Markdown, os primitivos compartilhados e o catálogo de Skills
  somente leitura foram validados em aparelho; revalidar ao mudar o runtime.
- As validações manuais ainda abertas são A75, A73 e A74; os roteiros vivem em
  [USER_TESTING.md](USER_TESTING.md).
- A72 foi implementado em 2026-10-31 (estado vazio e rótulo de modelo seguem a
  persona; inventário no backlog) e aguarda conferência no aparelho. O próximo
  trabalho de produto é A65, fechar o contrato autenticado para corpo integral,
  edição, exclusão e ativação persistidas de Skills.
- A60 continua condicionado a uma decisão explícita de escopo e privacidade.
  B0, B10, B9 e B11 são a fila posterior de contrato e runtime.

## Fatos que evitam regressões

- `design/Hermes.dc.html` é referência visual, não código para copiar.
- `DesignScale` adapta o canvas de 390 px; não reescalar fontes manualmente.
- Usar `serifIn`/`monoIn` para peso real; `copyWith(fontWeight:)` pode escolher
  uma face inexistente.
- A thread respeita quem está relendo. Conversas curtas começam no topo; threads
  longas usam lista cronológica lazy e abrem sincronizadas com o fim.
- O acompanhamento do fim só permanece ativo quando a intenção da pessoa está
  ativa. Divulgação da timeline e rolagem manual pausam sem corrigir o offset;
  mudanças de altura só sincronizam o fim durante o acompanhamento.
- Reconnect nunca reenvia prompt ou resposta interativa.
- Retomada usa sessão, epoch e sequência quando o servidor oferece replay;
  deltas já entregues não são aplicados novamente. Snapshot fallback e
  transformação terminal têm semânticas próprias: comprimento não é identidade.
- Histórico concluído do Dashboard usa `session.history` com o id durável; não
  abra sessão live apenas para hidratar a tela.
- O transcript pode conter user e segmentos intermediários em curso; `inflight`
  continua separado e pode reter erro com `running=false`. Não adotar a resposta
  do turno anterior como parcial do atual.
- `reasoning.delta`, `thinking.delta` e `reasoning.available` têm semânticas
  diferentes. O contrato medido está em
  [../dashboard-api/tui-eventos-0.20.1-medido.md](../dashboard-api/tui-eventos-0.20.1-medido.md).
- O delta atual, os ajustes de streaming e a validação ainda pendente estão em
  [../dashboard-api/mobile-streaming-audit-0.21.6.md](../dashboard-api/mobile-streaming-audit-0.21.6.md).
- `tool.complete` do TUI carrega `result`, `args` e `tool_id`; a Runs API continua
  sendo um fallback mais pobre por contrato.
- Segredos nunca entram em terminal, log, screenshot, teste ou documentação.
- Na edição de conexões, segredo vazio significa preservar o valor atual. Falha
  após mutação exige rollback das duas conexões; somente “Esquecer conexões” pode
  limpar deliberadamente o pareamento.
- Copy de persona vem de `AgentPersona`; referências técnicas e de produto não
  devem ser renomeadas com a persona.
- Respeitar a política de Host e origem da instalação Dashboard configurada;
  não contornar validações para conectar.
- `/chat` é filha de `/`, a navegação usa `go`, e o roteador é criado uma vez em
  `HermesApp`.
- Não alterar o runtime Hermes como parte de uma mudança do cliente móvel.

## Limites

Não ler ou imprimir credenciais. Não adicionar dependência, serviço externo,
método TUI ou desvio relevante de design sem decisão do usuário.

Contratos e evidências técnicas ficam em `docs/dashboard-api/`; roteiros
pendentes de aparelho ficam em [USER_TESTING.md](USER_TESTING.md).

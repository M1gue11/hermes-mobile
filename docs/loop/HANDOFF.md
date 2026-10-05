# Passagem de bastão atual

Hermes Mobile é um app Flutter cliente do agente Hermes. Leia
[README.md](../../README.md), [BACKLOG.md](BACKLOG.md) e somente então o código
afetado.

## Checkpoint

- O baseline registrado no último pacote foi `flutter analyze` limpo, suíte de
  testes verde e APK debug compilado.
- O pacote de Ajustes, a lista de conversas, a abertura inicial, a timeline
  operacional, o Markdown, os primitivos compartilhados e o catálogo de Skills
  somente leitura foram validados em aparelho; revalidar ao mudar o runtime.
- As validações manuais ainda abertas são A75, A73 e A74; os roteiros vivem em
  [USER_TESTING.md](USER_TESTING.md).
- O próximo trabalho de produto é A72, aplicar a persona configurada em toda a
  cópia apresentada, e A65, fechar o contrato autenticado para corpo integral,
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
- Retomada é monotônica: histórico ou snapshot parcial pode enriquecer o turno
  ativo, nunca substituir uma timeline mais completa.
- Histórico concluído do Dashboard usa `session.history` com o id durável; não
  abra sessão live apenas para hidratar a tela.
- Nenhum histórico contém o turno em curso até ele terminar; qualquer
  reconstrução deve preservar a bolha viva por `_timelineComTurnoEmCurso`.
- `reasoning.delta`, `thinking.delta` e `reasoning.available` têm semânticas
  diferentes. O contrato medido está em
  [../dashboard-api/tui-eventos-0.20.1-medido.md](../dashboard-api/tui-eventos-0.20.1-medido.md).
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

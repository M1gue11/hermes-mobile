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
- A60 tem fatia in-app na branch exclusiva `feat/notifications-night-20261007`,
  baseline `08833d0`, **WIP — não aceita para merge**. Inbox e preferências são
  locais em memória; nenhum transporte/ponte OS novo. SDK oficial ARM Flutter
  3.44.6 / Dart 3.12.2: pub get/codegen/analyze exit 0; suíte completa após duas
  rodadas corretivas: **717 passes, exit 0, 5m40**. A revisão final encontrou
  um P2 de retomada idle/histórico vazio que Claudia reproduziu em teste isolado
  (exit 1); duas rodadas corretivas esgotadas. Aceite de aparelho também pendente.
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

## Protótipo durável complementar — offline, WIP

[`prototypes/notifications`](../../prototypes/notifications/README.md) contém
Python stdlib/SQLite, envelope v1, evento+inbox+outbox transacionais, dedupe,
retry/expiry/leases/fencing e read/ACK/auditoria separados. Não cria HTTP/serviço,
scheduler, regra ativa nem transporte real; adapters fake são só testes.
Claudia executou 15 testes unittest e py_compile (exit 0) e smoke de CLI com
restart por comando, dedupe, read/ACK separado e arquivo 0600 (exit 0).

Review independente encontrou P2 de inicialização interrompida: arquivo é criado
antes de schema/identidade; falha deixa arquivo próprio com identidade zero que a
CLI passa a rejeitar como alheio. Claudia reproduziu com injeção neutra (probe
exit 1). **Protótipo WIP, não aceito para deploy**. Guard/fixture têm raiz scratch
fixada ao host autorizado, limitação de portabilidade documentada. Nenhum DB
preexistente foi tocado; FCM/APNs/UnifiedPush continuam opções, não integrações.

## A60 — resultado final WIP e bloqueio de aceite

Claudia executou `flutter pub get`, `dart run build_runner build`, `flutter analyze`
(exit 0, No issues found, 2.3s) e `flutter test --reporter compact` completo
(**717 passes, exit 0, 5m40**). Foco pós-rodada #2: **135 passes, exit 0, 27s**.
SDK oficial ARM Flutter 3.44.6 / Dart 3.12.2 em scratch, sem relaxar pubspec/lock.

**P2 remanescente, reproduzido e não corrigido:** `_resumeActiveGatewayTurn`
(linha 885) e `_recoverGatewayTurn` (linha 1265) chamam `_noticePhase` sobre fase
local após retorno `running:false`. Se `_fail` de observação/stop deixou a fase
local `failed` e os históricos estão vazios, `_noticePhase` (linha 1754) a trata
como falha autoritativa, finaliza o slot na inbox e impede correção posterior.
Não existe status remoto de falha nesse caso. Teste isolado de Claudia com
FakeGatewayLiveTurn e erro neutro de interrupt: aviso antes da retomada era
“Não foi possível acompanhar a execução”; depois tornou-se “A execução falhou”.
Comando `flutter test --reporter expanded ${HERMES_SCRATCH}/notifications-known-p2-probe_test.dart`
retornou **exit 1, 0 passes/1 falha**, como esperado para comprovar o defeito.
Esse probe vive em scratch, não integra os 717 testes da branch; não esconder a
lacuna atrás da suíte verde. Duas rodadas corretivas permitidas esgotadas: próximo
trabalho precisa preservar proveniência autoritativa e adicionar essa regressão.
Aceite de código/A60 bloqueado; APK/aparelho e OS/push não comprovados.

Os registros abaixo preservam o histórico das rodadas, não descrevem pendências
atuais de SDK ou ausência de testes. Commits locais WIP serão identificados no
relatório da missão; nenhum push/merge/PR/release/deploy.

### Superfície implementada

- `OperationalNotice.parse` valida show/clear e projeta sinais sem payload rico.
  `_eventsFrom` entrega `RunEvent.operational`, separado de texto e raciocínio.
- `NotificationInbox.accept/run` controla inbox, read/unread, key por sessão
  durável, dedupe, TTL e progresso agregado em 750 ms. Entradas: 100; caches:
  256 cada; pending: 32. Timers são cancelados na substituição/clear/dispose.
- O controller usa somente seu `state.sessionId` durável e id local do turno;
  `_noticePhase/_noticeRun` projetam início/terminal/snapshot/cancelamento local.
  Troca, ocultação, reconciliação e dispose descartam progresso pendente.
  Nenhum listener adicional; reconnect não envia prompt.
- `NotificationSheet` usa `HermesTokens/showHermesSheet`, `agentPersonaProvider`,
  texto plain e rota existente `/chat/${Uri.encodeComponent(sessionId)}`.
- `TurnCapture` registra apenas metadata operacional mesmo com sampleText.
- Regressões em domain, store, controller, widget, adapter e captura. Rodada #1
  cobre null/warn, seqScope por live session/epoch, fallback local por conexão,
  falha provisória de observação e progresso genérico de ferramentas. Dedupe por ID
  de sinais permanece independente; show usa identidade reutilizável com seq ou
  comparação do payload limitado da entrada ativa quando sem seq. Nenhum novo log de identificadores.
- `_fail` mantém o comportamento do chat; somente a projeção de notices distingue
  observação de terminal autoritativo. Falhas de start/submit são provisórias,
  mesmo quando limpam registro local. Snapshot terminal substitui erro provisório.

Validação Codex na rodada #1 (todos os comandos Dart/Flutter usaram caminho
absoluto do SDK e `PUB_CACHE=${HERMES_SCRATCH}/notifications-pub-cache`):
`dart format` e `dart fix --apply --code=curly_braces_in_flow_control_structures`
executados. `flutter analyze` inicial tentou resolver pacotes e terminou exit 69
por DNS de pub.dev; comandos seguintes usam `--no-pub`, sem alteração de lock.
`flutter analyze --no-pub`: exit 0, No issues found (2.9s).
`flutter test --no-pub test/domain/operational_notice_test.dart
 test/features/notification_inbox_test.dart test/features/notification_controller_test.dart
 test/features/notification_sheet_test.dart test/data/dashboard_gateway_repository_test.dart
 test/core/turn_capture_test.dart`: exit 1, todos os seis arquivos bloqueados no
loading por bind local `127.0.0.1` (Operation not permitted). Nenhum teste chegou
à execução. Sandbox não ampliado; Claudia executará as regressões e suíte completa.
Codegen real é o de Claudia; não foi necessário regerar nesta correção. Somente
whitespace da linha vazia após construtor RunOperational foi normalizado no gerado,
sem alteração de lógica. `git diff --check`: exit 0.
Ponte OS/permissões/som/push/cron, entrega offline/terminated e durabilidade no
servidor permanecem fora desta execução. Nenhum commit/push/PR/CI/release.

Rodada #2 final: `_duplicate` mantém seq/scope após clear/TTL e limita dedupe
sem seq de show ao payload ativo. `_schedule` cancela pending quando o último
sinal coincide com o publicado, preservando localId/read; atualizações pendentes
mantêm a janela original. `status.running` projeta “Execução em andamento”.
Regressões cobrem IDs reutilizados, clear repetido, TTL/remoção, replay seq,
keyless/fallback sem seq, scopes reais versus turno local e last-wins no controller.
Validação Codex #2: `dart format` exit 0; `flutter analyze --no-pub` exit 0
(No issues found, 2.2s), após corrigir fixture que usava parâmetro ID inexistente
em NoticeClear. A primeira tentativa de analyze concorrente ao teste falhou
no engine.stamp temporário do SDK; analyze sequencial acima passou.
Teste focado com os dois arquivos inbox/controller: exit 1 no loading; inbox
teve esse erro de compilação de fixture (corrigido e validado por analyze),
controller bloqueado no bind 127.0.0.1 (Operation not permitted). Nenhum teste
executou; não repetido após o bloqueio. Suíte inteira não executada no sandbox.
`git diff --check` exit 0. Codegen de Claudia e whitespace gerado preservados.
Nenhum artefato criado fora de scratch, nenhum commit/push/deps/infra.
BACKLOG A81–A93 e USER_TESTING preservados. Re-review final e suíte completa da
rodada #2 aguardam Claudia, sem resultado presumido.

Comandos reproduzíveis para re-review (mesmo cache, sem pub get):
`HERMES_SCRATCH` deve apontar para o diretório scratch configurado da instalação;
os comandos abaixo usam caminhos absolutos derivados dessa variável.

```sh
PUB_CACHE=${HERMES_SCRATCH}/notifications-pub-cache ${HERMES_SCRATCH}/flutter-notifications-sdk/bin/flutter analyze --no-pub
PUB_CACHE=${HERMES_SCRATCH}/notifications-pub-cache ${HERMES_SCRATCH}/flutter-notifications-sdk/bin/flutter test --no-pub test/domain/operational_notice_test.dart test/features/notification_inbox_test.dart test/features/notification_controller_test.dart test/features/notification_sheet_test.dart test/data/dashboard_gateway_repository_test.dart test/core/turn_capture_test.dart
git diff --check
```

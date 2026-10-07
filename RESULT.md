# Resultado real — missão de notificações Hermes Mobile

Data: 2026-10-07. Checkpoint de evidências: 01:26:29 -03.
Responsáveis: Claudia P.O./revisora; implementação por subprocessos Codex reais.

> [!warning] Entrega WIP, não aceita para merge/deploy
> Foram produzidas duas fatias executáveis e testadas, com commits locais. A suíte
> Flutter final tem 717 passes e o protótipo SQLite tem 15 passes, mas revisão e
> probes adicionais comprovaram dois P2 que essas suítes ainda não cobrem. As duas
> rodadas corretivas permitidas foram usadas; não houve terceira correção.
> Nenhum push, merge, PR, release, deploy, alteração do Gateway ou serviço externo.

## 1. Branch, baseline e commits

- Worktree exclusivo: `/home/miguel/.hermes/workspace/hermes-mobile-notifications-20261007`.
- Branch: `feat/notifications-night-20261007`.
- Baseline: `08833d04f7bae3723ff17b2385d1722947281235`.
- Repo de origem/auditoria: `/home/miguel/.hermes/cache/scratch/hermes-mobile-second-review`;
  `main` continuou no baseline, com status limpo na leitura final.
- Commit cliente: `35eacef66e32614a2fa6748c5d11f02a42b35dd7` —
  `WIP: notificações in-app A60; P2 de retomada pendente`.
- Commit complementar: `05362f09c0e0a7d86049076811302768d234d1b2` —
  `WIP: inbox e outbox SQLite offline; recuperação inicial pendente`.
- Este relatório e o fechamento de STATUS/docs recebem um commit local de documentação
  posterior; seu SHA deve ser lido com `git log -1`, pois não é possível incorporar
  o hash de um commit no próprio conteúdo que determina esse hash.

O primeiro commit falhou com exit 128 por identidade Git ausente. Consultei o
histórico, usei a identidade Claudia-ha já existente via flags `git -c` somente
nos comandos de commit e não alterei configuração global ou compartilhada.

## 2. Fatia principal implementada e exercitada

- `notification.show`/`notification.clear` viram `RunEvent.operational`, não fala
  final ou reasoning. Modelo separado valida shape, opcionais ausentes/null,
  `warn` e compatibilidade `warning`, limites e TTL.
- Inbox in-app em **Ajustes → Notificações**, com persona configurada, categoria,
  origem genérica, severidade, lida/não lida, remoção e abertura da conversa
  durável capturada. Navegação codifica ID e fecha inbox/Ajustes; payload não
  fornece URL/ação executável. Texto personalizado usa `Text`, limitado a 1000
  codepoints, sem interpretar Markdown ou links.
- Show substitui por key real na mesma sessão; keyless usa ID real ou identidade
  local separada. IDs de show são reutilizáveis; seq/scope identifica ocorrências.
  Clear repetido é idempotente. TTL válido 0–604800000 ms; inválido rejeitado;
  expiração/substituição/remoção/dispose cancelam timers.
- Seq scope usa `session_id` do envelope e `replay_epoch` de `gateway.ready`.
  Metadata incompleta usa identidade **local** por conexão, não ID servidor
  fabricado. Caches limitados, sem ledger/replay garantido.
- Progresso da run e subagents é genérico, agregado por slot com janela de 750 ms
  e last-wins. Não há alerta por token. IDs reais distinguem subagents paralelos;
  sem ID há agregado limitado. Timeout de subagent é erro; status desconhecido
  apenas encerramento, não sucesso inventado. Background tem resumo genérico.
- Categorias progresso/conclusão/erro/personalizado podem ser silenciadas.
  Mute cancela pending; terminais cancelam progresso tardio. Erro de observação
  direto tem aviso provisório; o caso de retomada abaixo ainda viola essa regra.
- Captura operacional omite corpo/keys/IDs; sampleText não revela payload bruto.
  Nenhum tool arg/result, prompt, reasoning ou resumo privado de subagent é
  projetado automaticamente para a nova inbox.

**Limites explícitos:** inbox e preferências só em memória nesta abertura do app.
Listeners continuam limitados à conversa visível/conectada. Não há entrega
contínua em background, app encerrado, offline, todas as sessões ou replay de
avisos perdidos. Nenhuma ponte Android, permissão OS, som, push, serviço,
polling perpétuo, wake lock ou cron novo. APK e aparelho não foram validados.

### P2 principal comprovado — bloqueia aceite

Após falha de observação/stop, `_fail` mantém a bolha local `ChatPhase.failed`
mas publica corretamente aviso provisório. Ao ocultar/retomar, `running:false`
e históricos vazios não fornecem causa terminal remota. Contudo,
`_resumeActiveGatewayTurn`/`_reconcileGatewayAfterDisconnect` passam essa fase
**local** a `_noticePhase`, que afirma “A execução falhou” e sela o slot como
terminal. Isso pode impedir substituição por conclusão/cancelamento posteriores.

- Call sites: `lib/features/chat/chat_controller.dart:885–887` e `1265`.
- Conversão indevida: `_noticePhase`, ramo failed, linha `1754`.
- Probe de Claudia, em scratch: erro neutro de `interrupt()` → aviso provisório →
  ocultar/retomar idle com história vazia → aviso incorreto. Nenhum prompt reenviado.
- Resultado real: **exit 1, 0 passes/1 falha**; esperado aviso provisório, recebido
  “A execução falhou”. Esse probe NÃO integra os 717 testes da branch.
- Próximo aceite exige proveniência autoritativa explícita e regressão desse caso
  incorporada ao repositório; suíte verde atual não é suficiente.

## 3. Fundamento durável complementar — offline, também WIP

Em `prototypes/notifications/`, Python stdlib/SQLite, sem dependência nova:

- Envelope v1 imutável e schema estrito, ID/dedupe transacional por origem/destino,
  conflitos rejeitados sem sobrescrever evento.
- Evento + inbox + outbox + auditoria persistidos numa transação antes de send.
- Claims com `BEGIN IMMEDIATE`, lease/token/fencing, attempts persistidos,
  retry exponencial limitado, falha transitória/permanente e expiry.
- Recuperação de restart/crash antes/depois de send, com possibilidade documentada
  de reenvio do mesmo ID. Sem promessa exactly-once remoto.
- Read e ACK separados entre si, da outbox e da auditoria append-only.
- Adapter é Protocol, sem transporte default/no-op que finja push. DTO produzido
  pelo claim usa mensagem fixa genérica; texto rico não vai para essa fronteira.
- CLI offline exige `--db`, limita criação a scratch, arquivo 0600 e rejeita
  symlinks/hardlinks/arquivo público/banco alheio. Nenhuma regra/scheduler ativo.

Claudia executou smoke com DB novo
`/home/miguel/.hermes/cache/scratch/notifications-offline-smoke-ni4jfqqm/smoke.sqlite`:
ingest inseriu; repetição não inseriu; cada comando foi um processo novo; read
não fez ACK; ACK foi persistido; audit ficou `ingested/read/ack`; outbox continuou
`pending: 1`; permissão 0600. **Transporte REAL AUSENTE**, não houve push.

### P2 complementar comprovado — inicialização interrompida

`open_private` cria arquivo exclusivo em `cli.py:24`, antes de schema
`core.py:109` e identidade `cli.py:42`. Falha nessa janela deixa arquivo vazio ou
parcial com identidade zero. Reabrir o mesmo arquivo o rejeita como DB alheio
(`cli.py:36–37`), sem recuperação segura da própria inicialização.

Claudia injetou `sqlite3.OperationalError` antes de Store/schema, depois de
criar o arquivo: ficou com 0 bytes; tentativa seguinte retornou “DB não pertence
ao protótipo”. Probe **exit 1** comprova o defeito, não indisponibilidade de Python.
Não remover bancos alheios para contornar; precisa publicação/recuperação segura.

Outros limites: CLI e fixture fixam a raiz scratch autorizada deste host (dois
paths de infraestrutura, não segredos); portabilidade pendente. Clock regressivo,
race de troca de path, opacidade de IDs/categoria, seleção do safe_summary pelo
produtor e auth/enrollment/revogação/TLS precisam decisão antes de produção.
O teste de ausência de erro bruto via `str(sqlite3.Row)` é fraco e precisa consultar
valores reais; fonte/auditoria foram revisadas, mas essa asserção não prova isso.

README compara WS/MethodChannel, FCM, APNs e UnifiedPush com fontes oficiais.
WebSocket não acorda app morto; provider accepted não significa delivered/read.
Nenhum transporte ativado, Telegram/produtores/agendadores intocados.

## 4. Arquivos e funções/linhas verificadas

Linhas desta branch no checkpoint; os hashes gerados são intencionais somente
para RunEvent/controller. Gerados não relacionados foram restaurados.

| Arquivo | Superfície |
| --- | --- |
| `lib/domain/models/operational_notice.dart:36` | `OperationalNotice.parse`, show/clear/sinais, null/warn/TTL, `NoticeSeqScope` |
| `lib/domain/models/gateway_rpc.dart:43,76` | `GatewayEventFrame`, `decodeGatewayFrame`, seq/session metadata |
| `lib/domain/models/run_event.dart:21` | factory operacional; `run_event.freezed.dart` gerado real |
| `lib/data/gateway/dashboard_gateway_repository.dart:996,1219,1380` | `_eventsFrom`, scope de socket/ready e roteamento separado |
| `lib/features/notifications/notification_inbox.dart:140,187,300,365,391` | `_duplicate`, `accept`, `run`, `_schedule`, `_put`; caches/timers/mute/read |
| `lib/features/notifications/notification_sheet.dart:11,23,87–94` | `showNotificationSheet`, `NotificationSheet.build`, navegação segura |
| `lib/features/chat/widgets/sheets.dart:69–74` | entrada de Notificações em Ajustes |
| `lib/features/chat/chat_controller.dart:854,1212,1323,1676,1749,1762` | resume/reconcile, `_onEvent`, `_fail`, `_noticePhase`, `_noticeRun`; lifecycle e P2 acima |
| `lib/features/chat/chat_controller.g.dart` | hash gerado correspondente ao controller |
| `lib/core/diagnostics/turn_capture.dart:241,286` | `rawFrame`, `adapterEvent`, omissão operacional |
| `prototypes/notifications/core.py:48,153,194,220,227,249,266` | parse, ingest, claim, valid, finish, send_claim, read/ack |
| `prototypes/notifications/cli.py:14,48` | `open_private`, `main`; P2 de inicialização |

Regressões Flutter: `test/domain/operational_notice_test.dart`,
`test/features/notification_inbox_test.dart`, `notification_controller_test.dart`,
`notification_sheet_test.dart`, `test/data/dashboard_gateway_repository_test.dart`,
`test/core/turn_capture_test.dart`, `test/features/settings_sheet_test.dart` e
clock neutro `test/support/notice_clock.dart`.

Regressões Python: `prototypes/notifications/test_core.py` (15 métodos).
Docs: `docs/loop/BACKLOG.md`, `HANDOFF.md`, `NOTIFICATIONS_ARCHITECTURE.md`,
`USER_TESTING.md`, README do protótipo, `STATUS.md` e este `RESULT.md`.
A81–A93 e roteiros A75/A73/A74 foram preservados, sem backlog paralelo no vault.

## 5. Validação real, ferramenta e comandos

SDK oficial isolado em `/home/miguel/.hermes/cache/scratch/flutter-notifications-sdk`:
Flutter **3.44.6**, Dart **3.12.2**, ELF ARM aarch64. SHA/tag/remoto conferidos:
`ee80f08bbf97172ec030b8751ceab557177a34a6`, tag `3.44.6`,
`https://github.com/flutter/flutter.git`. Checkout detached imprime canal
`[user-branch]/unknown source`; origem e SHA upstream foram conferidos, não uma
versão inventada. SDK `du -sh`: 1.1G; PUB_CACHE isolado 242M. Nenhuma instalação
ou privilégio global, Docker não usado. Python real: **3.13.5**.

Os comandos Dart/Flutter usaram binários absolutos desse SDK e
`PUB_CACHE=/home/miguel/.hermes/cache/scratch/notifications-pub-cache`.

| Execução | Exit real | Resultado |
| --- | ---: | --- |
| `flutter pub get` compatível, inicial e repetido | 0 | dependências do lock existente; nenhuma dependência nova |
| `dart run build_runner build`, inicial e após correções | 0 | codegen real; churn alheio restaurado; whitespace gerado normalizado sem lógica |
| `flutter analyze` inicial | 1 | 14 infos de lint, sem erro de compilação; corrigidas |
| `flutter test --reporter compact` inicial | 0 | 704 passes, 4m33 |
| suíte completa pós-rodada #1 | 1 | 708 passes/2 falhas, 5m34; fixtures/throttle corrigidos na rodada #2 |
| foco pós-rodada #2, sete arquivos | 0 | 135 passes, 27s |
| `flutter analyze` final canônico | 0 | No issues found, 2.3s |
| `flutter test --reporter compact` final canônico | 0 | **717 passes, 5m40** |
| `flutter test --reporter expanded` probe P2 scratch | 1 | **0 passes/1 falha**, defeito de retomada comprovado |
| `python -m unittest discover -s prototypes/notifications -p 'test_*.py' -v` | 0 | **15 testes, 1.242s, OK** |
| `python -m py_compile` dos três fontes Python | 0 | compilação real; PYTHONPYCACHEPREFIX em scratch |
| smoke CLI independente com readback/novo processo | 0 | persistência/dedupe/read/ACK/audit/0600; outbox pending, transporte ausente |
| probe Python com fault injection de inicialização | 1 | arquivo próprio vazio passa a ser rejeitado como alheio |
| Codex implementação, duas correções, reviews separados e protótipo | 0 | processos reais concluídos; review exit 0 não significa aceite |
| `git diff --check` / `git diff --cached --check` finais | 0 | whitespace limpo |
| auditoria local de links/segredos/preservação contra baseline | 0 | links locais sem quebra, padrões de segredo sem matches, A81–A93/roteiros preservados |

Dentro do sandbox Codex, testes Flutter falharam no loading por bind local
127.0.0.1, sem execução (exit 1); analyze com resolução chegou a falhar DNS (exit
69), depois `--no-pub` passou. Não ampliei sandbox por conveniência. Claudia
executou os comandos canônicos com a toolchain recuperada e obteve resultados
acima. Inspeção/format não foram vendidos como analyze/test.

Auditoria relata explicitamente dois paths de infraestrutura autorizados em
`cli.py:11` e `test_core.py:27`; exceções exatas, scan de segredo continua ativo.
STATUS/RESULT contêm paths pedidos da missão e não são fixtures. Não foi possível
provar ausência universal de segredo por regex: a inspeção dos dados novos é
neutra e o scan heurístico não encontrou padrões. Nenhum log privado no repo.
As validações de links aqui são **locais**, não uma promessa de todos os links
externos vivos. Diff de Android/iOS/CI/pubspec/lock contra baseline ficou vazio.

### Evidências/probes em scratch (não versionados)

- `notifications-tests-round2-full.log`, `notifications-tests-round2-focused.log`,
  `notifications-analyze-round2.log`, `notifications-codegen-round2.log`.
- `notifications-finalreview-last.md`, `notifications-durable-review-last.md`.
- `notifications-known-p2-probe_test.dart` e `notifications-known-p2-probe.log`.
- `notifications-durable-tests.log`, `notifications-durable-smoke.py`,
  `notifications-durable-init-probe.py`, `notifications-audit-final.json`.
- Todos sob `/home/miguel/.hermes/cache/scratch/`; scratch é temporário e pode ser
  podado, por isso este relatório preserva resultados e cenários, não logs privados.
- Codex criou um diff em `/tmp/notifications-round1.patch` na primeira correção;
  movi para scratch, retirei dali e reforcei a restrição nos subprocessos seguintes.

## 6. Como Miguel testa e decisões pendentes

Somente nesta branch, sem deploy automático:

1. Ler `docs/loop/USER_TESTING.md` A60 exclusivo; branch WIP, não pacote de main.
2. Reexecutar suíte com SDK compatível: `flutter pub get`,
   `dart run build_runner build`, `flutter analyze`, `flutter test`.
3. Em build/aparelho controlado, Ajustes → Notificações; verificar persona,
   texto plain, categorias/mute/read/clear/TTL e abertura da conversa.
4. Exercitar início/progresso/final/erro/interrupção, subagents paralelos,
   reconnect/troca de conversa e privacidade com produtor/fixtures **neutros**.
   Não emitir comandos privilegiados ou inventar RPC para gerar aviso.
5. Reproduzir o P2 idle/histórico vazio antes de conceder aceite; o comportamento
   atual não é correto. Corrigir com proveniência de status e regressão nova.
6. Rodar unittest do protótipo no host autorizado com TMPDIR scratch; CLI em DB
   novo exclusivo. Nenhum comando faz envio real. Falha de inicialização exige
   correção antes de aceitar a CLI; não apagar DBs de terceiros.

Pendências de produto: ponte OS nativa testável, permissão explícita, canais e
lockscreen, pareamento/autenticação/revogação/TLS de inbox durável, transporte
FCM/APNs/UnifiedPush e política de retenção/quiet hours. Regras de agente precisam
confirmação humana/revogação. Nenhuma migração de Telegram/produtores/agendadores.

**Aceito como evidência:** código produzido, fluxo comum exercitado, testes reais,
revisões e defeitos reproduzidos. **Não aceito como entrega pronta:** A60/CLI,
merge, Android físico, push/OS, offline/background/terminated ou produção.

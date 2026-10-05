# Gateway TUI remoto: contrato JSON-RPC 0.18.2

Este documento registra a superfície que o Hermes Desktop usa para chat ao vivo contra `hermes serve`. O inventário é o snapshot [`tui-gateway-contract-0.18.2.json`](tui-gateway-contract-0.18.2.json), extraído do Hermes `0.18.2` no commit `df5700ebe317…`. Não é um OpenAPI e não transforma detalhes não presentes no snapshot em contrato.

## Escolha da superfície

| Serviço | Endereço | Papel no Mobile |
| --- | --- | --- |
| Gateway/API Server | `:8642` | Compatibilidade OpenAI, Runs/SSE e APIs REST já existentes. |
| Gateway TUI remoto | `:9119`, `WS /api/ws` | Superfície de live chat fiel ao Desktop: texto, tools, reasoning e prompts interativos. |

O Mobile não deve tentar reconstruir essa UX pelo SSE de Runs em `:8642`: ele é complementar, mas não encaminha o `reasoning_callback` nativo na versão documentada. As REST APIs do Dashboard complementam o inventário; `/api/ws` é a superfície de live chat.

## Autenticação, host e conexão

1. Faça login no Dashboard e mantenha a sessão por cookie conforme o gate do Dashboard.
2. Com essa sessão, chame `POST /api/auth/ws-ticket`.
3. Use o ticket retornado **uma única vez** para abrir `ws://<host>/api/ws?ticket=...` ou `wss://<host>/api/ws?ticket=...`, conforme o transporte externo.
4. Cookie e credenciais podem existir somente no armazenamento seguro do sistema;
   nunca registre esses valores nem os inclua em documentação. O ticket é efêmero
   e nunca é persistido.

Use o host e o esquema publicados/configurados pelo servidor (`wss` atrás de TLS; `ws` somente em rede de desenvolvimento confiável, quando permitido). Não substitua o host ou a origem para contornar o gate. `4401` deve ser diagnosticado como credencial/ticket ausente, expirado, já consumido ou sessão inválida: refaça login se necessário e emita **novo** ticket. `4403` indica que a conexão foi recusada pela política de host, origem ou autorização: confira URL publicada, origem do cliente e permissões; não faça retry cego nem tente burlar a restrição.

No handshake atual, o primeiro frame após a autenticação é a notificação
JSON-RPC `event`/`gateway.ready`. O payload atual contém `skin`,
`change_events` e `replay_epoch`; no transporte WebSocket, `heartbeat` é um
campo opcional. O Mobile só usa o heartbeat quando o campo está presente e
verdadeiro; o delta completo e a política de 15/45 s estão em
[`mobile-contract-delta-0.20.1.md`](mobile-contract-delta-0.20.1.md).

## Framing JSON-RPC

O endpoint usa JSON-RPC 2.0. O contrato recomendado do Mobile é **exatamente um objeto JSON-RPC por frame de texto WebSocket**. O snapshot não declara nem o Mobile suporta múltiplos objetos JSON em um mesmo frame. O primeiro evento do servidor é `gateway.ready`; só depois dele a UI considera o gateway pronto.

Exemplos de envelopes, deliberadamente redigidos:

```json
{"jsonrpc":"2.0","id":"req-redigido","method":"session.list"}
```

```json
{"jsonrpc":"2.0","id":"req-redigido","result":"<resultado do método>"}
```

```json
{"jsonrpc":"2.0","id":"req-redigido","error":{"code":-32601,"message":"<erro redigido>"}}
```

```json
{"jsonrpc":"2.0","method":"event","params":{"type":"gateway.ready","payload":{"skin":"<skin>","change_events":true,"replay_epoch":"<epoch>","heartbeat":true}}}
```

Não há `id` em notificação do servidor. Preserve `id` para correlacionar request/response, trate `error` como resposta terminal daquele request e não suponha campos além dos listados abaixo.

## Requests do servidor para o Mobile (P0)

O backend atual também envia perguntas como requests JSON-RPC, não como
notificações `*.request`. O Mobile anuncia esta capacidade uma vez por conexão,
depois de `gateway.ready`, com:

```json
{"jsonrpc":"2.0","id":"mobile-1","method":"client.capabilities","params":{"server_requests":true}}
```

O resultado de `approval` usa **o mesmo `id` do frame recebido**; não
use o `request_id` interno da aprovação como correlação do envelope.

Para `clarify`, o Mobile trava **cada pergunta** pelo RPC `clarify.lock`,
correlacionando o `id` do frame com `request_id` e o `qid` com `question_id`:

```json
{"jsonrpc":"2.0","id":"srq-redigido","method":"clarify","params":{"session_id":"<live>","questions":[{"qid":"q0","question":"<pergunta>"}]}}
```

```json
{"jsonrpc":"2.0","id":"mobile-2","method":"clarify.lock","params":{"request_id":"srq-redigido","question_id":"q0","answer":"<resposta>"}}
```

O backend devolve `remaining` e o último lock resolve o pedido. Antes do último
lock, um `qid` já travado com resposta não nula pode ser editado e travado de
novo; `null` é um skip confirmado e não volta para a UI como campo editável.
Para `multi_select`, `answer` é uma string JSON contendo o array escolhido.
Em reconexão, `open_requests[].params.answers` traz os locks já aceitos.

Para aprovação, o resultado é `{ "choice": "once|session|always|deny", "all": false }`.
O Mobile suporta somente `clarify` e `approval`, sempre com gesto explícito. Ele
responde `-32601` sem abrir UI para `sudo`, `secret`, `vault.*` e outros métodos
não suportados; nunca encaminha nem exibe seus parâmetros.

`request.cancel` é uma notificação com `{id, method, reason}`. O cliente limpa
somente o card cujo `id` coincide; uma notificação para outro pedido não pode
derrubar o prompt atual. Respostas tardias continuam sem efeito.

Em `session.resume` (e demais snapshots que tragam `open_requests`), cada item
`{id, method, params}` é reentregue pelo mesmo caminho de request. O Mobile deve
restaurar apenas `clarify`/`approval`; pedidos sensíveis ou desconhecidos são
recusados sem UI. Em batches `server_request`, `answers` não nulas podem ser
reenviadas apenas para edição antes do último lock; respostas `null` são skips
confirmados e nunca são reenviadas.

## Eventos do snapshot

Classificação: **core mobile** é candidato à UI de chat; **interação protegida** requer UX e autorização explícitas; **administrativo/fora do MVP** não entra no MVP; **diagnóstico** é log/telemetria segura. “Payload documentado” reproduz somente o inventário.

| Evento | Payload documentado | Classificação |
| --- | --- | --- |
| `gateway.ready` | `{ skin, change_events, replay_epoch, heartbeat? }` | diagnóstico |
| `skin.changed` | `{ skin }` | administrativo/fora do MVP |
| `session.info` | metadados de sessão para banner + painéis de tool/skill | core mobile |
| `message.start` | início do streaming do assistant | core mobile |
| `message.delta` | `{ text, rendered? }` | core mobile |
| `message.interim` | `{ text, already_streamed }` | pendente: bloco próprio antes de persistir |
| `message.complete` | `{ text, usage, status: complete|error|interrupted, failure_reason? }` | core mobile |
| `thinking.delta` | `{ text }` | core mobile |
| `reasoning.delta` | `{ text, verbose? }` | core mobile |
| `reasoning.available` | `{ text, verbose? }` | core mobile |
| `status.update` | `{ kind, text }` | core mobile |
| `notification.show` | `{ id, key, kind, level, text, ttl_ms? }` | diagnóstico |
| `notification.clear` | `{ key }` | diagnóstico |
| `tool.start` | `{ tool_id, name, context?, args_text? }` | core mobile |
| `tool.generating` | `{ name }` | core mobile |
| `tool.progress` | `{ name, preview }` | core mobile |
| `tool.output_risk` | `{ tool_id, name, risk, findings, redacted }` | pendente: sinal de segurança, nunca texto do assistant |
| `tool.complete` | `{ tool_id, name, error?, summary?, duration_s?, inline_diff?, todos? }` | core mobile |
| `clarify.request` | **removido do gateway atual** | clarify chega como server request `clarify` (ver seção de server requests); o Mobile não trata mais este evento |
| `approval.request` | `{ command, description, allow_permanent? }` | interação protegida |
| `sudo.request` | `{ request_id }` | interação protegida |
| `sudo.expire` | `{ request_id }` limpa prompt sudo expirado | interação protegida |
| `secret.request` | `{ prompt, env_var, request_id }` | interação protegida |
| `secret.expire` | `{ request_id }` limpa prompt secret expirado | interação protegida |
| `background.complete` | `{ task_id, text }` | core mobile |
| `billing.step_up.verification` | `{ verification_url, user_code }` | administrativo/fora do MVP |
| `review.summary` | `{ text }` | core mobile |
| `browser.progress` | `{ message }` | administrativo/fora do MVP |
| `voice.status` | `{ state }` | administrativo/fora do MVP |
| `voice.transcript` | `{ text, no_speech_limit? }` | administrativo/fora do MVP |
| `subagent.spawn_requested` | `{ subagent_id?, task_index, goal?, depth?, parent_id? }` | core mobile |
| `subagent.start` | `{ subagent_id?, task_index, goal?, depth?, parent_id? }` | core mobile |
| `subagent.thinking` | `{ text }` | core mobile |
| `subagent.tool` | `{ tool_name?, tool_preview?, text? }` | core mobile |
| `subagent.progress` | `{ text }` | core mobile |
| `subagent.complete` | `{ status, summary?, text?, duration_seconds? }` | core mobile |
| `gateway.stderr` | sintetizado do stderr do filho | diagnóstico |
| `gateway.protocol_error` | sintetizado de stdout malformado | diagnóstico |
| `gateway.start_timeout` | `{ cwd?, python?, stderr_tail? }` | diagnóstico |

### Semântica de streaming que o Mobile deve preservar

- `message.delta` acrescenta texto da resposta do assistant; `message.complete` fecha a mensagem, trazendo o texto final e, quando emitidos, `rendered`, `usage` e `status`.
- `reasoning.delta` é reasoning nativo incremental **quando o provider o emite**. É um bloco distinto do texto da resposta e deve respeitar os controles de visibilidade/produto aplicáveis.
- `reasoning.available` é texto disponível como preview/fallback. Nunca o promova, concatene ou rotule como chain-of-thought nativo.
- `thinking.delta` é sinal/estado de pensamento para spinner ou status; não é reasoning e não deve ser apresentado como tal.
- `tool.start` abre a atividade identificada por `tool_id`; `tool.complete` a encerra e pode trazer erro, resumo, duração, diff inline ou todos. `tool.progress` é preview transitório por nome, não uma mensagem persistida do assistant.

## Métodos RPC do snapshot

### Contrato MVP observado no código

Esta seção é estrita: foi revalidada contra a implementação do TUI Gateway em
2026-08-30. **Não é OpenAPI.** Ela contém apenas os parâmetros e resultados confirmados para
a allowlist MVP; nenhuma versão é inferida a partir deste documento.

| Método | Parâmetros necessários / opcionais confirmados | Resultado confirmado |
| --- | --- | --- |
| `session.create` | Nenhum obrigatório. Opcionais: `cols` (default `80`), `messages`, `title`, `parent_session_id`, `cwd`, `source`, `profile`, `model`, `provider`, `reasoning_effort`, `fast`, `close_on_disconnect`. | `session_id`, `stored_session_id`, `message_count`, `messages`, `info` |
| `session.list` | `limit` opcional (default `200`). | `sessions[]` com `id`, `title`, `preview`, `started_at`, `message_count`, `source` |
| `session.most_recent` | Nenhum. | `session_id` (pode ser `null`); quando presente: `title`, `started_at`, `source` |
| `session.resume` | `session_id` obrigatório. Opcionais: `cols` (default `80`), `profile`, `lazy`, `source`, `close_on_disconnect`, `eager_build`. | `session_id` (live), `resumed`, `message_count`, `messages`, `info`, `inflight`, `running`, `session_key`, `started_at`, `status` |
| `session.history` | `session_id` obrigatório: o id **live** retornado por create/resume. | `count`, `messages` |
| `prompt.submit` | `session_id` e `text`; `truncate_before_user_ordinal` opcional. | `status: "streaming"` (ou envelope de erro) |
| `session.steer` | `session_id`, `text` não vazio. | `status: "queued"\|"rejected"`, `text` |
| `session.interrupt` | `session_id`. | `status: "interrupted"` |
| `clarify.lock` | `request_id` (id do server request), `question_id` (`qid`), `answer` (string; multi-select é JSON em string; `null` = skip). | `{status:"ok", remaining:[qid...]}`; `{status:"expired"}` quando o pedido já acabou. O último lock resolve o pedido. `clarify.respond` não existe mais no gateway atual. |
| `approval.respond` | `session_id`; `choice` opcional (default `deny`); `all` opcional (default `false`). | `resolved` |
| `file.attach` | `session_id` live, `path`, `data_url` e `name`. | `ref_text`, usado como referência `@file:` no prompt |

`stored_session_id` (de `session.create`) e `session_key` (de `session.resume`) são identificadores duráveis; `session_id` é o identificador **live**. O cliente deve usar o `session_id` live em `prompt.submit`, `session.history`, `session.steer`, `session.interrupt` e `approval.respond`, sem trocar por um identificador durável. O Mobile também deve rejeitar localmente `text` vazio antes de `prompt.submit`, mesmo que o handler atual não o valide explicitamente.

Os 107 métodos restantes continuam somente como nomes inventariados: não há contrato de parâmetros ou retorno inferido para eles. “MVP” identifica a allowlist necessária; “bloqueado” exige UX/autorização específica antes de ser exposto.

| Domínio | Métodos | Decisão Mobile |
| --- | --- | --- |
| Sessões e histórico | `session.activate`, `session.active_list`, `session.branch`, `session.close`, `session.compress`, `session.context_breakdown`, `session.create`, `session.cwd.set`, `session.delete`, `session.history`, `session.interrupt`, `session.list`, `session.most_recent`, `session.resume`, `session.save`, `session.status`, `session.steer`, `session.title`, `session.undo`, `session.usage` | **MVP:** `session.create`, `session.resume`, `session.list`/`session.most_recent` (criar/resumir), `session.history` (histórico), `session.steer`, `session.interrupt`. Demais: fora do MVP; `session.cwd.set` bloqueado até autorização de ambiente. |
| Prompt e comandos de chat | `prompt.background`, `prompt.submit`, `command.dispatch`, `command.resolve`, `commands.catalog`, `complete.path`, `complete.slash`, `clipboard.paste`, `input.detect_drop`, `paste.collapse`, `slash.exec` | **MVP:** somente `prompt.submit` (enviar). `prompt.background` bloqueado até ter contrato, UX e autorização específicos. Demais fora do MVP; `slash.exec` bloqueado até UX/autorização. |
| Interações sensíveis | `approval.respond`, `clarify.lock`, `secret.respond`, `sudo.respond`, `terminal.read.respond` | **MVP:** `clarify.lock` (clarify via server request), `approval.respond`, com confirmação explícita. `secret.respond`, `sudo.respond`, `terminal.read.respond` bloqueados até UX segura e autorização específica. |
| Tools, skills e plugins | `tools.configure`, `tools.list`, `tools.show`, `toolsets.list`, `skills.manage`, `skills.reload`, `plugins.list`, `plugins.manage` | Leitura (`tools.list`, `tools.show`, `toolsets.list`, `plugins.list`) fora do MVP. Configuração/gestão bloqueadas até UX/autorização. |
| Arquivos e anexos | `file.attach`, `image.attach`, `image.attach_bytes`, `image.detach`, `pdf.attach` | **MVP documentado:** somente `file.attach`, com seleção explícita do arquivo, limite local de 25 MB, sessão segura do Dashboard e ticket efêmero. Demais métodos continuam fora do MVP. |
| Terminal, shell e processo | `cli.exec`, `shell.exec`, `terminal.resize`, `process.kill`, `process.list`, `process.stop` | **Bloqueados** até UX/autorização específica. |
| Segredos, configuração e runtime | `config.get`, `config.set`, `config.show`, `reload.env`, `reload.mcp`, `setup.runtime_check`, `setup.status`, `model.disconnect`, `model.options`, `model.save_key` | `config.get`, `config.show`, `model.options`, `setup.status` fora do MVP; config, reload, runtime, key e model mutation **bloqueados** até UX/autorização. |
| Projetos e rollback | `project.facts`, `projects.discover_repos`, `projects.project_sessions`, `projects.record_repos`, `projects.tree`, `rollback.diff`, `rollback.list`, `rollback.restore` | Leitura fora do MVP; descoberta/gravação de repos e restore bloqueados até UX/autorização. |
| Agentes, delegação e handoff | `agents.list`, `delegation.pause`, `delegation.status`, `handoff.fail`, `handoff.request`, `handoff.state`, `spawn_tree.list`, `spawn_tree.load`, `spawn_tree.save`, `subagent.interrupt` | Leitura/status fora do MVP; pausa, handoff, save e interrupção bloqueados até UX/autorização. |
| Browser, voz e preview | `browser.manage`, `preview.restart`, `voice.record`, `voice.toggle`, `voice.tts` | **Bloqueados** até UX/autorização específica. |
| Billing, créditos e verificação | `billing.auto_reload`, `billing.charge`, `billing.charge_status`, `billing.state`, `billing.step_up`, `credits.view`, `verification.status` | Administrativo/fora do MVP; operações de cobrança **bloqueadas**. |
| Cron, aprendizado e insights | `cron.manage`, `insights.get`, `learning.delete`, `learning.detail`, `learning.edit`, `learning.frames` | Leitura fora do MVP; cron e mutações de aprendizado bloqueados até UX/autorização. |
| Pet | `pet.cancel`, `pet.cells`, `pet.disable`, `pet.export`, `pet.gallery`, `pet.generate`, `pet.generate.status`, `pet.hatch`, `pet.info`, `pet.info.meta`, `pet.remove`, `pet.rename`, `pet.scale`, `pet.select`, `pet.thumb` | Administrativo/fora do MVP; mutações bloqueadas até UX/autorização. |
| LLM isolado | `llm.oneshot` | Bloqueado até UX, custo e autorização específicos. |

## Delta de versão 0.18.2 para 0.19.0

O servidor desta implantação foi atualizado para `0.19.0` em 2026-07-25. O snapshot
versionado continua sendo o do `0.18.2`: renová-lo exige uma captura autenticada e
controlada, conforme o procedimento no [README](README.md). Enquanto isso, esta
seção registra a diferença apurada **no código-fonte** do checkout `0.19.0`
(`pyproject.toml` em `version = "0.19.0"`, tag `v2026.7.20`), extraindo os métodos
pelo decorator `@method("...")` em `tui_gateway/*.py` e os eventos por
`ui-tui/README.md`, que é a mesma fonte do campo `events_from_tui_readme`.

**Conclusão para o Mobile na medição de versão:** os 10 métodos originais da
allowlist e os 37 eventos continuam existindo, com os mesmos nomes. Em
2026-08-07 o usuário autorizou `file.attach` como décimo primeiro método para o
fluxo móvel de anexos; essa ampliação é uma decisão posterior de produto, não
uma mudança inferida do delta de versão.

Métodos: 117 no `0.18.2`, 124 no `0.19.0`.

| Mudança | Métodos | Decisão Mobile |
| --- | --- | --- |
| Adicionados | `session.redirect`, `subscription.change`, `subscription.preview`, `subscription.resume`, `subscription.state`, `subscription.upgrade`, `system.battery`, `usage.bars` | Todos fora do MVP. Assinatura e cobrança são administrativas e permanecem **bloqueadas**; `session.redirect`, `system.battery` e `usage.bars` ficam apenas inventariados, sem contrato inferido. |
| Removido | `credits.view` | Some do `0.19.0`. Já estava fora do MVP, então não há impacto; a linha do domínio de billing acima permanece descrevendo o snapshot `0.18.2`. |

Eventos: os 37 do snapshot continuam presentes no `0.19.0` e nenhum evento novo foi
encontrado. A união permanece válida.

Fora do gateway TUI, o **API Server** mudou o envelope de erro de autenticação: o
`401` passou de `{code: invalid_api_key, type: invalid_request_error}` para
`{code: gateway_auth_failed, type: gateway_auth_error}`. A **forma**
`{error: {message, type, code}}` é a mesma, então o cliente Mobile continua lendo
corretamente; há teste fixando os dois envelopes.

Nada aqui amplia a superfície consumida: a allowlist do adapter segue restrita ao
MVP até haver contrato, UX e autorização específicos.

## Limite de estabilidade

Esta é uma interface consumida pelo Desktop e documentada pelo código. Não existe schema OpenAPI nem capability versionada para cada notificação. O Mobile deve manter allowlists de métodos/eventos, ignorar com segurança e registrar de forma redigida eventos desconhecidos, e revalidar o inventário a cada versão do Hermes antes de ampliar a superfície.

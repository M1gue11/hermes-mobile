# Contrato medido: Hermes 0.22.5

Medido em 2026-10-31 por leitura do código do `hermes-agent` em
`v0.22.5+canary.20261031T064409Z-39-gd33d4fd9e7`, sem executar o servidor.
Este documento registra só o que mudou para o Mobile e as decisões
tomadas no cliente. Os demais endpoints que o app usa seguem compatíveis.

## Defeito do servidor: `GET /v1/skills` sempre responde `500`

`gateway/platforms/api_server.py` chama
`find_all_skills(skip_disabled=False, include_editorial=True)`, mas
`tools/skills_tool.py` não aceita mais `include_editorial` desde o revert
`0dcadf6f41`. O `TypeError` vira
`500 {"error":{"message":"Failed to enumerate skills","type":"server_error"}}`.
O teste do servidor usa um mock que aceita qualquer argumento e não pega o
defeito. `/v1/capabilities` continua anunciando `skills_api: true`.

Decisões no cliente:

- O boot não carrega mais skills. Antes, essa falha derrubava o seletor de
  modelos e a folha de Contexto.
- `skillsCatalogProvider` tenta o API Server e, em `5xx` ou `404`, usa
  `GET /api/skills` do Dashboard. Se o Dashboard também falhar, o erro mostrado
  continua sendo o do API Server.

## Catálogo de skills do Dashboard

Rotas em `hermes_cli/web_routers/skills.py`, todas com sessão do Dashboard e
`?profile=` opcional:

| Método | Caminho | Corpo | Resposta |
| --- | --- | --- | --- |
| `GET` | `/api/skills` | - | lista solta `[{name, description, category, enabled, usage, provenance}]` |
| `GET` | `/api/skills/content?name=` | - | `{name, content, path}`; `404` se não existir |
| `PUT` | `/api/skills/content` | `{name, content, profile?}` | reescrita integral |
| `PUT` | `/api/skills/toggle` | `{name, enabled, profile?}` | `{ok, name, enabled}` |
| `POST` | `/api/skills` | `{name, content, category?, profile?}` | criação |

Não há exclusão genérica de skill local, só `hub/uninstall`. O Mobile usa as
quatro primeiras rotas (A65). `GET /api/skills` inclui as desativadas
(`skip_disabled=True` ignora o filtro de desativadas). A reescrita valida o
frontmatter (`name` e `description`), o tamanho (100 mil caracteres) e passa
pelo scan de segurança; uma recusa volta como `400` com a causa em `detail`.
Não há versão nem ETag: a última gravação vence, por isso o app relê o
`SKILL.md` antes de gravar.

## Mídia entregue pelo agente (`MEDIA:`)

O agente entrega um arquivo do servidor escrevendo `MEDIA:<caminho absoluto>`
na resposta. Ferramentas que guardam imagem (MCP, capturas, cache) devolvem
essa forma; a geração por FAL devolve uma URL remota, que o modelo escreve
como `![alt](url)`.

- `GET /api/media?path=` (`hermes_cli/web_routers/files.py`), com sessão do
  Dashboard, devolve `{"data_url": "data:<mime>;base64,..."}`. Só serve
  `.png .jpg .jpeg .gif .webp .svg .bmp .ico`, até 25 MB, e só dentro de
  `HERMES_HOME/images`, `screenshots` e `cache`, com o caminho resolvido.
  Recusas em `detail`: `415` tipo, `403` fora das pastas, `404` ausente, `413`
  grande demais.
- O chat do Dashboard não reescreve `MEDIA:`: o texto chega cru pelo TUI e pelo
  histórico. Só as rotas de chat, completions e responses do API Server trocam
  a diretiva por `![image](data:...)` (até 5 MB); a Runs API não troca nada.
- O prompt de sistema não orienta o modelo para `source: mobile` (não há
  `PLATFORM_HINTS["mobile"]`). Para que o agente prefira `MEDIA:` ao falar com
  o celular, o operador pode configurar `platform_hints.mobile` no servidor.
- `GET /api/media/proxy?url=` busca imagens de CDNs permitidos (`fal.media`,
  `storage.googleapis.com`) para clientes sem rota até eles. O Mobile ainda não
  usa: o aparelho costuma alcançar o CDN direto.

No Mobile (A96), `MEDIA:` com caminho absoluto vira figura lida por
`/api/media`; SVG, ICO e não imagens ficam como referência com o caminho.
Sem Dashboard, a referência diz para conectá-lo. Na cauda do streaming o
caminho pode estar pela metade, e nada é pedido até o bloco assentar.

## Saúde, logs e reinício do gateway

Usados pela tela Servidor (A97). Rotas do Dashboard em
`hermes_cli/web_routers/status.py` e `actions.py`; a do API Server em
`gateway/platforms/api_server.py`.

| Rota | Auth | Uso no Mobile |
| --- | --- | --- |
| `GET /api/status` | pública | `gateway_running`, `gateway_state` (`starting`, `running`, `degraded`, `draining`, `stopping`, `stopped`, `startup_failed`), `gateway_updated_at`, `gateway_exit_reason`, `active_sessions`, `active_agents`, `gateway_busy`, `components.platforms.{configured,connected}` |
| `GET /api/system/stats` | Dashboard | `hostname`, `hermes_version`, `cpu_percent`, `memory`, `disk` (do `HERMES_HOME`), `uptime_seconds` (da máquina); tudo opcional sem `psutil` |
| `GET /api/logs` | Dashboard | `file` (`agent`, `errors`, `gateway`…), `lines` até 500, `level` mínimo em maiúsculas (minúscula vira sem filtro), `search` sobre as últimas 2.000 linhas; devolve `{file, lines}` cru, do mais antigo para o mais novo |
| `POST /api/gateway/restart` | Dashboard | sem corpo; roda `hermes gateway restart --interrupt`; pedido repetido em 10 s reaproveita o anterior |
| `GET /api/actions/gateway-restart/status` | Dashboard | `{running, exit_code, pid, lines}`; `exit_code` 0 só diz que o comando foi entregue |
| `GET /health/detailed` | Bearer | `status`, `readiness.checks.{nome: {status, detail?}}`, `api_server.active_runs`, `metrics_today` |

- O gateway não informa tempo de atividade. O app considera que voltou quando
  `gateway_state` é `running` com `gateway_updated_at` posterior ao lido antes
  do pedido; compara dois instantes do servidor, nunca o relógio do celular.
- Reiniciar derruba o API Server (8642) e os WebSockets servidos pelo próprio
  gateway. O `hermes dashboard` avulso (9119) segue de pé e mostra a
  transição; ele pode perder o registro em memória da ação, que então volta
  com `exit_code` nulo.
- Os logs são redigidos na escrita pelo `RedactingFormatter`; `update`,
  `handoff` e `mcp` podem não ser, e o app não os oferece.
- `POST /api/gateway/stop` existe, mas o app não oferece: derrubaria o próprio
  acesso.

## Busca no conteúdo (`/api/sessions/search`)

`hermes_cli/web_routers/sessions.py`, com sessão do Dashboard. `q` vazio
devolve `{"results": []}`; `limit` vai de 1 a 100 (padrão 20); aceita
`source`, `sources` e `exclude_sources`.

- Ordem: id da sessão primeiro, depois o conteúdo das mensagens (FTS5 com
  prefixo, `nimb` acha `nimbus`), depois títulos. Cada linhagem de compressão
  aparece uma vez, apontando para a sessão mais recente (`session_id` e `id`),
  com `lineage_root`.
- Cada resultado traz os campos da sessão (`title`, `source`, `model`,
  `last_active`, `started_at`, `message_count`, `preview`…), o que permite
  abrir a conversa direto, mais `snippet` e `role` da mensagem que casou.
- O trecho marca o termo com `>>>` e `<<<`. Saídas de ferramenta também são
  indexadas, então JSON de ferramenta aparece com frequência.

No Mobile (A99), a lista de conversas consulta a busca a partir de dois
caracteres, 400 ms depois da última tecla, e mostra "No conteúdo das
conversas" abaixo dos resultados locais, sem repetir os que já estão na lista.

## Fala (`POST /api/audio/speak`)

`hermes_cli/web_routers/audio.py`, com sessão do Dashboard. Corpo `{text}`;
texto vazio dá `400`. Usa a cadeia de TTS de `tts.` no `config.yaml` do perfil
e devolve `{ok, data_url, mime_type, provider}`, com o arquivo temporário
apagado no servidor. Falha do provedor volta `400` com a causa em `detail`.
O servidor também normaliza o texto para fala (`tools/tts_text_normalize.py`),
mas o app já manda o texto sem markdown. No emulador, uma frase curta levou
cerca de 6 s para sintetizar.

## Pareamento de plataformas (`/api/pairing*`)

`hermes_cli/web_routers/ops.py` e `gateway/pairing.py`, com sessão do
Dashboard e `?profile=` opcional.

| Rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /api/pairing` | - | `{pending: [{platform, request_id, user_id, user_name, age_minutes}], approved: [{platform, user_id, user_name, approved_at}]}` |
| `POST /api/pairing/approve` | `{platform, request_id}` ou `{platform, code}` | `{ok, user}`; `404` vencido; `429` só no caminho do código, após tentativas erradas |
| `POST /api/pairing/revoke` | `{platform, user_id}` | `{ok}`; `404` se não estava aprovado |
| `POST /api/pairing/clear-pending` | - | `{ok, cleared}` |

- O código enviado à pessoa nunca volta pela API; o app aprova pelo
  `request_id` (16 hex). Pedidos antigos sem hash vêm com `request_id` vazio
  e só podem ser aprovados pelo código.
- Aprovar também espelha a pessoa na allowlist da plataforma, quando
  configurada. `user_id` pode vir como número.
- Não há recusa individual: só `clear-pending`, que descarta todos.

## Toolsets e servidores MCP

Rotas do Dashboard em `hermes_cli/web_routers/tools.py` e `mcp.py`.

| Rota | Uso no Mobile |
| --- | --- |
| `GET /api/tools/toolsets` | lista solta `[{name, label, description, platform, platform_label, enabled, available, configured, tools[]}]` |
| `PUT /api/tools/toolsets/{name}` | `{enabled}`; grava `platform_toolsets` da plataforma do toolset (`cli` para quase todos); nome fora do conjunto configurável dá `400`. Ligar pode disparar instalação em segundo plano (`post_setup_started`) |
| `GET /api/mcp/servers` | `{servers: [{name, transport, url, command, args, env (mascarado), auth, enabled, tools, source, plugin}]}` |
| `PUT /api/mcp/servers/{name}/enabled` | `{enabled}`; `409` para servidor de plugin, `404` se não existe; vale na próxima sessão |
| `POST /api/mcp/servers/{name}/test` | conecta, lista e desconecta; falha volta `200` com `{ok: false, error}` |

- As sessões do TUI montam o agente com `platform_toolsets.cli`
  (`tui_gateway/agent_factory.py`), então os toolsets alternados valem para as
  conversas do app a partir da próxima sessão.
- O app não mostra `command`, `args`, `url` nem `env` de servidor MCP e não
  oferece instalação, edição de variáveis ou catálogo (A100).
- `save_config` reescreve o `config.yaml` do perfil a cada alternância.

## Uso por período (`/api/analytics/usage`)

`hermes_cli/web_routers/analytics.py`, com sessão do Dashboard. `days` vai de 1
a 365 (fora disso o servidor limita). Devolve `period_days`, `totals`
(`total_input`, `total_output`, `total_cache_read`, `total_reasoning`,
`total_estimated_cost`, `total_actual_cost`, `total_sessions`,
`total_api_calls`), `daily` (`day` no calendário local do servidor, só os dias
com sessão), `by_model`, `by_task`, `skills` e `tools`.

- Conta sessões por `started_at`, de todas as origens (Desktop, Telegram,
  rotinas, Mobile). Somas podem vir `null` quando não há linha.
- `by_model` inclui chamadas auxiliares (compressão, visão) que os totais não
  contam; a soma dos modelos passa do total. O app calcula a fatia de cada
  modelo sobre a soma dos modelos.
- Provedor por assinatura (`openai-codex`) não registra custo: os totais de
  custo vêm `0`, e o app destaca tokens em vez de "US$ 0".
- Tokens e custo de uma conversa já vêm em `GET /api/sessions` do API Server
  (`input_tokens`, `output_tokens`, `estimated_cost_usd`, `actual_cost_usd`) e
  aparecem na folha da conversa.
- Uso de contexto da sessão viva (`session.usage`, `session.context_breakdown`)
  só existe no TUI. Os dois métodos estão fora da allowlist do app e esperam
  autorização explícita.

## Aprovação da Runs API sob session authority

Com a session authority ativa, que é o padrão do gateway, o evento
`approval.request` de `/v1/runs/{id}/events` traz `request_id` e
`execution_generation` (int). A resposta em `POST /v1/runs/{id}/approval`
precisa ter **exatamente** `{request_id, execution_generation, choice}`, sem
os apelidos `approve`/`allow`. Qualquer outra forma devolve `400 invalid_params`
(`api_server_authority_runs.py`, `respond_run`).

Códigos de recusa: `400 invalid_params`, `409 stale_generation`,
`409 approval_not_pending` e `409 not_found`. O cliente mapeia
`stale_generation` para "pedido já resolvido".

O caminho legado aceita o mesmo corpo e usa o `request_id` para resolver só o
pedido indicado. Por isso o cliente sempre manda os três campos quando o evento
traz a geração, e cai em `{choice}` quando o evento não traz.

Eventos novos do SSE que o cliente passou a tratar:

- `approval.settled {prompt_id, execution_generation}`: o pedido fechou, sem
  dizer qual escolha venceu.
- `run.interrupted {error}`: terminal, tratado como cancelamento.

Ainda sem tratamento no fallback Runs: `clarify.request` e
`/v1/runs/{id}/clarify`, `run.steered`, `run.queued` e `/v1/runs/{id}/steer`.
O chat ao vivo usa o TUI Gateway, que já cobre clarify e steer.

## `GET /api/sessions` passou a honrar `include_children`

O padrão (`false`) lista raízes e branches/resets visíveis, e esconde subagents
e continuações de compressão (`hermes_state_sessions.py`). Com `true` entram
também subagents, segmentos superados e ancestrais de compressão. O Mobile
mandava `true`, então deixou de mandar o parâmetro.

Cada sessão traz agora `is_internal_child` (marcador `_delegate_from` do
subagent), sempre presente. É o critério seguro que B14 pedia.

## Sem mudança para o Mobile

- `GET /api/model/options`: ainda `{providers, model, provider}`. Linhas
  ganharam campos opcionais (`plan_usage`, `usage_levels`, `usage`, `limit`,
  `featured_models`, `source`), ignorados pelo parser.
- `/health`, `/v1/capabilities` (`runs_idempotency` virou objeto, campo não
  lido), `/v1/models`, `/v1/toolsets`, sessões, runs, `/api/audio/transcribe`,
  `/api/auth/ws-ticket` e `/api/ws`.

## Diagnóstico da "Resposta inesperada" na folha de Modelo

A folha mostra o erro do boot, não o do inventário. O boot desembrulhava
`ParallelWaitError` com um cast para `AsyncError`, mas o nome resolvia para o
`AsyncError` do Riverpod, exportado por `riverpod_annotation`. O cast falhava,
e toda falha de boot virava `TypeError` e, na tela, "Resposta inesperada" sem
código HTTP. A falha real era o `500` de `/v1/skills`.

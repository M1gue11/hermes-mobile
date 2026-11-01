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

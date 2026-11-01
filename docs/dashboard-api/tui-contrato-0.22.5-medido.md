# Contrato TUI Gateway e Dashboard no 0.22.5 (B0)

Auditoria de leitura do `hermes-agent` em `v0.22.5+canary.20261031` contra o
que o Mobile usa, a partir da linha de base de
[mobile-streaming-audit-0.21.6.md](mobile-streaming-audit-0.21.6.md). Caminhos
abaixo são do repositório `hermes-agent`.

No deployment padrão (Dashboard em `:9119`, sem session authority) nada no
0.22.5 quebra o cliente. Login, ticket, `/api/ws`, close codes e os métodos
usados seguem iguais; o que mudou está nas seções seguintes.

## Corrigido no cliente

- **Histórico concluído nunca vinha do Dashboard.** `session.history` resolve
  só ids de sessões vivas (`tui_gateway/session_registry.py:305-320`) e
  respondia `4001` ao id durável; o controller engolia o erro e ficava com o
  snapshot do API Server, depois de pagar ticket e socket a cada abertura. O
  cliente agora lê `GET /api/sessions/{id}/messages?inline_images=false`
  (`hermes_cli/web_routers/sessions.py:739`), a mesma projeção que o Desktop
  pré-carrega. Página cheia (500) cede ao snapshot do API Server para não
  cortar o começo. A etapa `session.history(stored)` saiu do diagnóstico.
- **Pedidos de servidor que o celular não mostra.** `theme.apply` entrou nos
  pedidos de janela do Desktop; `theme.pick` e `setup_beat` são cartões do
  Desktop. O gateway fecha o pedido no primeiro erro que não seja `4404`
  (`tui_gateway/server_requests.py:281-302`), então o `-32601` do celular
  tomava a vez do Desktop. Os três agora recebem `4404`.

## Pendente (degrada, não quebra)

- **Prompt encaminhado ao dono do gateway (RT-37).** Quando o ledger do gateway
  tem trabalho para a mesma sessão, `prompt.submit` responde
  `status: "queued"`, `forwarded: true`, e só `message.start` e
  `message.complete` são repassados (`tui_gateway/owner_forward.py:41-44`). Se
  o repasse perde o dono, chega `message.complete {"text": ""}`
  (`owner_forward.py:214-218`) e o celular mostra resposta vazia. Correção
  sugerida: com `forwarded`, reler o histórico ao concluir.
- **Session authority.** Quando o Dashboard é servido pelo listener do próprio
  gateway, `gateway.ready` traz `session_authority: true`
  (`tui_gateway/ws.py:647`) e o fallback legado recusa `session.*`, `prompt.*`
  e `message.*` (`tui_gateway/ws_legacy_fallback.py:31-58`); clarify usa
  `clarify.respond`. Só `gateway/run_api.py:97` liga esse modo; o
  `hermes dashboard` do Docker não. O cliente deveria detectar a flag e avisar
  em vez de falhar no meio do turno. Não verificado ponta a ponta.

## Novos e opcionais

- `tool.progress` voltou a ser emitido para progresso MCP
  `{tool_id, name, progress, total?, percent?, message?}`, no máximo um a cada
  500 ms (`tui_gateway/contracts/events.py:457-469`). O cliente o tirou da
  allowlist e hoje o ignora.
- `skills.changed {}` (`events.py:865`): sinal para recarregar o catálogo de
  Skills.
- `message.start/delta/interim` trazem `turn_id`; deltas trazem `segment` e
  `offset` em unidades UTF-16 (`events.py:135-191`).
- `message.start` pode trazer `display_kind`, `display_text` e
  `notification_category` em turnos de automação.
- `persisted_turn` ganha `user_row_ids` e `submission_id`; há
  `error_surface.usage_limit` (`events.py:206-278`).
- `session.usage`: `usage` virou opcional e há `plan_gauge`
  (`events.py:318-351`, `contracts/common.py:19-54`).
- `onboarding.ended`, `agent.print` (só com authority) e `detail` em
  `notification.show`.
- `client.capabilities` devolve `canonical_clarify_batch: true`; método novo
  `request.answer {id, result}` responde pedido de servidor por RPC.
- Código `4064` (backend de config indisponível); `5035` (backend se
  aposentando, reconectar) já existia e o cliente não o trata como retentável.

## Removidos (o cliente não usava)

Eventos `layout.apply`, `browser.controller.command` e
`browser.controller.cancel`; métodos `session.start_chat` e `setup_choose`.

## Inalterado

`POST /auth/password-login`, `POST /api/auth/ws-ticket` (`ttl_seconds: 30`, uso
único), ticket em `?ticket=` ou subprotocolo, guarda de Host/Origin (movida
para `web_server_boundary.py`), close codes `4401`/`4403`/`1011`, erros
`4001`/`5032`/`-32000`/`4404`, parâmetros de todos os métodos usados (extras
são proibidos, `4000`), `message.complete`, `tool.*`, `subagent.*`,
`todo.updated`, `approval.cancelled`, `session.reclaimed`, `sessions.changed`,
`session.info`, `/api/model/options`, `/api/audio/transcribe` e `/api/skills*`.

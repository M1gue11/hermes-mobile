# Recursos do Hermes 0.22.5 que o Mobile ainda não usa

Mapa de leitura do `hermes-agent` em `v0.22.5+canary.20261031`, para escolher
os próximos itens do backlog. Nada aqui está decidido. Legenda de superfície:
**A** = API Server (chave Bearer, `:8642`), **D** = Dashboard (sessão do
login), **R** = RPC do TUI Gateway por `/api/ws`. Caminhos de código são do
repositório `hermes-agent`.

Valor é para quem opera o agente pelo celular. Esforço: P (dias), M (uma
semana), G (mais que isso ou depende de UX nova de streaming).

## Prioridade sugerida

| # | Recurso | Superfície | Valor | Esforço | Cuidado |
| --- | --- | --- | --- | --- | --- |
| 1 | Agendamentos (cron): listar, pausar, retomar, disparar, criar | A `/api/jobs*` (`gateway/platforms/api_server.py:1581`) | Alta | M | `DELETE` destrói; o prompt roda depois sem supervisão |
| 2 | Imagens que o agente gera (`MEDIA:` na resposta) | D `GET /api/media?path=` (`hermes_cli/web_routers/files.py:427`) | Alta | P/M | só tipos e pastas permitidos pelo servidor |
| 3 | Saúde, logs e restart do gateway | A `/health/detailed`; D `/api/logs`, `/api/system/stats`, `POST /api/gateway/restart` (`status.py:894`, `actions.py:160`) | Alta | P leitura, M ações | `stop` derruba o próprio acesso do app |
| 4 | Custo e uso de contexto na conversa | R `session.usage`, `session.context_breakdown`; D `/api/analytics/usage` | Alta | P/M | billing parece específico do provider Nous (não verificado) |
| 5 | Busca no servidor, desfazer e compactar | D `GET /api/sessions/search?q=` (`sessions.py:286`); R `session.undo`, `session.compress` | Alta | P/M | undo é destrutivo; exigem sessão ociosa |
| 6 | Ligar e desligar toolsets e servidores MCP | D `PUT /api/tools/toolsets/{name}`, `PUT /api/mcp/servers/{name}/enabled`; R `tools.configure` | Alta | P | não expor `/env` nem chaves |
| 7 | Aprovar pareamento de plataformas (Telegram, WhatsApp) | D `/api/pairing`, `approve`, `revoke` (`ops.py:84-131`) | Alta | P | aprovar dá acesso ao agente a terceiros |
| 8 | Ouvir a resposta (TTS) | D `POST /api/audio/speak` (`audio.py:295`) | Alta | P simples, G streaming | - |

Depois desses: slash commands (`commands.catalog`, `complete.slash`,
`slash.exec`) e pergunta lateral (`prompt.btw`); subagentes e processos em
segundo plano (`subagent.list/tail/interrupt`, `process.list/kill`); hub de
Skills (`/api/skills/hub/search`, `preview`, `scan`, `install`), que completa a
tela entregue no A65; memória e curator (`/api/memory`, `/api/learning/*`);
checkpoints (`rollback.list/diff/restore`); perfis (`/api/profiles*`); troca do
modelo padrão global (`POST /api/model/set`).

## Já sinalizados pela auditoria do contrato

Ver [tui-contrato-0.22.5-medido.md](../dashboard-api/tui-contrato-0.22.5-medido.md):
`tool.progress` de MCP, `skills.changed` para recarregar o catálogo,
`turn_id`/`segment`/`offset` nos deltas e `session.usage` com `plan_gauge`.

## Não recomendado no celular

Config bruta e variáveis (`/api/config/raw`, `/api/env`, `POST /api/env/reveal`
que devolve segredos), credenciais e OAuth de providers, hooks, backup e
`cli.exec`/`shell.exec`. Expõem segredos ou viram execução remota.

## Fora de escopo

Temas, janela, layout, terminal e console do desktop, plugins do dashboard,
modelos locais, worktrees, compatibilidade OpenAI (`/v1/chat/completions`,
`/v1/responses`). Não há endpoint de push; existe o WebSocket `/api/events`
(pub/sub por canal), ainda não verificado como fonte de alertas para o A60.

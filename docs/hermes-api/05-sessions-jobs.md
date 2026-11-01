# Sessions API e Jobs API

## Sessions API

Endpoints sob `/api/sessions/*` permitem gerenciar sessoes Hermes via REST sem depender do dashboard.

Todos usam Bearer auth com `API_SERVER_KEY`.

## Endpoints de sessions

| Metodo | Path | Uso |
| --- | --- | --- |
| `GET` | `/api/sessions` | Lista sessoes. Suporta paginacao e filtros. |
| `POST` | `/api/sessions` | Cria sessao vazia. |
| `GET` | `/api/sessions/{id}` | Le metadados da sessao. |
| `PATCH` | `/api/sessions/{id}` | Atualiza titulo ou `end_reason`. |
| `DELETE` | `/api/sessions/{id}` | Remove sessao. |
| `GET` | `/api/sessions/{id}/messages` | Le historico de mensagens. |
| `POST` | `/api/sessions/{id}/fork` | Cria branch da sessao, similar ao comando CLI `/branch`. |
| `POST` | `/api/sessions/{id}/chat` | Executa um turno sincrono do agente. |
| `POST` | `/api/sessions/{id}/chat/stream` | Executa um turno com SSE. |

## `GET /api/sessions`

Parametros documentados:

- `limit`
- `offset`
- `source`
- `include_children`

Uso no front-end:

- Lista lateral de conversas.
- Paginacao/infinite scroll.
- Separar sessoes por origem.
- Desde o 0.22.5, `include_children=true` traz também subagents e
  continuações de compressão; o padrão já lista branches e resets visíveis.
  Ver [contrato 0.22.5](contrato-0.22.5-medido.md).

## `POST /api/sessions`

Cria uma sessao vazia. Use quando o produto quer reservar uma conversa antes da primeira mensagem.

## `PATCH /api/sessions/{id}`

Atualiza campos como:

- `title`
- `end_reason`

Uso no front-end:

- Renomear conversa.
- Marcar encerramento.

## `POST /api/sessions/{id}/fork`

Cria uma ramificacao da sessao.

Exemplo:

```bash
curl -X POST http://localhost:8642/api/sessions/$ID/fork \
  -H "Authorization: Bearer $API_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"title": "explorar caminho alternativo"}'
```

Uso no front-end:

- Botao "Criar alternativa".
- Comparar duas linhas de investigacao.
- Preservar contexto antes de uma acao arriscada.

## `POST /api/sessions/{id}/chat`

Executa um turno sincrono dentro da sessao.

Use quando:

- A resposta pode ser bloqueante.
- Nao ha necessidade de renderizar progresso.
- O ambiente nao suporta streaming.

## `POST /api/sessions/{id}/chat/stream`

SSE para um turno da sessao.

Eventos documentados:

- `assistant.delta`
- `tool.started`
- `tool.completed`
- `run.completed`

Exemplo:

```bash
curl -N -X POST http://localhost:8642/api/sessions/$ID/chat/stream \
  -H "Authorization: Bearer $API_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"input": "quais arquivos mudaram na ultima hora?"}'
```

Inline images sao suportadas em `chat` e `chat/stream`.

## Jobs API

Endpoints sob `/api/jobs/*` gerenciam trabalhos agendados ou em background.

Todos usam Bearer auth com `API_SERVER_KEY`.

## Endpoints de jobs

| Metodo | Path | Uso |
| --- | --- | --- |
| `GET` | `/api/jobs` | Lista jobs agendados. |
| `POST` | `/api/jobs` | Cria job agendado. |
| `GET` | `/api/jobs/{job_id}` | Le definicao e ultimo estado. |
| `PATCH` | `/api/jobs/{job_id}` | Atualiza parcialmente um job. |
| `DELETE` | `/api/jobs/{job_id}` | Remove job e cancela run em andamento. |
| `POST` | `/api/jobs/{job_id}/pause` | Pausa job. |
| `POST` | `/api/jobs/{job_id}/resume` | Retoma job pausado. |
| `POST` | `/api/jobs/{job_id}/run` | Executa imediatamente, fora do agendamento. |

## Shape de job (medido no 0.22.5)

Handlers em `gateway/platforms/api_server.py` (`_handle_*_job`) e regras em
`cron/jobs.py` do `hermes-agent`. O Mobile usa este contrato desde o A95.

- Respostas: lista `{"jobs": [...]}`, uma rotina `{"job": {...}}`, exclusão
  `{"ok": true}`. Erros vêm como `{"error": "texto"}`, sem o envelope OpenAI.
- Sem o módulo de cron o servidor responde `501`. `jobs_admin` em
  `/v1/capabilities` é fixo em `false` e não serve para detectar suporte.
- `GET /api/jobs` esconde desativadas; pausar grava `enabled: false`, então o
  cliente pede `include_disabled=true` para ver as pausadas.
- Criação: `{name, schedule, prompt, skills?, repeat?, deliver?, paused?}`.
  Nome até 200 caracteres, prompt até 5000 e passa por varredura de injeção;
  recusa é `400` com a causa.
- `schedule` aceita `every 30m`, `every monday 9am`, `every day at 9am`,
  expressão cron de 5 campos ou data ISO (execução única). O servidor devolve
  `schedule` como objeto e `schedule_display` como texto.
- Campos lidos pelo app: `id` (12 hex), `name`, `prompt`, `schedule_display`,
  `enabled`, `state` (`scheduled`, `paused`, `completed`, `error`),
  `paused_reason`, `next_run_at`, `last_run_at`, `last_status` (`ok`, `error`,
  `delivery_failed`, `cancelled`), `last_error`, `repeat {times, completed}` e
  `live_execution` (presente enquanto roda).
- `POST /api/jobs/{id}/run` agenda para o próximo tick e **reativa** uma rotina
  pausada; rotinas terminais (`completed`, `error`) recusam com `400`.
- `PATCH` aceita só `name`, `schedule`, `prompt`, `deliver`, `skills`,
  `skill`, `repeat` e `enabled`. O app ainda não edita rotinas.

## UX recomendada para jobs

- Lista com status, proxima execucao e ultima execucao.
- Acoes: pausar, retomar, executar agora, editar, excluir.
- Confirmacao antes de excluir, porque tambem cancela run em andamento.
- Historico ou link para a run/sessao gerada pelo job, se retornado pela API.


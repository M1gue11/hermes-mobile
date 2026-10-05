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
- Mostrar branches/forks quando `include_children` estiver ativo.

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

## Shape de job

O body de criacao aceita o mesmo formato de `hermes cron`, incluindo:

- prompt
- schedule
- skills
- provider override
- delivery target

A documentacao publica nao detalha todos os campos do schema. Para o front-end:

- Leia jobs existentes e derive o formulario dos campos retornados no ambiente real.
- Valide client-side apenas o essencial.
- Mantenha um editor JSON avancado para campos ainda nao modelados.

## UX recomendada para jobs

- Lista com status, proxima execucao e ultima execucao.
- Acoes: pausar, retomar, executar agora, editar, excluir.
- Confirmacao antes de excluir, porque tambem cancela run em andamento.
- Historico ou link para a run/sessao gerada pelo job, se retornado pela API.


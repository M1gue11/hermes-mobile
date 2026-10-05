# Referencia de endpoints

Base URL:

```txt
http://localhost:8642
```

Auth:

```http
Authorization: Bearer <API_SERVER_KEY>
```

## OpenAI-compatible

| Metodo | Path | Auth | Body principal | Uso no front-end |
| --- | --- | --- | --- | --- |
| `POST` | `/v1/chat/completions` | Sim | `model`, `messages`, `stream` | Chat stateless compativel com OpenAI. |
| `POST` | `/v1/responses` | Sim | `model`, `input`, `instructions`, `store`, `previous_response_id`, `conversation` | Chat com estado server-side e eventos estruturados. |
| `GET` | `/v1/responses/{id}` | Sim | nenhum | Recuperar response armazenada. |
| `DELETE` | `/v1/responses/{id}` | Sim | nenhum | Apagar response armazenada. |
| `GET` | `/v1/models` | Sim | nenhum | Descobrir model ID anunciado. |
| `GET` | `/v1/capabilities` | Sim | nenhum | Descobrir features e endpoints suportados. |
| `GET` | `/v1/skills` | Sim | nenhum | Listar skills disponiveis. |
| `GET` | `/v1/toolsets` | Sim | nenhum | Listar toolsets e tools configuradas. |

## Health

| Metodo | Path | Auth | Uso |
| --- | --- | --- | --- |
| `GET` | `/health` | Nao especificado como gated | Health check basico. |
| `GET` | `/v1/health` | Nao especificado como gated | Health check com prefixo `/v1`. |
| `GET` | `/health/detailed` | Nao especificado como gated | Observabilidade detalhada. |

## Runs API

| Metodo | Path | Auth | Body principal | Uso |
| --- | --- | --- | --- | --- |
| `POST` | `/v1/runs` | Sim | `input`, `session_id`, `instructions`, `conversation_history`, `previous_response_id` | Criar run. |
| `GET` | `/v1/runs/{run_id}` | Sim | nenhum | Polling de status. |
| `GET` | `/v1/runs/{run_id}/events` | Sim | nenhum | SSE de progresso. |
| `POST` | `/v1/runs/{run_id}/stop` | Sim | vazio | Pedir cancelamento. |
| `POST` | `/v1/runs/{run_id}/approval` | Sim | decisao de approval | Resolver aprovacao pendente. |

## Sessions API

| Metodo | Path | Auth | Body/query | Uso |
| --- | --- | --- | --- | --- |
| `GET` | `/api/sessions` | Sim | `limit`, `offset`, `source`, `include_children` | Listar sessoes. |
| `POST` | `/api/sessions` | Sim | nao detalhado | Criar sessao vazia. |
| `GET` | `/api/sessions/{id}` | Sim | nenhum | Ler metadados. |
| `PATCH` | `/api/sessions/{id}` | Sim | `title`, `end_reason` | Atualizar sessao. |
| `DELETE` | `/api/sessions/{id}` | Sim | nenhum | Apagar sessao. |
| `GET` | `/api/sessions/{id}/messages` | Sim | nenhum | Ler historico. |
| `POST` | `/api/sessions/{id}/fork` | Sim | `title` | Criar branch da sessao. |
| `POST` | `/api/sessions/{id}/chat` | Sim | `input` e multimodal inline | Rodar turno sincrono. |
| `POST` | `/api/sessions/{id}/chat/stream` | Sim | `input` e multimodal inline | Rodar turno com SSE. |

## Jobs API

| Metodo | Path | Auth | Body principal | Uso |
| --- | --- | --- | --- | --- |
| `GET` | `/api/jobs` | Sim | nenhum | Listar jobs. |
| `POST` | `/api/jobs` | Sim | shape de `hermes cron` | Criar job. |
| `GET` | `/api/jobs/{job_id}` | Sim | nenhum | Ler job e ultimo estado. |
| `PATCH` | `/api/jobs/{job_id}` | Sim | update parcial | Atualizar job. |
| `DELETE` | `/api/jobs/{job_id}` | Sim | nenhum | Remover job e cancelar run em andamento. |
| `POST` | `/api/jobs/{job_id}/pause` | Sim | vazio | Pausar job. |
| `POST` | `/api/jobs/{job_id}/resume` | Sim | vazio | Retomar job. |
| `POST` | `/api/jobs/{job_id}/run` | Sim | vazio | Executar imediatamente. |

## Headers uteis

| Header | Direcao | Uso |
| --- | --- | --- |
| `Authorization: Bearer <key>` | request | Auth principal. |
| `Content-Type: application/json` | request | Bodies JSON. |
| `Idempotency-Key` | request | Deduplicacao por cerca de 5 minutos. |
| `X-Hermes-Session-Id` | request/response | Identificador de transcript/sessao. |
| `X-Hermes-Session-Key` | request/response | Escopo estavel para memoria de longo prazo. |
| `X-Content-Type-Options: nosniff` | response | Security header. |
| `Referrer-Policy: no-referrer` | response | Security header. |

## Limitacoes documentadas

- Stored responses persistem em SQLite e sobrevivem a restarts, mas ha limite de 100 responses com LRU eviction.
- Upload de arquivos nao e suportado pela API; imagens inline sao suportadas.
- `model` no request e cosmetico: o modelo real e definido no servidor via configuracao Hermes.
- CORS nao vem habilitado por padrao.
- Ferramentas rodam no host do API Server.


# Hermes API - Documentacao enxuta

Documentacao reorganizada da API do Hermes Agent para apoiar a construcao de um front-end proprio.

Fonte principal consultada em 2026-07-10:

- API Server: https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server
- Open WebUI integration: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/open-webui
- Profiles: https://hermes-agent.nousresearch.com/docs/user-guide/profiles

## Visao geral

O API Server do Hermes expõe o agente como um backend HTTP compativel com OpenAI. Um front-end pode falar com ele usando Chat Completions, Responses API ou APIs proprias do Hermes para runs, sessoes, jobs, skills e toolsets.

Base URL padrao:

```txt
http://localhost:8642
```

Base URL para clientes compativeis com OpenAI:

```txt
http://localhost:8642/v1
```

Autenticacao:

```http
Authorization: Bearer <API_SERVER_KEY>
```

## Qual API usar no front-end

| Necessidade do front-end | API recomendada |
| --- | --- |
| Chat simples OpenAI-compatible | `POST /v1/chat/completions` |
| Conversa multi-turn com estado no servidor | `POST /v1/responses` com `previous_response_id` ou `conversation` |
| UX rica com progresso, reconexao e cancelamento | Runs API: `/v1/runs/*` |
| Historico, forks e controle de sessoes Hermes | Sessions API: `/api/sessions/*` |
| CRUD de tarefas agendadas/background | Jobs API: `/api/jobs/*` |
| Descobrir capacidades antes de renderizar UI | `GET /v1/capabilities` |
| Descobrir skills e toolsets disponiveis | `GET /v1/skills` e `GET /v1/toolsets` |

## Arquivos

- [../dashboard-api/README.md](../dashboard-api/README.md): suplemento do Dashboard remoto em `:9119` (sessão cookie); não substitui os contratos deste API Server em `:8642`.
- [01-quick-start.md](01-quick-start.md): habilitar o servidor, testar e configurar variaveis.
- [02-auth-cors-security.md](02-auth-cors-security.md): auth, CORS, headers e cuidados de seguranca.
- [03-openai-compatible.md](03-openai-compatible.md): Chat Completions, Responses, models, capabilities, health, skills e toolsets.
- [04-runs-streaming.md](04-runs-streaming.md): Runs API, SSE, status, stop e approval.
- [05-sessions-jobs.md](05-sessions-jobs.md): Sessions API e Jobs API.
- [06-frontend-guide.md](06-frontend-guide.md): desenho pragmatico do front-end, estados, streaming e exemplos TypeScript.
- [07-endpoint-reference.md](07-endpoint-reference.md): tabela completa de endpoints.
- [08-operacao-integracoes.md](08-operacao-integracoes.md): front-ends compativeis, proxy mode e troubleshooting.

## Modelo mental

O Hermes API Server nao e apenas um proxy de LLM. Cada request roda contra um `AIAgent` no host onde o API server esta executando. Portanto, ferramentas como terminal, arquivos, browser tools, MCP local, memoria e skills atuam no ambiente do servidor, nao necessariamente no computador do usuario do front-end.


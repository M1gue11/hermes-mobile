# Runs API e streaming

## Limite para chat fiel ao Desktop

Runs/SSE é útil para clientes de API, progresso, reconexão e controle de runs, mas na versão documentada não encaminha o `reasoning_callback` nativo. Para fidelidade ao chat do Desktop — texto, tool progress, reasoning e prompts interativos — use o gateway TUI JSON-RPC `WS /api/ws` em `:9119`, conforme o [contrato do gateway](../dashboard-api/tui-gateway-json-rpc.md). O `:8642` continua sendo a superfície de compatibilidade/OpenAI/Runs; esta seção não define um novo contrato SSE.

Runs API é adequada para clientes de API, dashboards e fluxos que precisam acompanhar progresso sem depender apenas do streaming da chamada principal. Para reproduzir a fidelidade do chat Desktop, vale o limite do gateway TUI acima.

## Quando usar Runs API

Use `/v1/runs` quando o front-end precisa de:

- Progresso de ferramentas em tempo real.
- Reconexao apos reload ou troca de rota.
- Polling de status sem manter SSE aberto.
- Cancelamento de execucao.
- Fluxo de aprovacao humana.
- Correlacionar uma run com uma conversa propria do produto.

## `POST /v1/runs`

Cria uma nova execucao de agente.

Campos aceitos documentados:

- `input`: prompt simples.
- `session_id`: ID externo para correlacionar com a conversa do cliente.
- `instructions`: instrucoes adicionais.
- `conversation_history`: historico enviado pelo cliente.
- `previous_response_id`: reaproveita contexto de response anterior.

Request sugerido:

```json
{
  "input": "Analise os arquivos alterados e sugira melhorias.",
  "session_id": "frontend-conversation-123",
  "instructions": "Responda em portugues, de forma objetiva."
}
```

Response:

```json
{
  "run_id": "run_abc123",
  "status": "started"
}
```

## `GET /v1/runs/{run_id}`

Consulta estado atual da run.

Response:

```json
{
  "object": "hermes.run",
  "run_id": "run_abc123",
  "status": "completed",
  "session_id": "frontend-conversation-123",
  "model": "hermes-agent",
  "output": "Done.",
  "usage": {
    "input_tokens": 50,
    "output_tokens": 200,
    "total_tokens": 250
  }
}
```

Status terminais documentados:

- `completed`
- `failed`
- `cancelled`

Esses estados sao retidos por um periodo curto para permitir polling e reconciliacao de UI.

## `GET /v1/runs/{run_id}/events`

Stream SSE com progresso da run.

Conteudo esperado:

- Eventos de ciclo de vida.
- Deltas de texto.
- Progresso de tool calls.
- Resultados de ferramentas.

Padrao de front-end recomendado:

1. `POST /v1/runs`.
2. Guardar `run_id` no estado da conversa.
3. Abrir SSE em `/v1/runs/{run_id}/events`.
4. Renderizar eventos incrementais.
5. Em reconnect, chamar `GET /v1/runs/{run_id}` para reconciliar estado.

## `POST /v1/runs/{run_id}/stop`

Solicita interrupcao da run.

Response:

```json
{"status": "stopping"}
```

O Hermes pede ao agente ativo para parar no proximo ponto seguro. A UI deve tratar como cancelamento pendente, nao como cancelamento instantaneo.

Estados sugeridos na UI:

```txt
running -> stopping -> cancelled
running -> stopping -> completed
running -> failed
```

## `POST /v1/runs/{run_id}/approval`

Resolve uma aprovacao pendente de uma run, por exemplo quando uma tool call exige decisao humana.

A documentacao nao fixa um schema publico detalhado para o body. Portanto, para um front-end robusto:

- Descubra suporte via `/v1/capabilities` procurando `run_approval`.
- Renderize prompts de approval somente se a run emitir evento/estado indicando pendencia.
- Mantenha o payload de decisao desacoplado em uma funcao unica, para ajustar quando o schema estiver confirmado no ambiente real.

Exemplo conceitual:

```json
{
  "decision": "approved",
  "reason": "Usuario confirmou a acao."
}
```

## Streaming em Chat Completions vs Responses vs Runs

| API | Melhor uso | Eventos |
| --- | --- | --- |
| Chat Completions | Compatibilidade OpenAI e chat simples | `chat.completion.chunk` + `hermes.tool.progress` |
| Responses | Tool UI estruturada e estado no servidor | `response.*`, `function_call`, `function_call_output` |
| Runs | UX rica com detach/reconnect/cancelamento | Eventos de run, tool progress e deltas |

## Implementacao SSE no browser

`EventSource` nativo nao permite setar `Authorization` header diretamente. Opcoes:

- Criar endpoint no seu backend que injeta `Authorization` e repassa SSE.
- Usar `fetch` streaming com `ReadableStream`.
- Usar uma lib de SSE que suporte headers via `fetch`.

Para producao, a opcao com backend proxy costuma ser a mais limpa porque evita expor `API_SERVER_KEY` no browser.

## Regras de UX

- Mostre ferramenta em execucao separada do texto final.
- Nao persista `hermes.tool.progress` como mensagem do assistant.
- Tenha botao de cancelar apenas se `/v1/capabilities` indicar suporte.
- Mostre estado `stopping` enquanto o servidor ainda finaliza.
- Em falha de SSE, tente reconectar e consulte status via `GET /v1/runs/{run_id}`.

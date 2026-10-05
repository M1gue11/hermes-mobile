# APIs OpenAI-compatible e discovery

## `POST /v1/chat/completions`

Formato padrao Chat Completions. E stateless: o cliente envia a conversa inteira em `messages` a cada request.

Use quando:

- Voce quer compatibilidade ampla com SDKs e UIs OpenAI-compatible.
- O front-end ja gerencia historico.
- Voce quer a rota mais simples para chat.

Request:

```json
{
  "model": "hermes-agent",
  "messages": [
    {"role": "system", "content": "Voce e um especialista em Python."},
    {"role": "user", "content": "Escreva uma funcao fibonacci"}
  ],
  "stream": false
}
```

Response:

```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1710000000,
  "model": "hermes-agent",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Aqui esta uma funcao fibonacci..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 50,
    "completion_tokens": 200,
    "total_tokens": 250
  }
}
```

### Imagem inline

`messages[].content` pode ser array com partes `text` e `image_url`.

```json
{
  "model": "hermes-agent",
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "text", "text": "O que tem nesta imagem?"},
        {
          "type": "image_url",
          "image_url": {
            "url": "https://example.com/screenshot.png",
            "detail": "high"
          }
        }
      ]
    }
  ]
}
```

Suportado:

- URLs remotas `http(s)`.
- `data:image/...` com base64.

Nao suportado:

- Uploads por `file`, `input_file` ou `file_id`.
- `data:` que nao seja imagem.

Erro documentado para conteudo nao suportado:

```txt
400 unsupported_content_type
```

### Streaming

Com `"stream": true`, retorna SSE com chunks padrao de Chat Completions e eventos customizados do Hermes:

```txt
event: hermes.tool.progress
```

Esse evento serve para mostrar progresso de ferramentas sem misturar esse texto na mensagem final persistida.

## `POST /v1/responses`

Formato OpenAI Responses API. Diferenca principal: pode manter estado de conversa no servidor com `previous_response_id` ou `conversation`.

Use quando:

- Voce quer preservar historico completo de tool calls no servidor.
- O cliente nao quer reenviar a conversa inteira.
- Voce quer eventos estruturados de tool call no streaming.

Request:

```json
{
  "model": "hermes-agent",
  "input": "Quais arquivos existem no meu projeto?",
  "instructions": "Voce e um assistente de coding.",
  "store": true
}
```

Response:

```json
{
  "id": "resp_abc123",
  "object": "response",
  "status": "completed",
  "model": "hermes-agent",
  "output": [
    {
      "type": "function_call",
      "name": "terminal",
      "arguments": "{\"command\":\"ls\"}",
      "call_id": "call_1"
    },
    {
      "type": "function_call_output",
      "call_id": "call_1",
      "output": "README.md src/ tests/"
    },
    {
      "type": "message",
      "role": "assistant",
      "content": [
        {"type": "output_text", "text": "Seu projeto tem..."}
      ]
    }
  ],
  "usage": {
    "input_tokens": 50,
    "output_tokens": 200,
    "total_tokens": 250
  }
}
```

### Multi-turn com `previous_response_id`

```json
{
  "input": "Agora mostre o README",
  "previous_response_id": "resp_abc123"
}
```

O servidor reconstrui a conversa a partir da cadeia de responses armazenadas, incluindo tool calls e resultados.

### Conversas nomeadas

Alternativa a controlar IDs manualmente:

```json
{"input": "Ola", "conversation": "meu-projeto"}
```

```json
{"input": "O que tem em src?", "conversation": "meu-projeto"}
```

O servidor encadeia automaticamente com a response mais recente daquela conversa.

### Imagem inline no Responses

```json
{
  "model": "hermes-agent",
  "input": [
    {
      "role": "user",
      "content": [
        {"type": "input_text", "text": "Descreva este screenshot."},
        {"type": "input_image", "image_url": "data:image/png;base64,iVBORw0K..."}
      ]
    }
  ]
}
```

### Streaming no Responses

Eventos SSE documentados:

- `response.created`
- `response.output_text.delta`
- `response.output_item.added`
- `response.output_item.done`
- `response.completed`

Tool calls aparecem como output items do tipo `function_call` e `function_call_output`.

## `GET /v1/responses/{id}`

Recupera uma response armazenada.

Use para:

- Reabrir uma conversa.
- Depurar estado do servidor.
- Reconstruir UI apos reload.

## `DELETE /v1/responses/{id}`

Remove uma response armazenada.

Observacao: a documentacao informa limite de ate 100 stored responses com eviction LRU.

## `GET /v1/models`

Lista o agente como modelo disponivel. Necessario para muitos clientes OpenAI-compatible.

O nome anunciado vem de:

- `API_SERVER_MODEL_NAME`, se definido.
- Nome do profile Hermes.
- `hermes-agent` no profile default.

## `GET /v1/capabilities`

Retorna a superficie estavel da API em formato legivel por maquina.

Exemplo simplificado:

```json
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "chat_completions": true,
    "responses_api": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true
  }
}
```

No front-end, chame esse endpoint no boot da aplicacao para decidir:

- Se mostra botao de cancelar run.
- Se habilita streaming por Runs API.
- Se mostra prompts de approval.
- Se usa Sessions API.
- Se habilita `X-Hermes-Session-Key`.

## `GET /health` e `GET /v1/health`

Health check basico:

```json
{"status": "ok"}
```

`/v1/health` existe para clientes que esperam prefixo `/v1`.

## `GET /health/detailed`

Health check estendido. Reporta informacoes como sessoes ativas, agentes em execucao e uso de recursos. Use em telas internas de observabilidade.

## `GET /v1/skills`

Lista skills disponiveis para o agente.

Exemplo de shape:

```json
[
  {
    "name": "github-pr-workflow",
    "description": "...",
    "category": "..."
  }
]
```

Uso no front-end:

- Tela de capacidades.
- Filtro de skills disponiveis.
- Ajuda contextual sem perguntar ao modelo.

## `GET /v1/toolsets`

Lista toolsets resolvidos para a plataforma `api_server`.

Exemplo de shape:

```json
[
  {
    "name": "core",
    "label": "...",
    "description": "...",
    "enabled": true,
    "configured": true,
    "tools": ["read_file", "write_file"]
  }
]
```

Uso no front-end:

- Mostrar quais capacidades realmente estao configuradas.
- Alertar quando uma feature depende de ferramenta ausente.

## System prompt

Em Chat Completions, mensagens `system` sao aplicadas sobre o prompt base do Hermes. Em Responses, o campo equivalente e `instructions`.

Importante: isso adiciona instrucoes de comportamento, mas nao remove ferramentas, memoria e skills do agente.


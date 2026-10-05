# Guia para construir o front-end

## Arquitetura recomendada

Para producao:

```txt
Browser -> Backend do seu app -> Hermes API Server
```

Motivos:

- Nao expor `API_SERVER_KEY` no browser.
- Permitir auth por usuario no seu produto.
- Controlar CORS no seu backend.
- Fazer proxy de SSE com headers.
- Aplicar rate limit, logs e auditoria.

Para desenvolvimento local simples:

```txt
Browser -> Hermes API Server
```

Nesse caso, configure `API_SERVER_CORS_ORIGINS`.

## Boot da aplicacao

Ao iniciar o front-end, faca:

1. `GET /health` para saber se o servidor esta vivo.
2. `GET /v1/capabilities` para descobrir features.
3. `GET /v1/models` para preencher model picker, se necessario.
4. `GET /v1/skills` e `GET /v1/toolsets` para tela de capacidades.

Estado minimo:

```ts
type HermesBootState = {
  online: boolean;
  model?: string;
  capabilities?: Record<string, unknown>;
  skills?: HermesSkill[];
  toolsets?: HermesToolset[];
};
```

## Escolha de API por produto

### Chat MVP

Use `POST /v1/chat/completions`.

Vantagens:

- Mais simples.
- Compatibilidade com SDKs OpenAI.
- Historico controlado no cliente.

Limite:

- O cliente precisa reenviar historico.
- Tool progress vem como evento customizado em streaming.

### Chat com estado no servidor

Use `POST /v1/responses`.

Vantagens:

- `previous_response_id` preserva contexto no servidor.
- `conversation` permite conversa nomeada.
- Streaming mais estruturado para tool calls.

Limite:

- Stored responses tem limite documentado de 100 itens com LRU eviction.

### Workspace/dashboard avancado

Use Runs API + Sessions API.

Vantagens:

- Cancelamento.
- Reconnect.
- Status polling.
- Fork de sessao.
- Historico por sessao.
- Melhor UX para ferramentas.

## Cliente HTTP base

Exemplo TypeScript para uso em backend:

```ts
const HERMES_BASE_URL = process.env.HERMES_BASE_URL ?? "http://localhost:8642";
const HERMES_API_KEY = process.env.HERMES_API_KEY;

async function hermesFetch<T>(
  path: string,
  init: RequestInit = {}
): Promise<T> {
  const response = await fetch(`${HERMES_BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${HERMES_API_KEY}`,
      ...(init.headers ?? {})
    }
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Hermes ${response.status}: ${text}`);
  }

  return response.json() as Promise<T>;
}
```

## Chat Completions client

```ts
type ChatMessage = {
  role: "system" | "user" | "assistant";
  content:
    | string
    | Array<
        | { type: "text"; text: string }
        | { type: "image_url"; image_url: { url: string; detail?: "low" | "high" | "auto" } }
      >;
};

async function sendChat(messages: ChatMessage[]) {
  return hermesFetch("/v1/chat/completions", {
    method: "POST",
    body: JSON.stringify({
      model: "hermes-agent",
      messages,
      stream: false
    })
  });
}
```

## Responses client

```ts
async function sendResponse(input: string, previousResponseId?: string) {
  return hermesFetch("/v1/responses", {
    method: "POST",
    body: JSON.stringify({
      model: "hermes-agent",
      input,
      previous_response_id: previousResponseId,
      store: true
    })
  });
}
```

## Runs client

```ts
async function createRun(input: string, sessionId: string) {
  return hermesFetch<{ run_id: string; status: string }>("/v1/runs", {
    method: "POST",
    body: JSON.stringify({
      input,
      session_id: sessionId
    })
  });
}

async function getRun(runId: string) {
  return hermesFetch(`/v1/runs/${runId}`);
}

async function stopRun(runId: string) {
  return hermesFetch(`/v1/runs/${runId}/stop`, {
    method: "POST",
    body: JSON.stringify({})
  });
}
```

## SSE no front-end

Como `EventSource` nao envia `Authorization`, prefira expor um endpoint no seu backend:

```txt
GET /api/hermes/runs/:runId/events
```

Esse endpoint chama:

```txt
GET http://localhost:8642/v1/runs/:runId/events
Authorization: Bearer <API_SERVER_KEY>
```

E repassa o stream para o browser.

## Estados de mensagem

Modelo util para UI:

```ts
type ConversationMessage = {
  id: string;
  role: "user" | "assistant" | "system" | "tool";
  content: string;
  status: "pending" | "streaming" | "complete" | "failed" | "cancelled";
  runId?: string;
  responseId?: string;
  toolEvents?: ToolEvent[];
};
```

Tool events devem ser renderizados como timeline ou painel de progresso, nao como texto final do assistant.

## Tratamento de imagens

Suporte atual:

- URL remota de imagem.
- `data:image/...` base64.

Nao implemente upload de arquivos genericos esperando que o Hermes aceite `file_id`; a API documenta que isso retorna `400 unsupported_content_type`.

## Checklist de UI

- Campo de endpoint e API key apenas em ambiente dev/admin.
- Indicador de server online/offline.
- Model picker alimentado por `/v1/models`.
- Painel de capabilities alimentado por `/v1/capabilities`.
- Timeline de tool calls para streaming.
- Botao cancelar quando Runs API suportar `run_stop`.
- Reconexao SSE com fallback para polling.
- Separacao visual entre resposta final e progresso de ferramenta.
- Mensagens claras para `401`, CORS, servidor offline e conteudo nao suportado.

## Compatibilidade com Open WebUI

Open WebUI conecta no Hermes como se fosse OpenAI:

```txt
OPENAI_API_BASE_URL=http://host.docker.internal:8642/v1
OPENAI_API_KEY=<API_SERVER_KEY>
ENABLE_OLLAMA_API=false
```

Pontos uteis para o seu front-end:

- A URL precisa incluir `/v1`.
- Open WebUI usa Chat Completions por padrao.
- Responses API pode ser usada quando o cliente suporta esse modo.
- Tool calls rodam no host do API Server.


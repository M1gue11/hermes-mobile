# Delta do contrato Mobile: TUI Gateway 0.20.1+

Este delta complementa o snapshot REST `openapi-0.18.2.json` e o inventário
TUI `tui-gateway-contract-0.18.2.json`. A revisão de código usada para a
confirmação foi o checkout somente leitura do Hermes Agent em `620ceb86`.
Não é uma alteração no Gateway.

## `gateway.ready` e heartbeat

No WebSocket `/api/ws`, o primeiro frame continua sendo uma notificação
JSON-RPC `event` de tipo `gateway.ready`. O payload atual inclui, além de
`skin`, `change_events` e `replay_epoch`, o sinal opcional:

```json
{"heartbeat": true}
```

`heartbeat: true` é capacidade do transporte, não um status de sessão. O
cliente só inicia o keepalive quando esse campo é exatamente `true`. Se o
campo estiver ausente (backend antigo), não envia `gateway.ping`.

Quando anunciado, o Mobile envia a cada 15 s:

```json
{"jsonrpc":"2.0","id":"mobile-N","method":"gateway.ping","params":{}}
```

O retorno confirmado é `{"ok":true}`. Qualquer frame recebido conta como
liveness; se nenhum frame chega por 45 s, o cliente encerra o socket, cancela o
timer e reconcilia pelo caminho normal de queda do live turn. Não há retry
cego nem fallback que reenvie prompt.

`gateway.ping` não é REST, não é exposto na UI e não deve ser enviado a um
backend que não anunciou a capacidade.

## `message.complete`

O contrato atual fecha o turno com `status` em:

| `status` | Mapeamento Mobile |
| --- | --- |
| `complete` | resposta concluída (`RunCompleted`) |
| `error` | falha (`RunFailed`); `failure_reason` tem precedência sobre `error`/texto |
| `interrupted` | turno cancelado/interrompido (`RunStatus.cancelled`) |

Status ausente também conclui o turno (mirrors de subagent mandam só `text`).
`completed` e `failed` são aceitos por compatibilidade com gateways antigos.
Qualquer outro status fecha o turno como falha (`RunFailed`): nunca é sucesso,
porque o texto pode ser parcial, e também não deixa o turno aberto.
`failure_reason` é uma causa de contrato, não deve ser concatenada ao Markdown
final nem virar uma nova mensagem do assistant.

O payload pode conter `text`, `usage`, `reasoning`, `warning`, `error`,
`failure_reason`, `recoverable` e `partial`. O adapter Mobile atualmente só
projeta texto final, falha e cancelamento; os demais campos permanecem no frame
redigido para diagnóstico quando aplicável.

## Eventos que continuam pendentes

- `message.interim` (`text`, `already_streamed`) exige um bloco persistível
  próprio para não duplicar texto já emitido nem transformar comentário
  transitório em resposta final. Permanece em B12 até haver modelo/timeline e
  teste de reabertura.
- `tool.output_risk` (`tool_id`, `name`, `risk`, `findings`, `redacted`) é um
  sinal de segurança. Não deve ser convertido em texto do assistant nem
  descartado silenciosamente; permanece em B10/B12 até existir uma affordance
  segura, redigida e coberta por teste.

## REST: Dashboard e API Server são superfícies diferentes

| Superfície | Base típica | Auth | Uso Mobile |
| --- | --- | --- | --- |
| API Server Hermes | `:8642` ou prefixo privado `/hermes` | HTTP Authorization header com token | `/health`, `/v1/capabilities`, `/v1/models`, `/v1/runs/*`, `/v1/skills`, `/v1/toolsets` |
| Dashboard REST | `:8443` publicado (interno `:9119`) | cookie de sessão; ticket efêmero para WS | `/auth/password-login`, `/api/auth/ws-ticket`, `/api/audio/transcribe`, inventário REST do Dashboard |
| Dashboard TUI Gateway | mesmo host publicado do Dashboard, `WS /api/ws` | cookie + ticket de uso único | live chat rico: sessões, deltas, tools, reasoning e prompts interativos |

Não use a chave Bearer do API Server como cookie do Dashboard e não derive a
porta/URL do Dashboard de `baseUrl` do API Server. O Mobile mantém os adapters,
credenciais e reconciliações separados. O Dashboard interno `:9119` não é o
endpoint publicado do aparelho; a publicação configurada é a autoridade.

Referências: [`README.md`](README.md), [`websockets.md`](websockets.md),
[`../hermes-api/README.md`](../hermes-api/README.md) e
[`tui-eventos-0.20.1-medido.md`](tui-eventos-0.20.1-medido.md).

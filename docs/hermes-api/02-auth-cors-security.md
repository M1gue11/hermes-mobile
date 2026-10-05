# Auth, CORS e seguranca

## Autenticacao

Use Bearer token em requests protegidas:

```http
Authorization: Bearer <API_SERVER_KEY>
```

Configure a chave em:

```env
API_SERVER_KEY=uma-chave-forte
```

Para um front-end proprio, prefira nao expor essa chave no browser em producao. O padrao mais seguro e:

```txt
Browser -> seu backend -> Hermes API Server
```

Use chamada direta do browser para Hermes apenas em ambiente local ou quando voce controlar bem CORS, rede e permissao de usuarios.

## Superficie sensivel

O API Server da acesso ao toolset completo do Hermes Agent, incluindo terminal, arquivos, web search, memoria e skills configuradas. Isso significa que `API_SERVER_KEY` equivale a permissao operacional sobre o agente e o ambiente onde ele roda.

Cuidados minimos:

- Use uma chave forte e diferente por ambiente.
- Nao commite `.env`.
- Evite expor `API_SERVER_HOST=0.0.0.0` sem proxy, TLS e controle de acesso.
- Mantenha `API_SERVER_CORS_ORIGINS` restrito.
- Para multiusuario real, prefira profiles isolados ou uma camada de backend que aplique autorizacao por usuario.

## CORS

Por padrao o Hermes nao habilita CORS para browser.

Para chamada direta do front-end:

```env
API_SERVER_CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

Quando CORS esta ligado:

- Preflight usa `Access-Control-Max-Age: 600`.
- Respostas SSE tambem carregam headers CORS.
- `Idempotency-Key` e permitido como request header.

## Idempotency-Key

Clientes podem enviar:

```http
Idempotency-Key: <uuid-ou-hash-da-operacao>
```

O Hermes cacheia respostas por chave por cerca de 5 minutos. Use para evitar duplicacao quando o usuario clica duas vezes ou quando ha retry apos queda de rede.

## Headers de sessao

### `X-Hermes-Session-Id`

Identificador de sessao/transcript. Pode mudar quando o usuario inicia uma conversa nova.

```http
X-Hermes-Session-Id: transcript-alpha
```

### `X-Hermes-Session-Key`

Identificador estavel para escopo de memoria de longo prazo, util em front-ends multiusuario.

```http
X-Hermes-Session-Key: agent:main:webui:dm:user-42
```

Regras documentadas:

- Maximo de 256 caracteres.
- Caracteres de controle como `\r`, `\n` e `\x00` sao rejeitados.
- O valor e ecoado nas respostas JSON e SSE.
- Suporte anunciado em `/v1/capabilities` como `session_key_header`.

Sugestao de formato para front-end:

```txt
app:<ambiente>:user:<user_id>
app:<ambiente>:workspace:<workspace_id>:user:<user_id>
```

## Security headers

Respostas incluem:

```http
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
```

## Erros comuns

| Sintoma | Causa provavel | Correcao |
| --- | --- | --- |
| `401` | Bearer token ausente ou incorreto | Conferir `Authorization` e `API_SERVER_KEY`. |
| Browser bloqueia request | CORS nao configurado | Definir `API_SERVER_CORS_ORIGINS`. |
| Front-end nao lista modelos | Base URL sem `/v1` | Usar `http://host:8642/v1`. |
| Ferramentas atuam no lugar errado | API Server roda em outro host | Rodar Hermes no host correto ou deixar isso claro na UI. |


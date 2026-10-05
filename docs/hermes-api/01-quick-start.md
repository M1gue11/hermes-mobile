# Quick Start

## 1. Habilitar o API Server

Adicione no arquivo `~/.hermes/.env`:

```env
API_SERVER_ENABLED=true
API_SERVER_KEY=change-me-local-dev
# Opcional: somente se o browser chamar o Hermes diretamente
# API_SERVER_CORS_ORIGINS=http://localhost:3000
```

Tambem e possivel usar comandos Hermes, quando disponiveis:

```bash
hermes config set API_SERVER_ENABLED true
hermes config set API_SERVER_KEY your-secret-key
```

Se o gateway ja estiver rodando, reinicie para aplicar a configuracao.

## 2. Iniciar o gateway

```bash
hermes gateway
```

Saida esperada:

```txt
[API Server] API server listening on http://127.0.0.1:8642
```

## 3. Testar disponibilidade

Health check publico:

```bash
curl http://127.0.0.1:8642/health
```

Modelo anunciado:

```bash
curl http://127.0.0.1:8642/v1/models \
  -H "Authorization: Bearer change-me-local-dev"
```

Chat simples:

```bash
curl http://127.0.0.1:8642/v1/chat/completions \
  -H "Authorization: Bearer change-me-local-dev" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "hermes-agent",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## 4. Conectar um front-end

Para clientes OpenAI-compatible:

```txt
Base URL: http://localhost:8642/v1
API key:  <API_SERVER_KEY>
Model:    hermes-agent, ou o nome anunciado em /v1/models
```

Se o front-end roda no browser e chama o Hermes diretamente, configure CORS:

```env
API_SERVER_CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

Se o front-end chama seu proprio backend, e esse backend chama o Hermes, CORS no Hermes normalmente nao e necessario.

## Variaveis de ambiente

| Variavel | Default | Uso |
| --- | --- | --- |
| `API_SERVER_ENABLED` | `false` | Liga o API Server. |
| `API_SERVER_PORT` | `8642` | Porta HTTP. |
| `API_SERVER_HOST` | `127.0.0.1` | Bind address. Por padrao aceita apenas localhost. |
| `API_SERVER_KEY` | obrigatoria | Bearer token usado em quase todos os endpoints. |
| `API_SERVER_CORS_ORIGINS` | vazio | Lista separada por virgula de origins permitidas no browser. |
| `API_SERVER_MODEL_NAME` | nome do profile | Nome retornado em `/v1/models`. No profile default, tende a ser `hermes-agent`. |

## Profiles multiusuario

Para isolar usuarios, rode um profile Hermes por usuario, cada um com seu proprio `.env`, porta e chave:

```bash
hermes profile create alice
hermes profile create bob
```

Exemplo de `.env` para profiles:

```env
# ~/.hermes/profiles/alice/.env
API_SERVER_ENABLED=true
API_SERVER_PORT=8650
API_SERVER_KEY=alice-secret
```

```env
# ~/.hermes/profiles/bob/.env
API_SERVER_ENABLED=true
API_SERVER_PORT=8651
API_SERVER_KEY=bob-secret
```

Cada profile anuncia seu proprio model ID, normalmente o nome do profile.


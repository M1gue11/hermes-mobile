# Operacao, integracoes e troubleshooting

## Front-ends compativeis

Qualquer cliente que fale formato OpenAI pode conectar ao Hermes usando:

```txt
Base URL: http://localhost:8642/v1
API key:  <API_SERVER_KEY>
```

Front-ends citados na documentacao oficial:

| Front-end/cliente | Configuracao esperada |
| --- | --- |
| Open WebUI | Conexao OpenAI com URL customizada. |
| LobeChat | Custom provider endpoint. |
| LibreChat | Custom endpoint em `librechat.yaml`. |
| AnythingLLM | Generic OpenAI provider. |
| NextChat | `BASE_URL`. |
| ChatBox | API Host setting. |
| Jan | Remote model config. |
| HF Chat-UI | `OPENAI_BASE_URL`. |
| big-AGI | Custom endpoint. |
| OpenAI Python SDK | `OpenAI(base_url="http://localhost:8642/v1")`. |
| curl | HTTP direto. |

## Open WebUI rapido

Docker:

```bash
docker run -d -p 3000:8080 \
  -e OPENAI_API_BASE_URL=http://host.docker.internal:8642/v1 \
  -e OPENAI_API_KEY=your-secret-key \
  -e ENABLE_OLLAMA_API=false \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Docker Compose:

```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3000:8080"
    volumes:
      - open-webui:/app/backend/data
    environment:
      - OPENAI_API_BASE_URL=http://host.docker.internal:8642/v1
      - OPENAI_API_KEY=your-secret-key
      - ENABLE_OLLAMA_API=false
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: always

volumes:
  open-webui:
```

Pontos importantes:

- A URL precisa terminar com `/v1`.
- `OPENAI_API_KEY` deve bater com `API_SERVER_KEY`.
- Open WebUI fala server-to-server, entao geralmente nao precisa de CORS no Hermes.
- `ENABLE_OLLAMA_API=false` evita um backend Ollama vazio poluindo o seletor de modelos.
- Configuracoes feitas pela UI do Open WebUI ficam persistidas no banco interno; mudar env vars depois pode nao sobrescrever o que ja foi salvo.

## Chat Completions vs Responses em Open WebUI

| Modo | Endpoint | Quando usar |
| --- | --- | --- |
| Chat Completions | `/v1/chat/completions` | Recomendado e funciona por padrao. |
| Responses | `/v1/responses` | Experimental; util para eventos estruturados e historico server-side. |

Observacao operacional: a documentacao de Open WebUI informa que ele ainda pode gerenciar historico client-side mesmo no modo Responses. O ganho principal nesse caso e o stream estruturado de eventos.

## Docker Linux sem Docker Desktop

Se `host.docker.internal` nao resolver:

```bash
# Opcao 1: adicionar host mapping
docker run --add-host=host.docker.internal:host-gateway ...

# Opcao 2: usar host networking
docker run --network=host -e OPENAI_API_BASE_URL=http://localhost:8642/v1 ...

# Opcao 3: usar IP da bridge Docker
docker run -e OPENAI_API_BASE_URL=http://172.17.0.1:8642/v1 ...
```

## Proxy mode

O API Server tambem pode atuar como backend para gateway proxy mode. Quando outra instancia Hermes Gateway usa `GATEWAY_PROXY_URL` apontando para esse API Server, ela encaminha mensagens para ele em vez de rodar seu proprio agente.

Uso tipico:

- Separar uma integracao em container de um agente rodando no host.
- Manter uma instancia cuidando do transporte/messaging e outra cuidando do agente.
- Cenarios como Matrix E2EE em container encaminhando para um agente host-side.

Configuracao conceitual:

```env
GATEWAY_PROXY_URL=http://host:8642
```

## Troubleshooting

### Nenhum modelo aparece

Verifique:

```bash
curl http://localhost:8642/health
curl -H "Authorization: Bearer your-secret-key" http://localhost:8642/v1/models
```

Causas comuns:

- Gateway nao reiniciado apos `API_SERVER_ENABLED=true`.
- URL sem `/v1`.
- Token errado.
- Docker apontando `localhost` para o container, nao para o host.
- Backend Ollama vazio aparecendo antes dos modelos Hermes em Open WebUI.

### Teste de conexao passa, mas modelos nao carregam

Quase sempre e URL sem `/v1`. Use:

```txt
http://host.docker.internal:8642/v1
```

Nao use apenas:

```txt
http://host.docker.internal:8642
```

### Resposta demora

O Hermes pode estar executando ferramentas antes de responder: leitura de arquivos, terminal, web search, browser tools ou skills. Para seu front-end, prefira streaming ou Runs API para mostrar progresso.

### `Invalid API key`

Confirme que:

- `Authorization: Bearer ...` no request tem a mesma chave de `API_SERVER_KEY`.
- Em Open WebUI, `OPENAI_API_KEY` e igual ao `API_SERVER_KEY`.
- A UI nao persistiu uma chave antiga no banco interno.

### Ferramentas rodam no host errado

O runtime de ferramentas e o host do API Server. Se o usuario usa um front-end no notebook apontando para Hermes remoto, comandos de terminal e leitura de arquivos rodam no remoto.

Deixe isso explicito na UI quando o front-end puder conectar a servidores diferentes.

# Contrato do Dashboard remoto

Este diretório versiona o contrato REST observado do Dashboard Hermes para orientar decisões do Hermes Mobile. É um suplemento operacional: não substitui os contratos do API Server documentados em [`../hermes-api/README.md`](../hermes-api/README.md).

## Dois backends, dois modelos de autenticação

Dashboard e API Server são serviços distintos e o Mobile não deve derivar um
endpoint do outro:

| Serviço | Porta / publicação | Uso | Autenticação |
| --- | --- | --- | --- |
| API Server Hermes | `:8642` ou prefixo privado publicado | `/v1/*`, Runs/SSE, Skills e toolsets | Bearer token |
| Dashboard REST | `:8443` publicado; `:9119` interno | login, ticket WS, transcrição e REST do Dashboard | sessão por cookie |
| Dashboard TUI Gateway | `WS /api/ws` no host publicado | live chat rico do Desktop | cookie + ticket efêmero |

O Mobile mantém `HttpHermesRepository` para o API Server e
`DashboardGatewayRepository` para Dashboard/TUI. Não reutilize Bearer como
cookie, não derive a porta do Dashboard do `baseUrl` do API Server e não aponte
o aparelho diretamente para o gateway interno `:9119`.

Não reutilize uma chave Bearer de `:8642` como se fosse sessão do Dashboard, nem conclua que um endpoint do Dashboard é público porque o OpenAPI não declara `security`.

No comportamento observado do Dashboard documentado, o gate exige sessão para tudo, com estas exceções: fluxos de bootstrap `/login`, `/auth/login`, `/auth/callback`, `/auth/password-login`, `/auth/logout`, `/api/auth/providers`; assets; e a allowlist exata `/api/status`, `/api/config/defaults`, `/api/config/schema`, `/api/model/info`, `/api/dashboard/themes`, `/api/dashboard/plugins`, `/api/cron/fire`. A última exige JWT próprio e não é rota do app mobile. Para APIs protegidas, `401` usa envelope com `error`, `detail`, `reason` e `login_url`.

## Artefatos

- `openapi-0.18.2.json`: snapshot autenticado, sem credenciais, do Dashboard Hermes 0.18.2; referência histórica para REST, não o contrato atual.
- `endpoint-reference.md`: referência gerada de todas as operações do snapshot.
- `mobile-mapping.md`: decisão de produto e risco por categoria de rota.
- `websockets.md`: índice das interfaces WebSocket fora do OpenAPI.
- `tui-gateway-contract-0.18.2.json`: inventário de métodos, eventos e transporte do gateway TUI extraído do Hermes 0.18.2, sem segredos.
- `tui-gateway-json-rpc.md`: contrato versionado de `/api/ws`, incluindo limites de estabilidade e allowlist Mobile.
- `mobile-live-chat-plan.md`: desenho do adapter Flutter para live chat fiel ao Desktop.
- `tui-eventos-0.20.1-medido.md`: o que o gateway TUI **de fato** emite em
  `0.20.1`, medido em turno real, com o que cada campo carrega, as diferenças de
  semântica entre TUI e Runs API e o modo de falha do `session.resume`. Leia
  antes de mexer no adapter de eventos: o snapshot `0.18.2` acima já diverge.
- `mobile-contract-delta-0.20.1.md`: delta acionável para `gateway.ready`,
  `gateway.ping`, estados de `message.complete`, pendências seguras e a
  separação REST entre Dashboard e API Server.

## Gerar e validar

Use apenas a stdlib do Python:

```bash
python3 tools/generate_dashboard_contract_docs.py --snapshot docs/dashboard-api/openapi-0.18.2.json
python3 tools/generate_dashboard_contract_docs.py --snapshot docs/dashboard-api/openapi-0.18.2.json --check
```

Sem `--snapshot`, o gerador usa `docs/dashboard-api/openapi-0.18.2.json`. `--check` retorna código diferente de zero quando `endpoint-reference.md` não corresponde exatamente ao snapshot selecionado.

## Renovação segura do snapshot

1. Obtenha a especificação em uma sessão autenticada controlada, gravando a resposta diretamente em arquivo temporário; não envie cabeçalhos de cookie, senhas, tickets, tokens ou URL autenticada ao terminal, logs ou repositório.
2. Verifique que o JSON contém somente a especificação OpenAPI e remova qualquer dado operacional indevido antes de substituí-lo por `openapi-<versão>.json`.
3. Atualize a referência e verifique-a apontando explicitamente para o novo snapshot:

   ```bash
   python3 tools/generate_dashboard_contract_docs.py --snapshot docs/dashboard-api/openapi-<versão>.json
   python3 tools/generate_dashboard_contract_docs.py --snapshot docs/dashboard-api/openapi-<versão>.json --check
   ```
4. Registre a versão e qualquer alteração de comportamento de gate nesta documentação. Não use nem documente exemplos de sessão ou ticket.

## Limites factuais

O snapshot REST tem 269 operações e 99 schemas, mas várias respostas usam schema vazio; nesses casos a forma do payload não está especificada. Ele não versiona schemas dos WebSockets. Para o gateway TUI há um inventário de código separado e limitado em [`tui-gateway-json-rpc.md`](tui-gateway-json-rpc.md); não infira além dele. Onde a fonte não especifica corpo, resposta, segurança ou semântica, a documentação mantém `não especificado` em vez de inferir contrato.

Estado histórico em 2026-08-08: o runtime publicado era `0.20.0`, enquanto os
snapshots versionados desta pasta permaneciam em `0.18.2`. A revisão somente
leitura do checkout Hermes `620ceb86` atualizou os deltas de WebSocket e os
pontos de REST documentados em `mobile-contract-delta-0.20.1.md`, mas **não**
renovou o OpenAPI nem mediu o runtime autenticado publicado. Login, ticket WS
e transcrição não devem ser inferidos do snapshot antigo. B0 no backlog exige
revalidação autenticada antes de ampliar o contrato.

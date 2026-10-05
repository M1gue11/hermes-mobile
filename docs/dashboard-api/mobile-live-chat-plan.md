# Plano Mobile: live chat pelo gateway TUI

## Decisão de produto

Para live chat, o cliente pode usar `/api/ws` no Dashboard: via WSS quando a
publicação oferece TLS, ou via WS em uma rede de desenvolvimento confiável,
quando habilitado. Essa superfície entrega texto, progresso de ferramentas,
reasoning e prompts interativos como o Desktop. Na versão documentada,
Runs/SSE não replica reasoning nativo.
## Contrato MVP observado no código

Esta seção é estrita: foi extraída do código-fonte do Hermes `0.18.2`, no commit `df5700ebe317ff9f2d9ea4677513e012eb68b6f4` registrado no snapshot; **não é OpenAPI**. Apenas estes contratos são confirmados para a allowlist MVP:

| Método | Parâmetros necessários / opcionais confirmados | Resultado confirmado |
| --- | --- | --- |
| `session.create` | Nenhum obrigatório. Opcionais: `cols` (default `80`), `messages`, `title`, `parent_session_id`, `cwd`, `source`, `profile`, `model`, `provider`, `reasoning_effort`, `fast`, `close_on_disconnect`. | `session_id`, `stored_session_id`, `message_count`, `messages`, `info` |
| `session.list` | `limit` opcional (default `200`). | `sessions[]` com `id`, `title`, `preview`, `started_at`, `message_count`, `source` |
| `session.most_recent` | Nenhum. | `session_id` (pode ser `null`); quando presente: `title`, `started_at`, `source` |
| `session.resume` | `session_id` obrigatório. Opcionais: `cols` (default `80`), `profile`, `lazy`, `source`, `close_on_disconnect`, `eager_build`. | `session_id` (live), `resumed`, `message_count`, `messages`, `info`, `inflight`, `running`, `session_key`, `started_at`, `status` |
| `session.history` | `session_id` obrigatório: id **live** de create/resume. | `count`, `messages` |
| `prompt.submit` | `session_id` e `text`; `truncate_before_user_ordinal` opcional. | `status: "streaming"` (ou envelope de erro) |
| `session.steer` | `session_id`, `text` não vazio. | `status: "queued"\|"rejected"`, `text` |
| `session.interrupt` | `session_id`. | `status: "interrupted"` |
| `clarify.respond` | `request_id`, `answer`. | `status: "ok"` ou erro quando não houver prompt pendente |
| `approval.respond` | `session_id`; `choice` opcional (default `deny`); `all` opcional (default `false`). | `resolved` |
| `file.attach` | `session_id` live, `path`, `name`, `data_url`. | `ref_text` para prefixar o prompt pela Runs API |

`stored_session_id` e `session_key` são duráveis; `session_id` é live. Use somente o `session_id` live em `prompt.submit`, `session.history`, `session.steer`, `session.interrupt` e `approval.respond`. Valide localmente `text` não vazio antes de `prompt.submit`, mesmo que o handler atual não o valide explicitamente. Os outros 107 métodos permanecem apenas inventariados, sem contrato de parâmetros/retorno inferido.

Os métodos listados formam a allowlist do live chat documentada neste plano.
`file.attach` é restrito a um arquivo selecionado explicitamente, com limite
local de 25 MB e ticket efêmero.

## Máquina de estados de conexão

`desconectado → login_pendente → sessão_cookie → ticket_pendente → conectando → aguardando_gateway_ready → pronto`.

Em erro: `reconectando` (após nova emissão de ticket) ou `acesso_negado`. Ao fechar uma sessão: `encerrando → desconectado`. O ticket nasce somente após login/cookie válido via `POST /api/auth/ws-ticket`, é usado uma vez na URL `ws(s)://<host>/api/ws?ticket=...` e nunca vai para logs, persistência ou analytics. Só considere a conexão pronta ao receber `gateway.ready` como primeiro evento. Para `4401`, obtenha sessão/ticket novo; para `4403`, pare e apresente diagnóstico de endpoint/origem/autorização.

## Modelo de blocos cronológicos

Mantenha uma timeline tipada, ordenada por chegada, separada da representação final da mensagem:

| Bloco | Origem | Regra de renderização/persistência |
| --- | --- | --- |
| texto | `message.start`, `message.delta`, `message.complete` | Agregar deltas na mensagem atual e fechar com `message.complete`. |
| reasoning nativo | `reasoning.delta` | Exibir como tipo próprio somente quando emitido pelo provider; nunca mesclar ao texto. |
| activity preview | `reasoning.available`, `thinking.delta`, `status.update`, `tool.generating`, `tool.progress` | Preview/status transitório, com rótulo de origem; não persistir como texto do assistant. |
| tool | `tool.start`, `tool.complete` | Correlacionar por `tool_id` quando disponível; mostrar resumo/erro/duração sem tratar preview como mensagem. |
| prompt interativo | `clarify.request`, `approval.request` | Bloquear a ação até decisão explícita e responder apenas pela allowlist. |
| lifecycle | `gateway.ready`, `session.info`, `background.complete`, eventos de subagent | Atualizar estado/timeline sem supor campos não documentados. |

Regra inflexível: `reasoning.delta` é nativo quando o provider o emite; `reasoning.available` é preview/fallback e jamais deve ser promovido a chain-of-thought; `thinking.delta` é spinner/status, não reasoning.

## Reconnect e reconciliação

Ao perder o socket, congele a timeline local e marque operações pendentes como estado desconhecido; não reenvie automaticamente prompt, steer, interrupt ou resposta interativa. Faça backoff limitado, valide novamente a sessão por cookie e emita um **novo** ticket para cada tentativa; nunca reutilize ticket. Após `gateway.ready`, reconcilie consultando a allowlist de sessão/histórico (`session.resume`, `session.history`, ou método de listagem aplicável), deduplique por identificadores somente quando existirem e sinalize ao usuário qualquer lacuna que o contrato não permita resolver. `4403` não é candidato a retry automático.

## Contratos e testes antes do adapter

- Fixture do handshake: primeiro frame é notificação `event` com `params.type = gateway.ready` e payload apenas observado `{ skin }`.
- Testes de codec JSON-RPC: exatamente um objeto JSON por frame de texto, correlação de `id`, response `result`/`error` e notificação sem `id`; não aceitar múltiplos objetos por frame sem nova evidência.
- Testes de allowlist: os 37 eventos e os métodos MVP do snapshot; evento/campo desconhecido não quebra o stream e é descrito sem dados sensíveis.
- Testes de reducer: interleaving de texto, reasoning, preview, tool e lifecycle; `reasoning.available` e `thinking.delta` nunca alimentam bloco de reasoning nativo.
- Testes de prompts: `clarify.respond` e `approval.respond` requerem gesto explícito; secret/sudo/terminal permanecem indisponíveis.
- Testes de transporte: ticket de uso único, novo ticket a cada reconnect, tratamento distinto de `4401` e `4403`, e nenhum segredo em logs/telemetria.
- Teste de compatibilidade por versão: validar o inventário JSON antes de habilitar uma nova versão do Hermes.

O adapter deve começar com allowlist MVP: `session.create`, `session.resume`, `session.list`/`session.most_recent`, `session.history`, `prompt.submit`, `session.steer`, `session.interrupt`, `clarify.respond` e `approval.respond`. Os demais métodos só entram após contrato, UX e autorização específicos. Consulte também o [contrato JSON-RPC](tui-gateway-json-rpc.md).

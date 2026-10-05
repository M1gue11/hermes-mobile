# Server requests do Gateway e `clarify.lock`: crítica e plano

> **Status (2026-10-04):** os problemas 1 a 6 e 8 foram corrigidos na própria
> `feat/gateway-contract-0215` depois do merge de `dev`; o 7 virou comentário
> (o contrato fixa `all: false`). Além deles, a correção revelou e resolveu um
> bug do buffer pré-listener (drenagem síncrona no `onListen` perdia frames).
> O texto abaixo fica como registro da revisão.

## Verificação no Hermes Agent (2026-10-04)

Conferido no checkout local do `hermes-agent` (`main` em `165c889e5`, que
contém o `620ceb86` citado no delta de contrato):

- **Server requests são obrigatórios.** Clarify e approval só saem como
  server request (`tui_gateway/server_requests.py`; `server.py::_clarify_block`
  e `_emit_approval_request`). Não existe mais evento `clarify.request` nem
  RPC `clarify.respond`. Sem `client.capabilities {server_requests: true}`, o
  clarify volta na hora como `undelivered` e a aprovação é retirada da fila.
  Ou seja: sem esta branch, o Mobile não faz clarify nem aprovação contra o
  gateway atual. O "veredito" abaixo (esperar confirmar) fica respondido.
- **Clarify é sempre batch** (`ClarifyRequestParams.questions` obrigatório) e
  o último `clarify.lock` resolve o pedido: o Mobile não precisa mandar o
  frame de resposta com `answers`. Confirma os itens 3 e 4.
- **`clarify.lock`** devolve `{status: ok, remaining}` ou `{status: expired}`;
  `answer` é string ou `null` (skip). Bate com o Mobile.
- **`approval`**: `request_id` é obrigatório nos params; o resultado é
  `{choice, all?}`. Bate com o Mobile.
- **Primeira resposta vence** (`resolve_response`). Por isso o Mobile agora
  responde `4404` (`NOT_SHOWN_CODE`) aos pedidos de janela do Desktop
  (`preview.*`, `terminal.read`, `window.read`, `tour`): um `-32601`
  instantâneo derrubaria o pedido antes de a janela dona responder. Para
  `sudo`, `secret` e `vault.*` o Mobile segue com `-32601`, como o Desktop faz
  com método sem handler. Limitação conhecida: com Desktop e Mobile na mesma
  sessão, esse `-32601` também vence o Desktop; o protocolo não tem um voto
  "não sou eu" para esses métodos (o `4404` viraria a resposta do prompt).
- **Heartbeat e `message.complete`** batem com `tui_gateway/ws.py` (ready
  sempre anuncia `heartbeat: true`; responde `gateway.ping` com `{ok: true}`)
  e `TurnStatus` (`complete`/`error`/`interrupted`).
- **Código legado morto:** o caminho `clarify.request`/`clarify.respond` do
  Mobile não tem par no gateway atual. `approval.respond` ainda existe como
  RPC. O legado de clarify foi removido do Mobile em seguida (modelo só batch, sem `clarify.respond` nem evento `clarify.request`).

Origem: revisão da branch `origin/feat/gateway-contract-0215` (`def68b5`),
feita em 2026-10-04. A branch **não foi mergeada**. Só a fatia de baixo risco
entrou em `dev` (heartbeat via `gateway.ping` e status de `message.complete`,
commit `feat(gateway): heartbeat via gateway.ping e status de message.complete`).
Este documento cobre o que ficou de fora, para implementar num segundo momento.

## O que a branch faz

1. **Server requests JSON-RPC (servidor→cliente)** para `clarify` e `approval`.
   Novo `GatewayServerRequestFrame`, `client.capabilities {server_requests:
   true}` enviado a cada `gateway.ready`, `bindSessionId`, fila de requests
   chegados antes da sessão, `open_requests` na resposta do `session.resume`,
   evento `request.cancel`, resposta por `{"id", "result"}` com o id do
   envelope, e recusa (-32601/-32602) de sudo, secret, vault e bridges do
   desktop.
2. **`clarify.lock`** em batch: cada pergunta é travada por `qid`, e uma
   resposta já travada (e não nula) pode ser editada até a última pergunta.
   Inclui prefill no `ClarifyCard`.
3. Extras: `ApprovalRequest.requestId`, `ClarifyRequest.serverRequest`,
   `ClarifyResponse.expired`, respostas `null` (skip) preservadas no replay.

Tamanho: ~550 linhas em `lib/` e ~1000 de testes e docs. É a maior parte do
diff da branch.

## Veredito

O ganho só existe quando o gateway **exige** o caminho de server request.
Hoje `client.capabilities` é opt-in e os eventos legados (`clarify.request`,
`approval.request`) continuam funcionando. Antes de implementar, confirmar no
gateway que roda em produção que (a) ele emite server requests para clientes
que anunciam a capacidade e (b) o caminho legado vai ser removido. Se não, o
custo (superfície de protocolo nova, estado duplicado no controller e no
widget) não se paga. Se sim, vale implementar, **com as correções abaixo**.

## Problemas a corrigir na reimplementação

Ordem de gravidade.

1. **Resposta a server request some sem aviso.**
   `_GatewaySocketClient.respondToServerRequest` retorna sem erro se o socket
   está fechado ou falhou, e `respondToApproval(requestId:)` retorna logo em
   seguida. A UI conclui que aprovou, mas o servidor nunca recebeu.
   Correção: propagar a falha (lançar `GatewayOperationException` como o
   `call` faz) para o controller mostrar `approvalError` e manter o card.

2. **Requests enfileirados sem sessão ficam sem resposta.**
   Se `session.resume` falha ou o socket cai antes de `bindSessionId`, o
   `close()` só limpa `_queuedUnboundRequests`. O contrato pede uma resposta
   por id. Correção: responder -32603 (ou equivalente) a cada item da fila no
   fechamento, quando o socket ainda aceitar escrita.

3. **Mesma decisão em três lugares.** O cliente rejeita clarify que não seja
   batch com -32602; o `_eventsFrom` e o `ClarifyRequest` ainda tratam single
   com `serverRequest`; o controller descarta `serverRequest` que não seja
   batch. O ramo single é código morto e um clarify single vindo do servidor
   falha com erro. Correção: confirmar no contrato 0.20.1 se single existe via
   server request. Se existir, suportar; se não, remover o ramo single de
   `_eventsFrom` e deixar a regra num lugar só.

4. **`respondToClarification(answers:)` sem chamador.** O parâmetro e o ramo
   que responde `{"answers": ...}` não são usados pelo
   `chat_controller.dart`, que só chama `lockClarification`. Ou falta o passo
   final de conclusão do batch, ou é código morto. Verificar no contrato como
   o servidor considera o batch concluído e remover o que não for usado.

5. **Editar resposta travada duplica regra.** `canEditLocked` existe no
   controller e `_canEditLocked` no `_ClarifyCardState`, com a mesma
   condição. Mover para `ClarifyRequest` (por exemplo
   `bool canEdit(String questionId)`), usar nos dois e testar no domínio.

6. **Prefill frágil.** `_answerMarker` compara respostas juntando com
   `\u0000`. Comparar listas por igualdade de valores (por exemplo
   `listEquals`) e tratar `String` e `List` com o mesmo tipo de chave.

7. **`respondToApproval` com `requestId` ignora aprovação "todos".** Envia
   sempre `'all': false`. Confirmar com o contrato se o Mobile precisa expor
   "aprovar para a sessão".

8. **Detalhes menores.** `unawaited(call('client.capabilities'))` engole
   qualquer erro, inclusive de socket; aceitável, mas logar no
   `turnCapture`. O `bindSessionId` só é chamado nos dois caminhos de
   `session.resume` do live turn (o probe de diagnóstico não precisa).

## Ordem sugerida de implementação

1. Confirmar com o gateway (itens 3, 4 e 7 acima dependem do contrato).
2. Modelo e protocolo: `GatewayServerRequestFrame` + `decodeGatewayFrame`
   (já há testes em `gateway_rpc_test.dart` na branch, reaproveitar).
3. Cliente: `client.capabilities`, `bindSessionId`, fila, validação de
   sessão, `request.cancel`, `open_requests`, **com** os itens 1 e 2.
4. Aprovação por server request (`requestId` no `ApprovalRequest`).
5. Clarify batch por server request (`serverRequest`, `lockClarification`).
6. Edição de resposta travada (item 5 e 6) por último, só se o ganho de UX
   justificar. É a parte mais frágil e a de menor valor.

Cada passo deve compilar e passar em `flutter analyze` e `flutter test` sozinho.

## Reaproveitar da branch

`git show origin/feat/gateway-contract-0215:<arquivo>` traz a implementação de
referência. Commits relevantes: `0d759a8` (server requests), `57caf87`
(sessão e clarify), `237c3bf` (edição de respostas travadas) e `def68b5`
(docs e backlog de replay de eventos). Os testes dessa branch precisam de
`import '.../domain/models/run.dart'` no
`dashboard_gateway_repository_test.dart`: sem ele o arquivo não compila.
O `fbe02bd` só reformata esse arquivo de teste e atrapalha cherry-pick; é
melhor reaplicar os testes à mão sobre o `dev` atual.

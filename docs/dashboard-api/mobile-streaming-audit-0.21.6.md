# Auditoria do streaming TUI — Hermes 0.21.6

Revisão em 2026-10-11, com foco em `/api/ws`, projeção do turno, persistência
e retomada do Hermes Mobile. O checkout do Hermes foi consultado somente para
leitura. Nenhuma alteração no runtime, dependência ou serviço novo.

## Referências e versões

- Última release estável consultada: [v0.21.6, publicada em 2026-10-08](https://github.com/NousResearch/hermes-agent/releases/tag/v0.21.6),
  commit `818c13be1dc4fd28987e1e881a9408224afd4535`.
- Checkout local analisado: `hermes-agent`, commit
  `1f2b9e08644c6de4a5b5c50d0e4676a19c5577c5`, de 2026-10-10;
  `v0.21.6+canary.20261010T070026Z-236-g1f2b9e0864`.
- A consulta do upstream apontou `9e827685f2ff…` em `main`. A comparação com o
  checkout local não apontou mudanças adicionais em `tui_gateway` ou
  `apps/shared`, as áreas de protocolo auditadas. `main` e a versão do servidor
  instalado não devem ser tratados como sinônimos da release estável.
- Autoridade do wire: `tui_gateway/contracts/events.py`, `sessions.py` e
  `common.py`; o cliente de referência está em `apps/shared` e `apps/desktop`.
  Os snapshots Mobile `0.18.2` continuam referências históricas.

Fontes de comportamento no checkout auditado:

- [event_replay.py](https://github.com/NousResearch/hermes-agent/blob/1f2b9e08644c6de4a5b5c50d0e4676a19c5577c5/tui_gateway/event_replay.py):
  sequência, epoch, ring e retenção.
- [methods_session.py](https://github.com/NousResearch/hermes-agent/blob/1f2b9e08644c6de4a5b5c50d0e4676a19c5577c5/tui_gateway/methods_session.py):
  resume e `session.events.since`.
- [session_history.py](https://github.com/NousResearch/hermes-agent/blob/1f2b9e08644c6de4a5b5c50d0e4676a19c5577c5/tui_gateway/session_history.py):
  projeção do transcript e acumulação de inflight.
- [prompt_turn.py](https://github.com/NousResearch/hermes-agent/blob/1f2b9e08644c6de4a5b5c50d0e4676a19c5577c5/tui_gateway/prompt_turn.py):
  conclusão, reutilização, transformação e recibo persistido.
- [server_requests.py](https://github.com/NousResearch/hermes-agent/blob/1f2b9e08644c6de4a5b5c50d0e4676a19c5577c5/tui_gateway/server_requests.py):
  pedidos interativos e recusa `4404`.

## Contrato relevante e ajustes

| Área | Comportamento atual do Gateway | Ajuste no Mobile |
| --- | --- | --- |
| Envelope | `params.type`, `params.session_id`, `params.seq`, `params.payload`; eventos globais podem não ter sequência | Preservar sessão e sequência na decodificação; filtrar sessões alheias antes da projeção |
| Replay | `session.events.since(session_id, last_seen)` retorna objetos `params`, `latest_seq`, `truncated`, `epoch`, `open_requests` | Repor a lacuna antes dos frames novos e descartar sequências repetidas |
| Cursor | Sequência por sessão live, vinculada ao epoch do processo | Guardar cursor em background/reconexão; avançar junto à projeção síncrona, sem uma fila assíncrona entre cursor e reducer |
| Ring | Até 512 frames/4 MiB por sessão; limite global de 64 MiB/64 sessões | Não pressupor replay ilimitado; abandonar a janela truncada e buscar snapshot novo |
| Resume | `messages` projetadas usam `text`, `row_id`; tools usam `name`, `context`, `args`, `tool_call_id` | Normalizar também o formato antigo `content`/`tool_name`; preservar identidade durável e argumentos |
| Inflight | Separado do transcript: `user`, `assistant`, `streaming`, erro/status/recoverable; pode existir com `running=false` | Restaurar o parcial e a falha retida sem adotar a resposta do turno anterior |
| Comentários | `message.interim(text, already_streamed)` sela um segmento anterior a ferramentas | Bloco de comentário próprio; limpar o segmento corrente após selar; reconstruir a ordem pelo histórico |
| Conclusão | Texto final, reasoning, warning; `response_previewed`, `response_reused`, `response_transformed` e `persisted_turn` | Conclusão autoritativa; evitar duplicação por reuse; aceitar transformação sem prefixo comum; vincular row IDs e exibir warning |
| Reasoning | `reasoning.delta` é conteúdo; `thinking.delta` é estado transitório | Manter semânticas distintas; usar reasoning terminal quando o provider não enviou deltas |
| `reasoning.available` | O relay `_relay_thinking` ainda pode anunciar uma prévia truncada da resposta final | Não transformar esse evento em reasoning nativo por seu nome |
| Estado | `status.update`, inclusive compactação, é estado operacional | Remover a criação de bloco permanente de atividade a partir desse estado |
| Submit | Worker pode iniciar antes do ACK; existem estados streaming/queued/steered/redirected e `user_row_id` | Distinguir falha antes do envio, recusa RPC e ACK ausente; reconciliar sem reenviar prompt ou migrar para Runs após envio incerto; preservar recibo |
| Pedidos | `open_requests` volta no resume/replay; `approval.cancelled.request_ids` usa IDs internos, diferentes do ID JSON-RPC | Restaurar perguntas pelo socket novo e invalidar aprovação pelo ID interno correto |
| Capacidades | `client.capabilities` negocia `declines_not_shown`; pedidos de janela podem receber `4404` | Esperar negociação; recusar pedidos exclusivos do Desktop com `4404` somente quando anunciado |
| Risco de tool | `tool.output_risk` identifica tool e pode conter findings sensíveis | Badge estático redigido; preservar risk/redacted entre abertura e conclusão; findings não viram texto/Markdown |
| Histórico público | `display_content`, `display_reasoning`, `display_commentary`, `display_kind`, `display_metadata` | Preferir sidecars públicos no REST e no TUI; omitir linhas `hidden`; evitar envelopes privados do provider na conversa |

A coalescência de tokens em aproximadamente 33 ms não muda o enquadramento:
cada mensagem de texto WS contém um objeto JSON-RPC. Heartbeat de 15 s e deadline
de 45 s já estavam alinhados no Mobile e foram preservados.

`close_on_disconnect=false` não garante execução infinita com o app fora da
tela: existem reaper/orphan grace e regras de atividade no servidor. A retomada
deve consultar o estado remoto; não pode reiniciar o trabalho por conta própria.

## Diagnóstico observado antes dos ajustes

O botão de captura foi usado no emulador pareado, sem amostras de conteúdo.
O prompt autorizado da rotina acionou `skill_view` e nove chamadas de terminal
em sequência. O turno terminou no TUI, sem fallback para Runs.

- 294 frames TUI, 0 frames Runs, 10 aberturas e 10 conclusões de ferramentas,
  todas com IDs; duração aproximada de 41 s.
- 217 `message.delta`, 23 `thinking.delta`, 2 `reasoning.delta`,
  1 `reasoning.available` e 1 `message.complete`.
- A timeline local tinha 13 blocos e o histórico completo tinha 12: o bloco
  adicional vinha de `status.update` de compactação. Isso foi observado, além
  de confirmado no adaptador.
- A captura indicava saídas maiores no histórico: por exemplo, 75 contra
  80 caracteres em terminal e 40 contra 45 em sleep. Apenas comprimento não
  comprova truncamento: JSON compacto e JSON com espaços têm esses deltas.
  O diagnóstico agora compara JSON estruturalmente quando possível. O baseline
  redigido não contém o conteúdo necessário para provar igualdade de cada saída.
- A conclusão carregava `persisted_turn`; o resume observado terminou idle,
  `running=false`, sem inflight. O cenário de erro retido foi verificado em
  testes com contrato, não produzido intencionalmente contra o servidor real.
- A conversa foi reaberta e o resultado ficou acessível. A incompatibilidade
  `text`/`content` foi confirmada pelo código atual e por fixtures; não se deve
  afirmar que essa captura demonstrou perda total da mensagem final.

O indicador de conectividade do API Server aparecia offline enquanto o TUI
continuava funcional. São backends diferentes; esse indicador não prova que o
WebSocket do Dashboard está desconectado.

Uma regressão adicional foi reproduzida em teste de retomada: o snapshot TUI
compacto substituía uma tool local do mesmo ID, apagando output, detalhe e
risco já recebidos. A mesclagem agora enriquece a projeção pelo `tool_call_id`
e preserva redaction, incorporando o estado mais recente. Nomes iguais, IDs
ausentes/vazios ou nomes incompatíveis não autorizam transferir esses dados.

## Aceite real após os ajustes

Em 2026-10-11, após autorização explícita, a build instalada executou uma vez
`roda o script de teste do hermes mobile que esta no vault`. A captura ficou
sem amostras de conteúdo. O app foi ao background durante as ferramentas e
voltou à mesma conversa antes da conclusão.

- 561 entradas na captura, 274 frames TUI, 0 frames Runs, aproximadamente
  35 s; um único `prompt.submit`, confirmado com `status=streaming` e
  `user_row_id`. Nenhum reenvio na retomada.
- 10 tools concluídas: `skill_view`, cinco chamadas de timestamp e quatro
  esperas. IDs e ordem coincidiram entre a projeção ao vivo e o histórico HTTP.
  Saídas equivalentes após normalização estrutural de JSON; detalhe de abertura
  preservado. Nenhum bloco permanente de atividade apareceu nesse turno.
- Na volta, `session.resume` informou `running=true`, `status=working` e
  inflight. `session.events.since(last_seen=34)` trouxe 13 eventos, sequências
  35–47, `latest_seq=47`, `truncated=false` e nenhum pedido aberto. O replay
  incluiu aberturas e conclusões de tools e precedeu a continuação ao vivo.
- `message.complete` chegou com `status=complete` e recibo `persisted_turn`.
  Foram observados 202 `message.delta`, 23 `thinking.delta`, nenhum
  `reasoning.delta` e um `reasoning.available`. A prévia disponível não virou
  bloco de raciocínio nem duplicou a resposta final.
- Após sair para a lista e reabrir a conversa concluída, a resposta final
  permaneceu acessível. A última tool foi expandida e conservava argumentos,
  saída JSON e conclusão bem-sucedida. Essa inspeção não comprova a riqueza de
  todos os outputs de todos os formatos de histórico.
- Os dois sockets anunciaram heartbeat, change events e replay epoch;
  `client.capabilities` confirmou 14 tipos de pedido e `declines_not_shown`.
  `session.info` anunciou `version=0.21.6`, `desktop_contract=8` e
  `release_date=2026.9.24`. Esses são metadados observados do servidor; não
  identificam seu commit nem provam igualdade com a release pública de outubro.

## Validação e limites

- `flutter analyze`: sem issues.
- Suíte completa após todos os ajustes, incluindo preservação dos detalhes de
  tools compactas: 690 testes passaram.
- APK debug compilado e instalado com `install -r`, preservando pareamento.
- Fixtures cobrem transcript projetado, ordem replay/live, dedupe, isolamento de
  sessão, cancelamento entre frames, replay truncado, mudança de epoch, replay
  do último turno já terminal, inflight ativo/erro retido, submit sem confirmação,
  interim/reuse/transform, equivalência estrutural do JSON da captura e
  preservação de output/risco pelo ID ao retomar um snapshot compacto.
- Script remoto, replay durante background e reabertura validados na build nova
  conforme o aceite acima. O script não produziu `message.interim`, risco de
  output, aprovação pendente, falha retida, restart ou ring expirado.

O resume atual não oferece watermark atômico associado ao snapshot. O fallback
descarta a janela antiga e relê o estado; frames produzidos durante a construção
do snapshot ainda exigem validação de corrida no runtime. Não prometer replay
exato nem recuperação de outputs inteiros quando o ring expirou: a projeção TUI
de ferramentas pode omitir esses outputs por contrato.

`corrections`/`correction_offsets`, `queued`, auto-continue, todos os detalhes de
`error_surface`, billing e subagents continuam fora da nova projeção tipada.
O recibo de submit preserva status e row ID, mas não implementa uma fila de
turnos concorrentes entre vários clientes. Esses campos precisam de desenho
próprio antes de ganhar comportamento de UI.

`sessions.changed`, `session.usage` e `todo.updated` ainda não atualizam uma
projeção dedicada do Mobile. Permanecem eventos desconhecidos para o reducer.
A auditoria de streaming não encerra B0 (todo o contrato do runtime publicado)
nem B9/B10 (subagents, usage e mudança de sessões).

## Aceites de runtime restantes

Turnos com interim e risco, falha de rede durante aprovação, backend restart
real e ring expirado ficam como aceites separados em
[USER_TESTING.md](../loop/USER_TESTING.md). Simulá-los nos testes não equivale a
executá-los no servidor publicado. Não é necessário repetir a rotina remota
já validada sem uma mudança que justifique nova execução.

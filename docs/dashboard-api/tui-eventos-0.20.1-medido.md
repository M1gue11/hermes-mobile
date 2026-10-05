# Eventos do gateway TUI medidos no runtime 0.20.1

Este documento existe para que ninguém precise refazer esta investigação. Ele
registra o que o gateway TUI **realmente** emite, medido durante uma execução observada no
aparelho, e o que o cliente Flutter faz com cada campo. O snapshot versionado
[`tui-gateway-contract-0.18.2.json`](tui-gateway-contract-0.18.2.json) continua
sendo o inventário formal; aqui está a diferença observada em `0.20.1` e a
leitura de código que a sustenta.

- Medido em 2026-08-15, em conversa real, pela captura de turno de
  `Ajustes -> Captura de turno` (roteiro em [`../loop/SMOKE.md`](../loop/SMOKE.md)).
- Amostra: um turno com 232 frames TUI, 0 frames Runs, 5 ferramentas, 3 blocos
  de raciocínio, 190 `message.delta`.
- Leitura de código feita no checkout `hermes-agent` em `0.20.1`, o mesmo do
  runtime publicado. Nada foi alterado lá.
- Perfil observado: `gpt-5.6-terra` via `openai-codex`, `reasoning_effort=high`,
  `approval_mode=smart`, `tool_progress_mode` no padrão (`all`).

## A regra que resume tudo

**O contrato do TUI entrega o conteúdo inteiro. Onde a timeline ao vivo é mais
pobre que a conversa reaberta, a perda é do cliente, não do gateway.** Isso não
vale para a Runs API, que é pobre por contrato; ver a última seção.

## Ciclo de vida da ferramenta

`tool.start`, emitido por `_on_tool_start`:

| Campo | Sempre? | Conteúdo |
| --- | --- | --- |
| `tool_id` | sim | identificador estável, casa com o `tool.complete` |
| `name` | sim | nome da ferramenta |
| `context` | sim | prévia de exibição de cerca de 80 caracteres |
| `args` | quando há argumentos | **dicionário completo de argumentos** |
| `args_text` | só em `tool_progress_mode=verbose` | argumentos renderizados como texto |

`tool.complete`, emitido por `_on_tool_complete`:

| Campo | Sempre? | Conteúdo |
| --- | --- | --- |
| `tool_id` | sim | mesmo id da abertura |
| `name` | sim | nome da ferramenta |
| `args` | sim | dicionário completo de argumentos |
| `result` | sim | **resultado inteiro**, já desserializado quando é JSON |
| `duration_s` | quando houve abertura | duração em segundos, `float` |
| `summary` | quando a ferramenta tem resumo | texto curto de exibição |
| `result_text` | só em verbose | resultado renderizado como texto |
| `inline_diff` | só em edição de arquivo | diff pronto para exibir |
| `todos` | só na ferramenta `todo` | lista completa |

Não existe campo `error` em `tool.complete`. Procurá-lo faz uma ferramenta que
falhou aparecer como concluída.

Medição que prova a diferença, mesmo turno, mesma ferramenta:

| Ferramenta | `output` montado ao vivo | `output` no histórico |
| --- | --- | --- |
| `skill_view` | 0 | 44.019 |
| `skill_view` | 0 | 5.046 |
| `web_search` | 22 | 3.653 |
| `terminal` | 0 | 3.238 |
| `web_extract` | 24 | 4.949 |

Os 22 e 24 caracteres são o `summary`. O resto do resultado estava em `result`,
no mesmo frame, e foi descartado.

`tool.progress` **não existe**. O nome aparece na allowlist do app por herança
do snapshot `0.18.2`, mas `_on_tool_progress` no gateway desdobra em
`tool.output_risk`, `reasoning.available` e `moa.*`. Nenhum código deve esperar
esse evento.

`tool_progress_mode` é configuração do gateway, não parâmetro de RPC. Em `all`,
que é o padrão, `args` e `result` já vêm. Em `off` não há evento de ferramenta
nenhum, exceto `clarify` e `setup_mcp`. Em `verbose` entram `args_text` e
`result_text`.

## Os três sinais de pensamento não são a mesma coisa

Esta é a confusão que mais custou tempo, e ela tem consequência visual direta.

| Evento | O que é | Como consumir |
| --- | --- | --- |
| `reasoning.delta` | raciocínio nativo incremental do provider | acumula em bloco de raciocínio |
| `reasoning.available` | resposta final, frequentemente truncada | **não é prévia no TUI**; não vira bloco |
| `thinking.delta` | estado transitório de execução, com kaomoji | mostra enquanto dura, some ao ser limpo |

`thinking.delta` chega com texto como `(´･_･`) reasoning...` ou
`٩(๑❛ᴗ❛๑)۶ reflecting...` e o gateway envia o **mesmo evento com texto vazio**
para limpar o estado. Tratar cada chegada como bloco novo produz uma pilha de
kaomojis permanentes na timeline; descartar o texto vazio remove o sinal de
limpeza. Os kaomojis são desejados na interface: o conserto é exibi-los como
estado ao vivo, não acumulá-los como conteúdo.

`reasoning.available` foi medido com 501 caracteres contra um `message.complete`
de 716, ou seja, o mesmo texto cortado. Transformá-lo em bloco de atividade faz
a resposta aparecer duas vezes.

## Semântica que muda por transporte

O mesmo nome de evento significa coisas diferentes no TUI e na Runs API. Um
adapter compartilhado que ignore isso erra em um dos dois lados.

| | Dashboard TUI | Runs API |
| --- | --- | --- |
| `reasoning.delta` | existe, medido em 5 frames num turno | não existe |
| `reasoning.available` | resposta final truncada | resposta final inteira |
| id de ferramenta | `tool_id` em 100% das aberturas | ausente; correlação por FIFO de nome |
| resultado da ferramenta | `result` completo | nenhum campo de resultado |
| argumentos | `args` completos | só `preview` |
| nome dos eventos | `tool.start` / `tool.complete` | `tool.started` / `tool.completed` |

Consequência prática: pela Runs a paridade entre timeline ao vivo e conversa
reaberta é **impossível**, porque o dado não trafega. A única rota lá é
re-hidratar do histórico ao concluir o turno. Pelo TUI a paridade é alcançável
lendo os campos que já chegam.

Com várias chamadas paralelas do mesmo nome, medidas 4 `web_search` simultâneas
num turno, a correlação por FIFO da Runs casa a conclusão com o card errado, e
duração e estado vão para a chamada errada. No TUI isso não acontece porque há
`tool_id`.

## Eventos do 0.20.1 fora do snapshot 0.18.2

Observados num único turno e hoje tratados como desconhecidos pelo app:

- `sessions.changed`, 9 ocorrências, sem payload;
- `session.usage`, 3 ocorrências, com `{model, input, output, reasoning, prompt,
  completion, total, calls, …}`;
- `tool.output_risk`, com `{tool_id, name, risk, findings, redacted}`. Chegou
  como `risk=high`, `findings=[1]`, `redacted=false` num `web_extract`. É um
  sinal de segurança sobre conteúdo não confiável e não deve ser descartado em
  silêncio.

`session.info` também traz muito mais do que o app consome: `model`, `provider`,
`reasoning_effort`, `service_tier`, `approval_mode`, `yolo`, inventário de
`tools` e `skills`, `cwd`, `branch`, `version`, `release_date`, `update_behind`,
`update_command`, `usage`, `profile_name`, `mcp_servers`, `desktop_contract`.

`message.complete` fecha o turno com `{text, usage, status, reasoning}`.

## `session.resume` e a queda muda para a Runs

Parâmetros aceitos em `0.20.1`: `session_id`, `cols`, `profile`,
`omit_messages`, `lazy`, `source`, `close_on_disconnect`, `eager_build`. O app
envia um subconjunto válido; não há desencontro de contrato.

Uma resposta bem-sucedida devolve `session_id` (o id **live**, diferente do
durável), `resumed`, `message_count`, `messages`, `info`, `running`,
`session_key`, `started_at` e `status`.

Modo de falha observado três vezes: cerca de 10 ms depois do `gateway.ready`, o
gateway recusa com

```
-32000  handler error: 'NoneType' object has no attribute 'execute'
```

Isso é um `SessionDB` com a conexão morta dentro do processo do gateway.
`SessionDB.close()` zera `_conn` e mantém o objeto, e `_get_db()` guarda esse
objeto num global do módulo, então um handle fechado envenena o processo. Dois
caminhos conhecidos levam lá:

1. sessão meio construída que fica registrada em `_sessions` enquanto o handle
   dela é fechado. O próprio `tui_gateway/methods_session.py` documenta o caso e
   diz que o atalho de sessão viva passa a servir a sessão morta "permanently";
2. a recuperação de `file is not a database` em `hermes_state.py`, que zera
   `_conn`, tenta reabrir e, se a reabertura falhar, deixa `_conn` nulo com
   guarda de tentativa única. Este **não** se recupera com restart enquanto a
   condição de origem existir. O log do servidor mostra o par
   `state.db connection reported 'file is not a database'` seguido de
   `state.db reconnect after 'file is not a database' failed`.

Na prática observada, reiniciar o gateway resolveu, então o caso 1 é o provável.
Para separar os dois sem acesso ao log, use `Sondar gateway` na tela de debug:
se `session.list` responde e só o resume recusa, o banco está vivo.

O ponto que fica para o app: **a queda para a Runs API era completamente muda**.
Nada na interface dizia que o transporte tinha caído, e por isso o Dashboard TUI
passou muito tempo sem nunca ter sido exercitado de verdade em execução.

## O que o cliente faz com isso hoje

Corrigido em 2026-08-15 (A59), com regressões em
`test/data/dashboard_gateway_repository_test.dart` escritas contra os shapes
desta página:

| Evento | Campo lido | Vira |
| --- | --- | --- |
| `tool.start` | `context` | prévia da chamada |
| `tool.start` | `args` | detalhe, pela mesma `toolDetail` do histórico |
| `tool.complete` | `result` | `output` inteiro |
| `tool.complete` | `inline_diff` | `output`, com precedência: já vem renderizado |
| `tool.complete` | `result.success` / `result.error` | estado de erro |
| `reasoning.delta` | `text` | bloco de raciocínio |
| `thinking.delta` | `text` | estado transitório; vazio limpa |
| `reasoning.available` | nenhum | nada, de propósito |

Restrição que não é de riqueza, é de segurança: o argumento **cru** só sai para
`terminal` e `execute_code`, ao vivo e no histórico. O caminho ao vivo do
servidor passa por `redact_tool_args_for_display`, que o app não tem; despejar
`args` de qualquer ferramenta trocaria uma divergência de exibição por um
vazamento. Por isso a prévia é sempre o `context` calculado pelo servidor.

## Como reproduzir esta medição

1. `Ajustes -> Captura de turno`, ligar **Capturar o próximo turno**.
2. Enviar uma pergunta que use várias ferramentas, em conversa descartável.
3. Ler o cabeçalho: ele diz qual transporte correu e acusa fallback.
4. Ler o `VEREDITO` e as duas projeções.

O relatório sai redigido: apenas nome de evento, nome de campo, id encurtado,
ordem e tamanho. A amostra de texto é opcional e nunca alcança chave com cara de
credencial.

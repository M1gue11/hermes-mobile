# Arquitetura de notificações do Hermes Mobile

Este documento explora o Mobile como destino e console de avisos operacionais.
Gatilhos podem residir em agendadores, serviços e scripts configurados pelo
operador; a escolha de transportes e migração depende de cada instalação.

## Fatia A60 in-app — WIP, validação automatizada executada

Somente na branch `feat/notifications-night-20261007`, baseline `08833d0`.
Nenhum RPC/HTTP novo, dependência, Gateway ou transporte externo. Android continua
com sua Activity existente, sem ponte de notificações OS. `RunEvent.operational`
foi gerado por build_runner real. Claudia executou SDK oficial ARM Flutter 3.44.6 /
Dart 3.12.2: pub get/codegen/analyze exit 0; suíte completa após duas rodadas
corretivas **717 passes, exit 0, 5m40**. Regressões focadas: 135 passes, exit 0.

> [!warning] Bloqueio de aceite, apesar da suíte verde
> Revisão final read-only revelou P2 e Claudia reproduziu em teste isolado (exit 1):
> erro provisório de acompanhamento/stop deixa fase local failed; retornar com
> running:false e histórico vazio usa essa fase local como falha terminal sem
> evidência remota. Esse terminal impede substituição posterior da inbox. Duas
> rodadas corretivas esgotadas; não aceitar/mergear sem corrigir e acrescentar a
> regressão ao repositório. Aparelho ainda pendente. Nenhum transporte OS/push.

### Contrato e privacidade do cliente

- Show exige `kind`, `level` e `text` strings não vazias; `id`/`key` são opcionais (ausentes ou null)
  e nunca sintetizado. Identificadores/kind até 256 codepoints, preservados sem
  trim, lowercase ou coerção. Levels aceitos: `info`, `success`, `warn` (`warning` como compatibilidade explícita),
  `error`. Valores desconhecidos/malformados são ignorados. Campos ricos não
  projetados (título, URL, ação, percentuais etc.) não são fabricados.
- Texto customizado é limitado a 1000 codepoints e exibido com `Text`, sem
  Markdown nem ativação de URLs. O produtor ainda é responsável pelo conteúdo
  que escolheu emitir nesse canal; tools/prompts/reasoning não são copiados para
  notificações pelo cliente.
- TTL ausente/null significa retenção até remoção/evicção/fechamento do app. TTL
  explícito deve ser inteiro de 0 a 604800000 ms (7 dias); inválido rejeita show.
  Zero remove a entrada da key imediatamente. Guarda de overflow também no
  store. Datas da inbox são locais, não timestamps afirmados do servidor.
- Clear exige key real, afeta apenas custom dessa sessão durável e é idempotente,
  inclusive com categoria personalizada silenciada.
- `background.complete` usa só resumo genérico. Os seis sinais de subagent
  (`spawn_requested/start/thinking/tool/progress/complete`) usam cópia fixa;
  `goal/summary/tool_preview/text` nunca chegam à inbox/timeline. IDs reais
  permitem paralelismo. Sem `subagent_id` ou com null, há um agregado por turno, sem inventar
  identidade nem percentual. O agregado não consegue distinguir tarefas sem id;
  após complete, progresso tardio desse agregado é ignorado. Status conhecido (incluindo timeout como erro)
  permite erro/interrupção genéricos; desconhecido apenas diz “encerrada”.
- Status/tool/thinking/reasoning crus nunca vão à inbox. O controller projeta
  início, andamento genérico por status.running/RunToolProgress e terminal em frases fixas, incluindo snapshot Runs terminal, histórico
  TUI terminal correlacionado e cancelamento local após RPC aceito. Cancelamento
  local mostra “Interrupção solicitada”, sem afirmar confirmação remota final;
  o estado do chat segue a reconciliação existente. O terminal posterior substitui
  esse aviso na inbox, inclusive quando o servidor conclui antes de interromper.
- A captura operacional mantém apenas tipo/contagem de campos e omissão do
  conteúdo; amostra ligada não revela texto, keys, IDs ou campos ricos.

### Memória, preferências e lifecycle

`NotificationInbox` guarda até 100 entradas, 256 itens por cache auxiliar e 32
throttles pendentes. IDs de show/key identificam avisos reutilizáveis, não
ocorrências imutáveis: novo seq permite atualização mesmo com o mesmo ID/key.
Clear, remoção, TTL e substituição não deixam um ID global suprimindo reemissão.
Sem seq, show com ID deduplica apenas enquanto houver entrada ativa com mesmo
ID/key/kind/level/texto limitado/TTL; payload diferente substitui seu slot.
Depois do desaparecimento, ID sem seq é indistinguível entre replay e reemissão
legítima e é aceito; isso não garante replay offline. IDs de sinais de subagent
mantêm dedupe de evento por sessão durável/tipo.
Seq usa NoticeSeqScope tipado com session_id real do envelope e replay_epoch
de gateway.ready retido pelo socket. Metadata incompleta usa token LOCAL por
conexão, separado de identidade servidor; turno local não é epoch. Nenhuma seq é inventada nem há promessa de replay. Seq opcional é
lida do envelope existente ou payload; o contrato antigo não a garante. Seq já visto no mesmo scope permanece deduplicado após clear/TTL, até evicção
do cache limitado. Uma
key verdadeira substitui a entrada custom só dentro da sessão durável. Sem IDs de evento,
subagents terminais são deduplicados pelo slot real/agregado do turno. Key ausente/null usa
slot interno por ID real ou identidade local separada quando ambos ausentes;
dois avisos anônimos não colapsam. Clear afeta somente key verdadeira.

Erro de observação/start/submit/stop/transporte usa “Não foi possível acompanhar
a execução”, sem terminal permanente nem erro bruto. RunFailed/snapshot failed
ou encerramento autoritativo usa “A execução falhou”. Completed/cancelled posterior
substitui erro provisório, sem duplicata final; sem alterar chat/reenvio.
RunToolProgress real projeta somente estado genérico: “Ferramentas em andamento”
ou “Execução em andamento”. A ferramenta _thinking não projeta progresso.
Argumentos/name/preview/results/reasoning/text/deltas não entram nesse aviso;
tokens/deltas não notificam. Progresso idêntico já publicado cancela pending obsoleto e preserva localId/read/unread.


Progresso usa janelas de 750 ms por slot, substituindo o aviso agregado.
O último sinal vence; atualizar pending não reinicia a janela. Final
cancela pending antes de publicar; subagent final cancela seu slot. Read/unread
é local, sem ACK servidor. TTL usa timer cancelável; substituição, remoção,
evicção e dispose cancelam o timer correspondente. Troca de sessão, ocultação,
reconciliação e dispose do controller cancelam pending. Caches são limitados:
eventos muito antigos podem voltar após evicção; não é ledger durável.

Preferências independentes de progresso/conclusão (inclui interrupção)/erro/custom
têm efeito imediato e cancelam os pending silenciados. Avisos já recebidos
continuam na inbox até remoção. **Preferências e inbox vivem apenas em memória
durante esta abertura do app**; reiniciar restaura categorias ligadas e inbox
vazia. Não são adicionadas ao shape global de settings, nem persistidas em
secure storage ou servidor.

Ajustes abre o sheet existente com tokens atuais e persona configurada. A única
ação operacional é abrir a conversa durável capturada do controller via
`/chat/${Uri.encodeComponent(sessionId)}`. Payload/show não escolhe destino;
títulos/prompts não são capturados. Abrir marca como lida e fecha os sheets.

Listeners continuam limitados à conversa visível. Epoch/listenerGeneration e
reconnect existentes protegem callbacks; não se abrem todas as sessões. Sem
conexão no background/terminated/offline não há entrega ou recuperação garantida.
Ao voltar, snapshots podem projetar terminal conhecido, mas não recuperam um
histórico de notifications.show/clear perdido. Nenhuma permissão OS é solicitada.

## Fronteira confirmada

```text
cron/systemd/agente
       │ evento operacional normalizado
       ▼
dispatcher + outbox durável
       ├── transporte existente (fallback opcional)
       ├── push Android/iOS
       └── inbox autenticado do Hermes Mobile
```

O Dashboard/TUI Gateway oferece sinais **live** autenticados por sessão e ticket
WebSocket, incluindo `notification.show`, `notification.clear` e
`background.complete`. Eles servem para apresentação in-app enquanto há conexão.
Não garantem entrega em background, app encerrado, offline ou reinstalado.

O `delivery_ledger` do Hermes registra tentativas de respostas finais do agente
para plataformas. Ele não é uma fila genérica para eventos operacionais ou
dispositivos Mobile.

## Camada complementar necessária

| Componente | Responsabilidade |
| --- | --- |
| Envelope de evento | `event_id`, `dedupe_key`, origem, categoria, severidade, título, resumo seguro, criação, TTL, política e deep link. |
| Dispatcher | Receber eventos dos scripts sem envio direto exclusivo ao Telegram. |
| Outbox transacional | Persistir antes da entrega; controlar tentativas, expiração, deduplicação, destino e resultado. JSONL pode permanecer como auditoria. |
| Inbox autenticado | Recuperar eventos depois de perda de push/rede; leitura e acknowledgement não apagam a auditoria. |
| Registro de dispositivos | Vincular e revogar tokens push após pareamento autenticado. |
| Push/notificação local | Entregar em Android/iOS em foreground, background ou app encerrado. |
| Preferências e regras | Categoria, prioridade, quiet hours e digest; regras propostas pelo agente exigem confirmação explícita. |
| Adaptador de transporte existente | Fallback reversível durante a migração, sem mudar produtores. |

## Limites de segurança e privacidade

- O agente só pode **propor** regra; o usuário confirma origem, condição, horário,
  prioridade, destino, expiração e quiet hours.
- Push em tela bloqueada carrega apenas título e resumo mínimos. O detalhe vive no
  inbox autenticado.
- Nunca incluir prompts, cookies, tickets WebSocket, segredos, argumentos de
  tools ou logs brutos em push, inbox, teste ou documentação.
- A escolha de FCM, APNs ou outro relay é uma decisão explícita. Tailnet/WebSocket
  isoladamente não prometem entrega confiável com o app encerrado.
- `notification.clear` deve cancelar pela chave de modo idempotente.

## Sequência de implementação

1. Diagnosticar a saúde dos produtores: transporte não corrige evento que não foi
   produzido.
2. Normalizar eventos operacionais no dispatcher neutro.
3. Implementar outbox e inbox antes de prometer push.
4. Registrar dispositivos e validar foreground, background, app encerrado e
   offline.
5. Entregar Mobile e transporte existente em paralelo usando `event_id` e `dedupe_key`.
6. Migrar categorias de evento somente após validação real; rollback reativa
   apenas o adaptador existente.

## Escopo do repositório

A primeira fase do cliente deve traduzir sinais live permitidos em modelos de
domínio seguros, sem alegar durabilidade. Serviço externo, infraestrutura de push
ou extensão do Gateway exigem decisão explícita do usuário. A direção é manter o
núcleo Hermes responsável por chat, sessões e sinais live; a entrega operacional
durável vive em serviço complementar ou plugin autenticado.

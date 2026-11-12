# Catálogo de eventos e acompanhamento de execução em segundo plano

**Estado:** especificação para implementação posterior, sem mudança de runtime.
**Levantamento:** 2026-11-09. **Cliente:** `5dba6a3da51f6ae07ba3fa803c40db5d0ef4f783`.
**Runtime observado:** HTTP informa Hermes `0.23.0`; fonte local inspecionada em
`2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19`. Versão HTTP e SHA da fonte são
observações distintas: antes de implementar, confirmar também a geração Python
carregada pelos dois processos, sem presumir que acompanharam o checkout.

Relacionados: [arquitetura](NOTIFICATIONS_ARCHITECTURE.md),
[backlog](BACKLOG.md), [aceites atuais](USER_TESTING.md).

## 1. Pedido e limites

Miguel quer:

1. Avisos operacionais: gateway ligando, desligando, reiniciando, atualizando,
   falhando e se recuperando; mapear outros avisos úteis sem criar spam.
2. Uma **notificação de acompanhamento da execução deixada rodando ao minimizar
   o app**, atualizada no mesmo cartão, somente com o app em segundo plano.
3. Documentação suficiente para implementar depois. Este levantamento **não**
   autoriza instalar serviços, mudar ACLs, dependências, Gateway/Core ou APK.

Decidido pelo usuário: direção de produto e acompanhamento apenas em background.
Sugestões deste documento: nomes de eventos novos, parâmetros, prioridades,
lease de acompanhamento, fases e preferências. Não são contratos já publicados.
Android é o alvo; iOS não participa do transporte UnifiedPush atual.

## 2. Evidência atual e lacunas reais

| Camada | O que foi estabelecido |
| --- | --- |
| Telefone, confirmado por Miguel nesta sessão | Avisos de conclusão e de pergunta `clarify` apareceram no Android com o app fora de foreground/fechado; outra conclusão também chegou após a resposta. Não equivale a force-stop, Doze prolongado ou teste de tela bloqueada. |
| Plugin atual | `on_session_end`, `on_human_input_request`, `on_human_input_resolved`; conclusão/falha/input habilitados por padrão; interrupção desligada; cron/subagent ignorados. |
| API de inscrição existente | CRUD de dispositivos e teste sob `/api/plugins/mobile-push/`, autenticados pelo Dashboard. Não há API de acompanhamento, inbox ou produtores de lifecycle neste plugin. |
| Entrega atual | Thread daemon por publicação, dedupe em memória e tentativas limitadas; não sobrevive de forma confiável à morte do produtor. Cache ntfy não é inbox nem prova de leitura/exibição. |
| Flutter atual | Apenas dois canais: respostas e atenção humana. Envelope v1 aceita tipos enumerados; todo tipo não `test` exige `session_id`. Tipos novos seriam ignorados. |
| App minimizado | `setLiveUpdatesVisible(false)` solta listeners/fecha o transporte local **sem cancelar a execução remota**. O progresso não continuará só por criar um cartão Android. |
| Saúde medida agora | `/api/status` e `/hermes/health`: HTTP 200, versão `0.23.0`; estado `running`, `overall: ok`, componentes Dashboard/Gateway/storage/platforms saudáveis; `memory` e `disk` presentes. Três unidades locais ativas: Dashboard, gateway de mensagens e ntfy. |

Falha, interrupção, aprovação/sudo, limpeza visual por `input.resolved`, deep link,
revogação, tela bloqueada, perda de rede e retomada seguem com aceites específicos;
não foram promovidos a aprovados a partir do teste de conclusão/clarify.

### Correção importante: conexão, heartbeat e boot são coisas diferentes

- `gateway.ready` é o **primeiro frame de cada conexão TUI/WS**, não um evento de
  boot do serviço. Reconectar o app não deve disparar “gateway reiniciado”.
- `gateway_updated_at` do status **não é identidade de boot no runtime atual**:
  foi observado `2026-11-10T01:23:36.823854+00:00` e depois
  `2026-11-10T01:24:36.825976+00:00`, com `gateway_state: running` nas duas
  consultas. O código atual reestampa `updated_at` em atualizações/housekeeping.
- Para instância do serviço local, combinar `InvocationID` do systemd e saúde;
  fora de systemd, usar identidade de processo com start-time ou identificador
  explícito de instância, validando a superfície suportada. PID sozinho é reciclável.
- Distinguir boot do host, boot de cada serviço, geração carregada e versão de
  checkout. A mesma versão pode ter SHAs diferentes; checkout novo não prova
  que os processos já usam a nova geração.
- A medição histórica [gateway-lifecycle.md](../dashboard-api/gateway-lifecycle.md)
  continua como histórico de `0.20.0`, **não como algoritmo atual de restart**.

## 3. Separar os componentes monitorados

Não usar “gateway” como uma caixa única:

- **Messaging Gateway:** adaptadores, API Server e atividades sob sua supervisão.
- **Dashboard/TUI backend (`hermes serve`):** API/WS usada pelo Mobile; pode cair
  com o Messaging Gateway ainda saudável, ou continuar vivo quando ele cai.
- **ntfy/relay + distribuidor Android:** entrega push; não demonstra saúde do chat.
- **Host, Tailnet e rede do telefone:** dependências comuns, com falhas distintas.

Cada evento operacional identifica `component` e `instance_id`. Isso evita um
“online” do processo errado e mostra corretamente disponibilidade parcial.

## 4. Catálogo operacional proposto

Os nomes abaixo são **eventos de domínio novos**, não hooks/RPCs já existentes.
“Fonte” é o que já foi encontrado ou o produtor que precisará ser adicionado.
Política de apresentação é recomendação inicial configurável.

| Evento proposto | Fonte e viabilidade | Política inicial |
| --- | --- | --- |
| `service.starting` | Transição systemd/runtime; observável, mas processo iniciado não significa pronto. | Silencioso/inbox; normalmente fundir com `ready`. |
| `service.ready` | Identidade nova + probe de saúde válido do componente. `gateway:startup` existe somente no sistema de hooks do gateway de mensagens, não prova boot do Dashboard. | Um aviso informativo no boot/retorno. |
| `service.stop_requested` | Intenção persistida por operação controlada ou estado `draining`/`stopping`; não inferir intenção de um timeout. | Silencioso se o próprio usuário pediu; incluir motivo seguro quando conhecido. |
| `service.stopped` | Observador systemd fora do processo, após saída; `ExecStopPost` é candidato de instrumentação, não hook instalado. | Aviso normal se não fizer parte de restart curto planejado. |
| `service.restart_requested` | Operação controlada com ID de correlação; precisa produtor. | Atualizar um único cartão de manutenção. |
| `service.restarted` | Nova instância pronta correlacionada ao restart, ou identidade anterior persistida. | Um resumo, em vez de três alertas parar/subir/pronto. |
| `service.failed` | Exit/result da unidade + diagnóstico limitado; observador independente do processo que falhou. | Atenção alta se persistente; uma vez por incidente. |
| `service.startup_failed` | Unidade falhou ou readiness não foi atingida no prazo. | Alta; distinguir timeout de motivo explicitamente conhecido. |
| `service.restart_loop` | Contagem de novas instâncias/falhas numa janela, persistida pelo observador. `NRestarts` isolado não é histórico durável. | Alta, agrupada e com cooldown. |
| `service.degraded` | `overall`, `components`, `gateway_heartbeat_stale_s` e runtime-state quando presentes. Não basta PID ativo. | Avisar após histerese; atribuir ao componente correto. |
| `service.recovered` | Incidente aberto seguido de probes saudáveis consecutivos. | Um aviso de recuperação com duração observada. |
| `platform.disconnected` / `platform.recovered` | Estado de adaptador no runtime/status; separar desabilitado de falha. | Só avisar desconexão sustentada e recuperação; sem spam de reconexão. |
| `update.started` / `update.stage_changed` | Receipts do updater: `update_id`, `outcome: running` e `stages`; observar arquivos/ação suportada, não stdout. | Início discreto, fases silenciosas no mesmo cartão. |
| `update.completed` | Receipt `success` **e** verificação das instâncias alvo/health; código atualizado não basta. | Um resumo com versão/SHA anterior e efetivo, sem logs. |
| `update.partial` / `update.failed` | Receipt `partial`/`failed`, followups e unidades com recuperação pendente. | Alta para falha; parcial deixa explícito o que ainda exige ação. |
| `update.interrupted` | Receipt continua `running`, mas identidade do updater não está viva; reconciliar handoff antes de concluir. | Atenção, nunca declarar sucesso nem falha definitiva só por timeout. |
| `update.available` | Verificação agendada de versão remota; não é consequência de `/health`. Requer política de frequência/rede. | Opt-in, baixa frequência/digest. |
| `plugin.activation_failed` / `integration.unavailable` | Resultado estruturado de ativação, doctor ou probe dedicado; produtor adicional. Não analisar mensagens arbitrárias do agente. | Atenção quando afeta recurso utilizado. |
| `host.reboot_observed` | Monitor persiste boot ID do host e compara após retorno; não usar timestamp do gateway como boot do Linux. | Informativo após voltar; se causa anterior for desconhecida, dizer isso. |
| `host.unreachable` / `network.unreachable` | Exige observação fora do host; timeout do telefone só prova perda de contato pelo telefone. | “Sem contato”, sem inventar causa; alerta durante queda exige caminho independente. |
| `resource.pressure` / `storage.unavailable` | Campos `memory`, `disk` e `components.storage` já existem; limiares/histerese e produtores novos. | Advertência/alta conforme gravidade; memória/disco não mudam necessariamente `overall`. |
| `push.delivery_degraded` / `push.device_revoked` | Outbox/sender e registro; HTTP 404/410 remove endpoint hoje, mas não há alerta durável desse fato. | Inbox/diagnóstico; não depender do próprio canal quebrado para avisar. |

### Fontes Hermes existentes: não confundir as famílias

1. **Gateway event hook:** `gateway:startup`, em `gateway/run_startup.py`.
   Drop-in `HOOK.yaml` é extensão diferente de `ctx.register_hook` do plugin.
   Não foi encontrado hook público equivalente de shutdown/update na revisão
   inspecionada; isso não prova ausência em versões futuras.
2. **Plugin hooks:** `on_session_end`, input, `pre_tool_call`, `post_tool_call`,
   `pre_llm_call`, `post_llm_call`, `on_stream_*`, `subagent_start/stop` e
   `post_compaction` existem no registro atual. `on_session_start` é início de
   sessão, **não cada turno**; `pre_llm_call` pode ocorrer várias vezes por turno.
   `gateway_platform_event` trata eventos nativos de mensagens, não serviço online/offline.
3. **Status + supervisor:** permitem monitorar lifecycle sem patch no Core.
   Persistir o último estado/identidade fora do processo observado; startup
   baseline não deve fabricar um incidente nem reproduzir todo o histórico.
4. **Update receipts:** fonte local atual em `$HERMES_HOME/logs/update_receipts/`
   na raiz da instalação; `update_<...>.json` identifica uma execução e
   `latest.json` é ponteiro, insuficiente para enumerar atualizações perdidas.
   Ler só campos permitidos; receipts também contêm argv/paths/detalhes privados.
   O Dashboard já usa resumos em `web_routers/actions.py`; medir rota/auth/escopo
   antes de criar uma API nova ou assumir cobertura de updates iniciados por CLI.
5. **Monitoring interno:** `agent/monitoring/gateway_health.py` já normaliza
   transições e o emitter tem subscribers. É fila em memória, não store; não é
   automaticamente API pública estável de plugins nem push Mobile. Reutilizar
   conceitos, sem monkeypatch e sem acoplar MVP a API interna não contratada.

### Limite físico da instalação privada

> [!warning]
> Se o Pi inteiro desligar, seu ntfy também sai do ar. Um plugin dentro dele não
> pode enviar depois de morrer. Nem um monitor em outro host consegue publicar
> no relay que está desligado. Para alerta **durante** essa queda é necessário
> observador e caminho de entrega independentes do Pi. Com a topologia atual,
> prometer somente aviso prévio best-effort em shutdown limpo e relato após
> recuperação. Sem Tailscale/rede/distribuidor no celular, entrega pode atrasar.

Um observador local separado cobre crash/restart do Hermes enquanto host e ntfy
continuam vivos; não cobre perda total de energia. Shutdown, SIGKILL, OOM e
host offline têm critérios de evidência diferentes. `OnFailure` sozinho não
cobre paradas limpas; script de stop não cobre morte abrupta. Não adicionar
`Requires`/`PartOf` que faça o monitor morrer junto com o alvo.

## 5. Catálogo de conversa, execução e automações

| Evento/categoria | Já existe? | Ampliação recomendada |
| --- | --- | --- |
| Conclusão do turno | Push `turn.completed`, comprovado no aparelho. | Preservar; uma conclusão não significa fim de todo trabalho filho. |
| Falha terminal / interrupção | Tipos v1 existentes; interrupção opt-in. | Testar separadamente; perda do observador ou falha do botão Parar não é falha remota. |
| Pergunta / aprovação / sudo | `input.requested`/`input.resolved`; clarify recebido. | Manter alta prioridade e ID do pedido; segredo/aprovação só dentro da UI autenticada. |
| Execução iniciada / fase / ferramenta | TUI tem `message.start`, `status.update`, `tool.start/complete/progress`; o plugin atual não produz push de progresso. | Alimentar cartão de acompanhamento silencioso, não alerta por tool/token. |
| Subagente iniciado/concluído/falho | Hooks `subagent_start/stop`, TUI `subagent.*`; plugin pula plataforma subagent. | Agregar no pai; B9/B14 definem lifecycle separado. Fim do pai não encerra automaticamente filho. |
| Tarefas X/Y | TUI `todo.updated`, ainda depende da medição de B11. | Mostrar contagem real; não chamar isso de percentual da run. |
| Compactação / mudança de modelo | `post_compaction`, `session.usage` e sinais versionados. | Apenas fase/diagnóstico por padrão, sem alerta individual. |
| Rate limit / retry / fallback / auth do provedor | Há hooks e metadados de erro; cobertura varia por runtime/provider. | Alertar só indisponibilidade sustentada ou ação humana; retry não é falha terminal. |
| Job agendado: falhou, atrasou, recuperou | Precisa adaptador do scheduler real, preferindo cron/systemd já usados. | Falha/ausência de execução esperada; sucesso rotineiro em digest/opt-in. Não migrar scheduler. |
| Kanban: concluído/bloqueado/worker morreu | Hooks específicos existem na fonte atual; ainda não conectados ao Mobile. | Notificar bloqueio/resultado de interesse, agrupando por tarefa, sem logs/paths. |
| Relatórios/lembretes/alerta proposto pelo agente | Direção da arquitetura, não capacidade arbitrária já pronta. | Regra estruturada e confirmada pelo usuário, revogável e com validade. |

## 6. Live notification: produto proposto

### Comportamento

- Ao deixar o app **realmente em background** (`hidden`/`paused`) com execução
  ativa e acompanhamento habilitado, mostrar um cartão silencioso persistente
  enquanto pertinente. `inactive` sozinho (cortina/diálogo) não inicia a função.
- Ao voltar a `resumed`, esconder o cartão de acompanhamento e reconciliar a
  execução; isso **não** cancela o trabalho nem apaga alertas/inbox não lidos.
- Escopo inicial: execução selecionada ao minimizar; se houver várias, uma
  escolhida explicitamente ou resumo “N execuções”. Não roubar foco para outra
  conversa; futuras preferências podem acompanhar várias.
- Conteúdo mínimo: persona, estado, tempo desde início confirmado, última
  atualização; ferramenta por classe segura e contagem de filhos se disponíveis.
  Sem prompt, resposta, reasoning, comando, argumentos, paths ou resultados.
- Exemplos ilustrativos: “Claudia trabalhando · executando ferramenta · 2 min”,
  “Aguardando sua resposta”, “Sem atualização recente — estado a confirmar”.
- Sem percentual/ETA inventados. Spinner/estado indeterminado quando não existe
  progresso mensurável; `tool.progress` pode dar percentual **daquela tool**, não
  da execução toda. Cronômetro Android pode correr sem push a cada segundo.
- Ao terminar: retirar o cartão ativo e manter o aviso terminal normal, uma vez.
  Se houver pedido humano, manter aviso urgente por `request_id`; ao resolver,
  removê-lo e retomar acompanhamento apenas se a execução continuar ativa.
- Ao dispensar “Ocultar acompanhamento”, respeitar a escolha naquela execução;
  não recriar a cada atualização. A execução continua no servidor.
- Ação inicial segura: **Abrir conversa**. Sem Aprovar, responder sudo ou
  executar comandos pela notificação. Cancelar run exige escopo separado,
  autorização, correlação e confirmação; não é necessário ao MVP.

### Notificação atualizável não é o mesmo que Android Live Updates

**MVP recomendado:** notificação ongoing comum, canal de baixa importância,
mesmo ID/tag por execução, `onlyAlertOnce`, atualização de estado e cronômetro.
Não exige manter o Flutter rodando continuamente: o receptor UnifiedPush pode
atualizar o aviso ao receber snapshots. A existência do cartão **não** mantém
um processo vivo por si só.

**Aprimoramento opcional:** Live Updates promovidas do Android 16+ e
`Notification.ProgressStyle`, condicionadas à API do sistema, biblioteca,
permissão/ajuste de promoção, critérios de uso e decisão do sistema/OEM. São
atividades em andamento, iniciadas pelo usuário e sensíveis ao tempo; não uma
licença para promover qualquer conversa, rotina ou serviço ligado. Avaliar a
adequação deste uso e oferecer fallback; não prometer chip/Now Bar na Samsung
nem presumir versão Android/One UI a partir do modelo S23 Ultra.

A dependência atual `flutter_local_notifications` pode demandar adapter nativo
ou upgrade para superfícies mais novas; medir a versão resolvida antes de decidir.
Não adotar foreground service de propósito genérico para segurar WS. Android
restringe início em background e exige tipo/permissão adequados; `dataSync`,
`remoteMessaging` e `shortService` não são atalhos para monitoramento infinito.
`specialUse` requer justificativa e, se distribuído na Play, revisão pertinente.
Um FGS próprio é alternativa posterior, com estudo de bateria e política, não
pré-requisito do MVP via push.

## 7. Arquitetura recomendada, ainda não implementada

```text
hooks públicos de execução ──► adaptador do plugin ──┐
status + supervisor + receipts ─► observador local ──┤
                                                  ▼
                         eventos + snapshots + outbox persistente
                              │                │
                         inbox autenticada     └► WebPush cifrado → ntfy
                              │                                      │
                              └────────────── Hermes Mobile ◄────────┘
                                               │
                                   projetor nativo de notificações
                                  /              |                
                         operações          atenção humana     execução live
```

Reusar o plugin e enrollment, sem construir outro transporte. O observador de
serviços precisa ficar **fora dos processos que observa**. Ele pode gravar numa
fila local privada consumida pelo dispatcher; protocolo e permissões exigem
revisão antes de implementar. Não copiar chaves/credenciais para scripts públicos.

### Acompanhamento por dispositivo e snapshots

- Proposta: inscrição autenticada temporária (*watch lease*) por
  `device_id + session_id + execution_id`. Não existe rota para ela hoje.
  Criar/renovar durante o fluxo visível e tentar mudar presença ao minimizar;
  lifecycle callback e rede podem falhar. Opt-in persistido é obrigatório.
- Guardar no aparelho intenção, geração de presença e execuções dispensadas,
  acessíveis tanto ao app quanto ao isolate headless; não usar apenas variável
  em memória. Ao voltar, invalidar geração antes de aguardar unsubscribe remoto.
- Presença é **best-effort**: Android pode suspender/matar antes do callback e
  isolar processos; uma atualização atrasada não deve recriar o cartão quando
  o app voltou ou quando o usuário o dispensou. Revalidar a geração no momento
  da apresentação; testar corrida entre isolates.
- Lease expira, pode ser revogada e é limitada a execuções autorizadas. O plugin
  não deve publicar progresso de todas as conversas para todos os aparelhos.
- Push carrega snapshot reduzido, não token/delta. Coalescer atualizações por
  execução, limite proposto de uma atualização a cada 5–10 s, só com mudança
  útil; espera humana e terminal têm precedência. TTL curto para progresso,
  retenção maior para evento terminal/operacional. Parâmetros precisam aceite.
- Cada snapshot tem versão monotônica; terminal não pode voltar a `running`
  por atraso de rede. Reenvio/replay usa o mesmo ID, sem duplicação.
- Um estado “executando” não pode permanecer fresco indefinidamente sem sinal:
  validade limitada, última atualização explícita e expiração nativa quando
  suportada. Sem rede, mostrar incerteza ou expirar, **nunca inventar falha ou
  conclusão**. A ação de reabrir reconcilia com fonte autoritativa.
- Fechar UI, swipe nos recentes, processo morto, tela bloqueada, Doze e
  **Force stop** são cenários diferentes. Force stop/distribuidor parado/VPN
  ausente não têm garantia de atualização até recuperação permitida pelo SO.

### Contrato de eventos v2 proposto

Não enviar os nomes novos como v1 esperando que o cliente entenda. O modelo atual
recusa tipos desconhecidos e exige sessão para tudo exceto teste.

Campos a definir e versionar em conjunto com fixtures de produtor e consumidor:

- Identidade: `v`, `event_id`, `dedupe_key`, `source`, `component`, `profile_id`.
- Objeto: `subject_type` e `subject_id`; `session_id`/`execution_id` opcionais
  somente para eventos que não são de conversa; `request_id` quando aplicável.
- Ordem: `instance_id`, `sequence`/`revision`, `occurred_at`, `expires_at`.
  Vincular reset de sequência à nova instância; evento atrasado de uma instância
  velha não pode substituir a atual.
- Semântica: `kind`, `state`, `severity`, `reason_code` limitado e `operation_id`
  para correlacionar restart/update. Texto só por templates permitidos.
- Apresentação: chave de substituição, política silenciosa/alerta/digest,
  deep link tipado para conversa ou diagnóstico. Evento operacional não deve
  inventar `session_id` nem usar conversa fictícia para passar no parser.

`execution_id` é identidade de domínio a mapear: o fluxo TUI usa sessão/turno e
não deve ser forçado a usar um `run_id` da Runs API. Exigir correlação comprovada
com o `turn_id` dos hooks; se faltar, tratar como bloqueio de contrato.

### Durabilidade, compatibilidade e segurança

- Persistir evento/outbox antes de envio; uma linha por destino e tentativa,
  backoff limitado, TTL, dedupe persistente e remoção 404/410. Snapshot de
  progresso substitui o anterior pendente; terminal/alerta não é descartado por
  coalescência. Registrar capacidade/versão do cliente e manter v1 durante migração.
- Inbox é autoridade para eventos perdidos/read/ack. HTTP 2xx do relay significa
  **publicado**, não recebido no telefone nem lido. Registrar essas etapas
  separadamente; ACK só quando efetivamente implementado e autenticado.
- Validar vínculo de aparelho, usuário/perfil e recurso; isolamento entre
  perfis/conversas. Registrar dispositivos não concede acesso a todos os eventos.
- Exigir criptografia para tipos novos; o fallback JSON puro atual não deve
  herdar o escopo ampliado. Manter política de endpoint/SSRF e redirects.
- A ACL atual de publicação anônima `up*` não autentica a identidade do produtor.
  URL do endpoint e segredos continuam privados; revisar autenticidade do emissor
  antes de aceitar eventos operacionais/ações. Decriptação sozinha não é authz.
- Manter canais separados: respostas, atenção, operações e acompanhamento
  silencioso. Quiet hours e cooldown configuráveis; não contornar DND.
- Não usar frase livre de LLM, stdout ou mensagem de erro como confirmação de
  estado. Sem logs brutos em push; deep links limitados a destinos autenticados.

## 8. Implementação futura e pontos de edição

**A107 — Base durável e contrato:** versionar envelope/fixtures, identidade de
execução e compatibilidade; persistência privada, outbox/inbox, retries,
preferências e políticas por destino. Estudar reaproveitar suporte de DB do
plugin antes de criar serviço paralelo. Testar crash no meio da criação/migração.

**A108 — Lifecycle operacional:** observador separado de Messaging Gateway,
Dashboard e relay; identidade de instância, probes com timeout/histerese,
correlação de manutenção e receipts. Começar por ready, stopped/failed,
recovered e update terminal. Nenhum patch no Core sem autorização nova.

**A109 — Acompanhamento em background:** primeiro provar origem de snapshots e
identidade TUI em turno finito. Depois lease/presença, coalescência, receptor
headless e projetor ongoing; Live Updates promovidas são melhoria opcional.

**A110 — Expansão opt-in:** filhos/tarefas (B9/B11/B14), jobs do scheduler real,
Kanban, recursos e regras confirmadas. Só conectar produtores após catálogo,
permissões e critérios por categoria; não habilitar tudo por padrão.

Arquivos atuais candidatos (não editados como parte deste levantamento):

- `server/mobile-push/{__init__,notifier,webpush,devices}.py`, manifesto e testes;
  módulos novos de store/dispatcher/observador devem ter fronteiras claras.
- `lib/domain/models/push_notice.dart`: v2, recurso não-sessão, execução/ordem/TTL.
- `lib/domain/repositories/local_notifier.dart` e
  `lib/data/platform/system_local_notifier.dart`: canal live, ongoing, update,
  expiração/cronômetro e ação de ocultar, sem mudar alertas atuais.
- `lib/features/notifications/`: policy/projetor, inscrição e persistência
  compartilhada com o caminho headless; verificar também `main.dart`.
- `lib/features/chat/chat_screen.dart` e `chat_controller.dart`: lifecycle e
  identidade de execução, sem religar todos os listeners em background nem
  alterar a autoridade remota da execução.
- `android/app/`: só se APIs/permissões/receiver nativos forem necessários,
  após inspecionar SDK/dependências e aprovação de escopo.

## 9. Matriz de aceite para quando implementar

Esta é uma **matriz futura**, não testes já executados nem roteiro de uma APK
que tenha esses recursos. Ao entregar cada fase, promover o recorte concreto
para `USER_TESTING.md` e registrar versão/commit/build/aparelho.

| Cenário | Resultado exigido |
| --- | --- |
| Restart limpo só do Messaging Gateway | Um incidente/correlação; Dashboard não é anunciado como reiniciado; aviso só “pronto” após health. |
| Crash/SIGKILL do alvo com host vivo | Observador sobrevive; registra falha quando comprovada, recuperação e dedupe após reinício do observador. |
| Stop deliberado / restart durante manutenção | Não confundir com crash; fundir ruído, respeitar preferências e conservar auditoria. |
| Dashboard fora com Messaging Gateway saudável | Estado parcial correto; inscrição/entrega usa fila persistida, não endpoint dentro do processo morto como único produtor. |
| Troca de timestamp/heartbeat e reconnect WS | Nenhum falso aviso de boot/restart. |
| Update por CLI e pelo Dashboard | Receipt correto por operação, mesma versão com SHA novo, parcial, falha, handoff e runtime velho detectados; `latest` de outro update não é aceito como seu. |
| Pi/ntfy indisponível | Sem promessa falsa de alerta imediato; após retorno há reconciliação, sem fabricar causa. Caminho externo, se contratado, testado separadamente. |
| Minimizar com execução ativa | Um cartão silencioso recebe fases sem manter UI/WS vivos; não mostra conteúdo privado. |
| Só `inactive`, trocar tela interna ou minimizar sem execução | Não criar acompanhamento de uma run inexistente nem tratar diálogo como background pleno. |
| Retornar ao app durante push | Cartão live some e não reaparece por corrida com isolate/atraso; execução não é cancelada. |
| Pedido humano / resolução por outro cliente | Aviso urgente separado e removido por ID; cartão live respeita estado real. Sem ação privilegiada pela notificação. |
| Filho ativo após fim do pai | Estado não é fechado por inferência; resumo identifica escopo e B9/B14. |
| Duas execuções / dois turnos seguidos | IDs corretos, sem substituir conversa errada; terminal do turno anterior não encerra o novo. |
| Push duplicado/fora de ordem/expirado | Terminal prevalece, versões não regridem, TTL respeitado, sem novo som nem novos cartões. |
| Usuário dispensa live / revoga push / perde lease | Não recriar cartão; revogação impede envios e limpa inscrição sem cancelar run. |
| Rede/Tailscale ausente, ntfy parado, Doze/tela bloqueada | Aviso não fica falsamente atualizado; retorno reconcilia snapshot/inbox e mede latência/consumo no S23 Ultra. |
| Swipe, processo morto e Force stop | Relatar cada comportamento separadamente; não exigir garantia impossível durante force-stop. |
| Versão Android sem promoção / permissão negada | Fallback ou explicação correta; não depender de Now Bar/chip; sem pedir permissão escondido. |
| Segurança/armazenamento | Sem plaintext fallback para eventos novos, nenhum segredo nos logs, migração interrompida recuperável, ACL atual não ampliada, origem e autorização verificadas. |

## 10. Fontes e verificação do levantamento

Consultas HTTP read-only e propriedades systemd executadas nesta sessão; nenhuma
queda, atualização, troca de ACL ou instalação foi provocada para fazer o mapa.

Código do cliente/plugin, no commit acima:
[notifier](../../server/mobile-push/notifier.py),
[manifesto](../../server/mobile-push/plugin.yaml),
[parser](../../lib/domain/models/push_notice.dart),
[lifecycle](../../lib/features/chat/chat_controller.dart),
[notificador Android](../../lib/data/platform/system_local_notifier.dart).

Fonte Hermes inspecionada, fixada pelo SHA (contrato dependente de revisão):

- [Registro dos hooks](https://github.com/NousResearch/hermes-agent/blob/2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19/hermes_cli/plugins.py), `VALID_HOOKS`.
- [Status runtime](https://github.com/NousResearch/hermes-agent/blob/2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19/gateway/status.py), `_prepare_runtime_status_update`, `runtime_status_is_stale`.
- [Status HTTP](https://github.com/NousResearch/hermes-agent/blob/2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19/hermes_cli/web_routers/status.py), projeção de saúde.
- [Startup](https://github.com/NousResearch/hermes-agent/blob/2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19/gateway/run_startup.py), `_start_post_connect_services`.
- [Receipts](https://github.com/NousResearch/hermes-agent/blob/2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19/hermes_cli/update_receipt.py), `UpdateReceipt`, `begin_update_receipt`, `_receipt_dir`.
- [Eventos TUI](https://github.com/NousResearch/hermes-agent/blob/2bd378ed1b8d6bf2192cb26e0a55ff3091e6bd19/tui_gateway/contracts/events.py), `GatewayReadyPayload`, `message.start/complete`, tools, todo e subagent.

Documentação oficial consultada em 2026-11-09:

- [Hermes: hooks e suas famílias](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks).
- [Hermes: extensões suportadas, sem monkeypatch](https://hermes-agent.nousresearch.com/docs/developer-guide/plugins/).
- [Android: atualizar o mesmo aviso e onlyAlertOnce](https://developer.android.com/develop/ui/views/notifications/build-notification#Updating).
- [Android: Live Updates e critérios de promoção](https://developer.android.com/develop/ui/views/notifications/live-update).
- [Android 16: ProgressStyle](https://developer.android.com/develop/ui/views/notifications/progress-centric).
- [Android: restrições de foreground service em background](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start).
- [Android: tipos de foreground service](https://developer.android.com/develop/background-work/services/fgs/service-types).
- [systemd.service](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) e [systemd.unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html).

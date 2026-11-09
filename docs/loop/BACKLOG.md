# Backlog ativo do Hermes Mobile

Esta é a fonte única de trabalho acionável do Hermes Mobile. Decisões técnicas
duráveis ficam nos contratos em `docs/dashboard-api/` e no histórico Git.

Estados: `[ ]` aberto, `[~]` implementado com validação pendente, `[!]` bloqueado.
O plano de ataque de produto e interface está em
[PRODUCT_INTERFACE_PLAN.md](PRODUCT_INTERFACE_PLAN.md).

## Agora

Aceites em aparelho pendentes: A60, A77, A78, A89, A91 e B9, com roteiros em
[USER_TESTING.md](USER_TESTING.md). Os aceites já registrados ficam no vault
pessoal, em "Histórico e decisões do loop".

## Melhorias após abertura do código-fonte

Itens identificados na segunda revisão estática da `main` em `00d7823` (ver
relatório de 2026-10-05 no vault). Por decisão do mantenedor, **não são
pré-requisitos para tornar público o código-fonte**; avaliar separadamente a
segurança e os requisitos antes de distribuir APKs a terceiros. Adicionar
regressões automatizadas e aceite no aparelho conforme cada correção.

- [~] **A89 Encerrar gravação de áudio no lifecycle.** Cancelar recorder e
  descartar temporários ao sair da tela ou colocar o app em background.

  Implementado em 2026-11-08: a gravação é descartada (o `record` apaga o
  arquivo no `cancel`) quando o app vai para `hidden`/`paused`, quando outra
  rota cobre a conversa e quando o composer é descartado; a tela diz o motivo.
  `inactive` não interrompe, porque o diálogo de permissão do microfone e a
  cortina de notificações passam por ele. Falta conferir no aparelho que o
  indicador de microfone do Android apaga ao sair do app.
- [ ] **A90 Evitar carregamento automático de imagens remotas em Markdown.**
  Rever privacidade e consentimento antes de buscar URLs de terceiros.
- [~] **A91 Confirmar a primeira host key SSH.** Exibir fingerprint e exigir
  confirmação consciente antes de confiar e persistir a chave.

  Implementado em 2026-11-08: na primeira conexão o handshake para no estágio
  `confirmandoHost`; a tela mostra a impressão digital e o comando para
  conferi-la no servidor, com "Confiar e conectar" e "Cancelar". Sem resposta
  em 90 s, ou saindo da sessão, é recusa; só se fixa a chave depois do
  "confio" e da sessão de pé. Falta o aceite contra um SSH real
  ([USER_TESTING.md](USER_TESTING.md)).
- [!] **A92 Revisar transporte HTTP/WS em `*.ts.net`.** Documentar ameaça e
  controles para a exceção cleartext; preferir proteção autenticada do serviço
  quando aplicável, sem confundir criptografia Tailscale com TLS do servidor.

  Documentado em 2026-11-08 em
  [seguranca-transporte-tailnet.md](../seguranca-transporte-tailnet.md), e os
  dois clientes HTTP deixaram de seguir redirects (a chave e o cookie não
  saem para outro host). **Bloqueado em decisão do usuário:** servir o
  Dashboard por `tailscale serve --https` e só então restringir a exceção ao
  FQDN em debug e removê-la do release.
- [ ] **A93 Preparar distribuição Android release.** Definir application ID,
  assinatura release sob custódia apropriada e canal de distribuição; não
  publicar APK release assinado com chave debug. O CI atual só constrói debug.

## Produto e interface

- [~] **A78 Permitir arquivo e áudio no mesmo envio.** Hoje o compositor força
  escolher um ou outro. Permitir preparar anexo(s), gravar áudio e incluir texto
  no mesmo turno sem apagar a seleção anterior; oferecer revisão, remoção e
  confirmação do que será enviado. Respeitar o contrato real: voz é transcrita
  em texto por `/api/audio/transcribe`, enquanto `file.attach` retorna
  `ref_text`; não prometer entrega do áudio original como anexo sem suporte
  medido. Critério de aceite: arquivo + voz + texto chegam na ordem esperada,
  sem envio duplo, perda silenciosa ou upload sem consentimento; falha parcial
  mantém o rascunho recuperável. Testar permissões e retorno do background.

  Implementado em 2026-11-08: o microfone deixou de sumir quando há anexo
  (só some com texto digitado, quando a ação da vez é enviar). Arquivo, voz e
  legenda chegam num turno só, nessa ordem (`@file:`, transcrição, legenda);
  a tira mostra cada item com remoção; retry não repete upload (A84) e o
  rascunho fica se o gateway não abrir (A85). **Decisão de design pendente:**
  gravar com texto já digitado exigiria mostrar microfone e enviar juntos no
  canto direito, o que o comentário do composer evitava de propósito. Falta
  aceite no aparelho.

- [ ] **A79 Corrigir interrupção e enfileiramento durante execução.** Reproduzir
  o bug do botão Parar e oferecer envio de uma nova mensagem enquanto o turno
  está em andamento (steer/fila conforme o contrato medido). Distinguir
  claramente interromper, enfileirar e enviar após o término; não perder nem
  executar duas vezes uma mensagem em reconexão. Critério de aceite: Parar
  interrompe apenas o turno pretendido e reconcilia seu estado; uma mensagem
  enfileirada é exibida com estado fiel, pode ser acompanhada até execução ou
  rejeição e não é confundida com resposta já enviada. Cobrir toque repetido,
  rede instável, troca de conversa e retorno ao app.

- [ ] **A76 Ajustar o Markdown das ações no estilo Obsidian.** Reproduzir com
  mensagens reais onde ações, tarefas ou instruções em Markdown aparecem
  incorretamente no chat; comparar o texto original com a renderização e
  corrigir o parser/estilo sem perder semântica (listas de tarefas, callouts,
  links e blocos de código quando presentes). Critério de aceite: as ações
  ficam legíveis e distinguíveis no streaming e ao reabrir a conversa, sem
  expor Markdown cru nem alterar trechos de código ou texto comum.

- [~] **A77 Atualizar a conversa ao sair e voltar ao app.** Ao retornar do
  background ou reabrir o app, reconciliar a conversa selecionada com o
  histórico/estado remoto antes de apresentá-la como atualizada, preservando
  mensagens locais e o turno em curso. Não duplicar mensagens, perder a
  posição de leitura nem reenviar prompts ou decisões interativas. Critério
  de aceite: uma resposta concluída enquanto o app estava fora aparece ao
  voltar; falha de rede mostra estado recuperável; testes cobrem retorno
  com turno ativo, histórico sem mudanças e troca de conversa durante refresh.

  Implementado em 2026-11-08: com turno ativo, a retomada que já existia
  segue igual; sem turno, voltar ao app ou à rota do chat relê o histórico
  (Dashboard quando pareado, senão API) e troca a timeline só se o servidor
  estiver à frente. Não mexe com envio em andamento, cartão de aprovação ou
  clarify, nem com outra conversa aberta no meio; não apaga envio local que
  o servidor não tem; sem mudança não reescreve o estado; sem rede mantém a
  tela. Falta aceite no aparelho (conversa continuada no desktop).

- [~] **A94 Acompanhar o contrato do Hermes 0.22.5.** Boot sem skills e com a
  causa HTTP preservada, fallback do catálogo para o Dashboard, aprovação da
  Runs API com `request_id` + `execution_generation`, `approval.settled`,
  `run.interrupted` e listagem sem `include_children`, implementados em
  2026-10-31. Falta: aceite no aparelho (folha de Modelo, Contexto e Skills
  contra o servidor real); relatar ao `hermes-agent` o `500` de `/v1/skills`
  (chamada com `include_editorial`); e decidir se o fallback Runs deve tratar
  `clarify.request`/`/v1/runs/{id}/clarify` e steer.

- [!] **A42 Ícone e splash.** Aguarda arte ou direção visual aprovada pelos
  mantenedores. Não gerar nem substituir a identidade sem esse insumo.

## Recursos do runtime 0.22.5

Aprovados em 2026-11-01 a partir de
[oportunidades-0.22.5.md](../hermes-api/oportunidades-0.22.5.md), na ordem de
prioridade. Antes de implementar cada um, medir o contrato no `hermes-agent` e
registrá-lo; operações destrutivas pedem confirmação explícita na interface.

- [!] **A98 Contexto da conversa viva.** Mostrar o uso de contexto da sessão
  aberta (`session.usage`, `session.context_breakdown`). Absorve a parte de
  `session.usage` do B10. A parte HTTP (Ajustes › Uso por período) foi aceita
  no aparelho. **Bloqueado em decisão:** os dois métodos estão fora da
  allowlist TUI. Billing do Nous não foi medido.

- [ ] **A104 Baixar arquivos citados na conversa.** Pedido do usuário em
  2026-11-08. Hoje um `MEDIA:` que não é imagem aparece só como "Arquivo no
  servidor" (`agent_media_figure.dart`), sem ação: `/api/media` serve apenas
  imagens. Permitir baixar ou abrir o arquivo no aparelho (salvar, compartilhar
  ou abrir com outro app), com nome, tamanho e progresso, e explicar a recusa
  quando o servidor não permitir. Candidatos no Dashboard 0.22.6:
  `/api/files/ticket` + `/api/files/download` e `/api/files/stream`
  (`hermes_cli/web_routers/files.py`); conferir a política de pastas
  permitidas e a autenticação antes de usar. Arquivo baixado não pode ir para
  log nem cache compartilhado.

## Notificações

- [~] **A60 Notificações do Hermes e canal arbitrário do agente.** Entregar em
  duas fases:

  1. apresentação local segura de eventos úteis, como erro, conclusão de
     trabalho e skill criada;
  2. entrega arbitrária em foreground, background e app encerrado, com envelope,
     id/dedupe, inbox durável, registro/revogação, retry, expiração e privacidade
     na tela bloqueada.

  WebSocket sozinho não cobre app encerrado. Serviço externo, dependência nova
  ou mudança no Gateway exige decisão explícita dos mantenedores. Uma notificação pode
  abrir a conversa, mas nunca executar ação do agente. A arquitetura, a fronteira
  com o Gateway e a sequência de migração estão em
  [NOTIFICATIONS_ARCHITECTURE.md](NOTIFICATIONS_ARCHITECTURE.md).

  Decidido pelo usuário em 2026-11-08: UnifiedPush com o app ntfy como
  distribuidor e ntfy self-hosted como relay; sem Firebase; payload mínimo
  (tipo e título da conversa). Nenhum plugin pronto servia (turn-bell,
  ntfy-approval, signal-notify, telegram-notify, pushover avaliados), então
  entrou um plugin próprio, `server/mobile-push`, no molde do signal-notify
  (MIT). Ele escuta `on_session_end` e `on_human_input_request`/`_resolved`,
  cifra WebPush `aes128gcm` com a chave do aparelho (vetor da RFC 8291 nos
  testes) e expõe o registro de aparelhos em `/api/plugins/mobile-push/devices`,
  atrás do login do Dashboard. No app: Ajustes › Notificações, registro no
  distribuidor e no plugin, isolate headless (`--unifiedpush-bg`) que mostra o
  aviso com o app fechado, toque abre `hermes://app/chat/<id>`, e nada de aviso
  da conversa que está na tela. Dependências novas: `unifiedpush_android`,
  `unifiedpush_platform_interface` e `flutter_local_notifications` 22 (a 23
  exige AGP 9.1). Aviso local deduzido pelo app foi descartado: fora da tela o
  `ChatController` solta os listeners do turno, então só o servidor sabe quando
  um turno termina em segundo plano. Validado no emulador contra o Dashboard
  real: permissão, estado sem distribuidor e "plugin não encontrado". **Falta**
  instalar o plugin no servidor e o roteiro de aparelho em
  [USER_TESTING.md](USER_TESTING.md); iOS fica sem push (UnifiedPush não existe
  lá).

## Gateway TUI e runtime

- [~] **B0 Validar o live chat contra o runtime publicado.** Auditoria do
  0.22.5 feita em 2026-10-31:
  [tui-contrato-0.22.5-medido.md](../dashboard-api/tui-contrato-0.22.5-medido.md).
  Nada quebra no deployment padrão. Corrigido: histórico concluído passou de
  `session.history` (que dava 4001 ao id durável) para
  `GET /api/sessions/{id}/messages` do Dashboard, e `theme.apply`,
  `theme.pick` e `setup_beat` recebem `4404`; turno concluído sem nada na
  bolha (prompt repassado ao dono do gateway) relê a conversa salva; o
  diagnóstico mostra `session_authority`. Falta: aceite no aparelho de que uma
  conversa concluída abre pelo histórico do Dashboard, e validar o Mobile
  contra um gateway em session authority quando houver um. Recursos novos não
  usados estão em
  [oportunidades-0.22.5.md](../hermes-api/oportunidades-0.22.5.md).

- [ ] **B10 Tratar eventos novos do `0.20.1`.** Decidir a semântica de
  `sessions.changed` e `session.usage`. `tool.output_risk` foi implementado e
  aceito em B12. Avaliar também
  os campos adicionais de `session.info`. Nenhum dado sem semântica e tratamento
  seguro confirmados vira texto do assistant ou configuração editável.

- [~] **B9 Mostrar subagents na timeline.** Reduzir eventos `subagent.*` em um
  bloco aninhado, sem convertê-los em texto do assistant. Cobrir spawn, thinking,
  tool, progress, complete e reconciliação.

  Implementado em 2026-11-08 contra o contrato do 0.22.6
  (`tui_gateway/contracts/events.py`: todo frame traz `goal`, `task_count` e
  `task_index`; `subagent_id`, `delegation_id`, `status`, `summary` e
  `duration_seconds` opcionais). Cada agente vira um bloco na timeline
  cronológica, na posição em que apareceu: "Subagente i/n · estado", o
  objetivo, a última ferramenta ou nota enquanto roda e o resumo ao terminar.
  `thinking`/`progress` deixaram de virar prévia solta. Chave por
  `subagent_id`, senão `delegation_id#task_index`; início para chave já
  encerrada abre bloco novo. Fim do turno fecha quem ficou aberto. Limites:
  o modo consolidado ainda não mostra subagents, e o histórico persistido não
  traz os frames, então reabrir a conversa perde o bloco (não é inventado).
  Falta aceite com uma delegação real no aparelho.

- [ ] **B14 Tirar subagents da listagem plana e agrupá-los no chat pai.**
  Recomendação: manter a lista principal só com conversas humanas, exibir no
  chat pai um grupo recolhível de subagents com estado, resumo e acesso aos
  detalhes, sem apagar sessões ou misturar transcrições na fala da Claudia.
  O vínculo por `parent_session_id` sozinho NÃO identifica subagent (branches,
  resets e compressão também são filhos); classificar pelo marcador de delegate
  e confirmar `source` no runtime. O TUI já emite `subagent.*` e oferece
  `subagent.list` para agentes em execução, mas essa lista não é histórico
  completo. No 0.22.5, `GET /api/sessions` oculta subagents por padrão e honra
  `include_children` (o Mobile deixou de mandá-lo); cada sessão traz
  `is_internal_child`, o marcador seguro de subagent.
  Antes de prometer agrupamento histórico, validar endpoint autorizado de
  filhos persistidos, paginação, parentesco após compressão e reconexão.
  Primeira fase sem mudar o Gateway: filtrar somente linhas identificadas com
  segurança como subagents e agrupar eventos ao vivo no pai (B9); se não houver
  metadados suficientes, manter a linha acessível em vez de ocultá-la.
  Critério de aceite: nenhuma branch legítima desaparece; subagents em paralelo
  aparecem uma vez no pai, com estado fiel após reabrir/reconectar; histórico
  parcial é sinalizado, não inventado; busca, paginação e contadores não
  perdem sessões. Qualquer API nova para histórico exige decisão separada.

- [ ] **B11 Painel de tarefas por turno.** Medir primeiro `todo.updated` no TUI
  Gateway real: payload, IDs estáveis, vínculo com sessão/turno, ordem,
  parentesco, estados e comportamento em reconexão/histórico. Só então criar um
  modelo Dart e um painel responsivo de leitura com **Tarefas X/Y**. A primeira
  versão não cria, edita, reordena nem conclui itens: qualquer mutação exige RPC
  e autorização confirmados pelo contrato.

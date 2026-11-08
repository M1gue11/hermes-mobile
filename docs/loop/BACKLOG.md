# Backlog ativo do Hermes Mobile

Esta é a fonte única de trabalho acionável do Hermes Mobile. Decisões técnicas
duráveis ficam nos contratos em `docs/dashboard-api/` e no histórico Git.

Estados: `[ ]` aberto, `[~]` implementado com validação pendente, `[!]` bloqueado.
O plano de ataque de produto e interface está em
[PRODUCT_INTERFACE_PLAN.md](PRODUCT_INTERFACE_PLAN.md).

## Agora

- [~] **A75 Confiabilidade do clarify batch.** O Mobile aceita o contrato atual
  do TUI Gateway (`clarify.request` single e batch), preserva respostas de
  replay travadas e envia uma resposta por `qid`. Falta aceite Android com um
  batch real, incluindo retry após falha de rede e multi-seleção.

- [~] **A73 Manter a expansão da timeline estável no controle tocado.** Tools,
  raciocínio e `Mostrar mais ferramentas` suspendem o acompanhamento antes de
  abrir ou recolher. Uma única transição vertical revela o conteúdo abaixo
  do controle, então o cabeçalho permanece sob o dedo e o conteúdo seguinte
  desce sem compensação geométrica ou `jumpTo`. A mesma regra vale nos modos
  cronológico e consolidado. Falta validar no aparelho expansão, recolhimento
  rápido, texto ampliado e redução de movimento.

- [~] **A74 Fazer o streaming acompanhar o fim somente por intenção.** Uma
  lista cronológica normal mantém o offset pausado intocado. Enquanto a intenção
  de acompanhar estiver ativa, mudanças de altura sincronizam a cauda já medida
  com o fim, sem animação por token. Qualquer gesto de rolagem, busca ou
  divulgação pausa imediatamente; só o retorno ao fim, um novo envio ou outra
  conversa reatam o acompanhamento. Falta validar no aparelho o streaming real,
  a leitura pausada e a retomada explícita.

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
- [ ] **A92 Revisar transporte HTTP/WS em `*.ts.net`.** Documentar ameaça e
  controles para a exceção cleartext; preferir proteção autenticada do serviço
  quando aplicável, sem confundir criptografia Tailscale com TLS do servidor.
- [ ] **A93 Preparar distribuição Android release.** Definir application ID,
  assinatura release sob custódia apropriada e canal de distribuição; não
  publicar APK release assinado com chave debug. O CI atual só constrói debug.

## Produto e interface

- [~] **A103 Operar o Hermes a partir da conversa.** Detalhes no título;
  Recursos no compositor (Skills, Ferramentas/MCP e instruções); menu Hermes
  com Acessos, Uso geral, Agendamentos, Servidor e Ajustes. Telas inteiras
  fecham o seletor e voltam direto à conversa, preservando rascunho e leitura.
  Uso da sessão e uso geral permanecem distintos; ferramentas explicam que a
  alteração vale para novas conversas. Copiar/ouvir têm alvo de 48 dp e
  acomodam texto ampliado. Brief em [A103_INTERFACE_BRIEF.md](A103_INTERFACE_BRIEF.md).
  Falta aceite em aparelho; badges atualizados e busca global dentro do chat
  ficam para outra etapa, sem dependências nem métodos TUI novos.

- [ ] **A78 Permitir arquivo e áudio no mesmo envio.** Hoje o compositor força
  escolher um ou outro. Permitir preparar anexo(s), gravar áudio e incluir texto
  no mesmo turno sem apagar a seleção anterior; oferecer revisão, remoção e
  confirmação do que será enviado. Respeitar o contrato real: voz é transcrita
  em texto por `/api/audio/transcribe`, enquanto `file.attach` retorna
  `ref_text`; não prometer entrega do áudio original como anexo sem suporte
  medido. Critério de aceite: arquivo + voz + texto chegam na ordem esperada,
  sem envio duplo, perda silenciosa ou upload sem consentimento; falha parcial
  mantém o rascunho recuperável. Testar permissões e retorno do background.

- [ ] **A79 Corrigir interrupção e enfileiramento durante execução.** Reproduzir
  o bug do botão Parar e oferecer envio de uma nova mensagem enquanto o turno
  está em andamento (steer/fila conforme o contrato medido). Distinguir
  claramente interromper, enfileirar e enviar após o término; não perder nem
  executar duas vezes uma mensagem em reconexão. Critério de aceite: Parar
  interrompe apenas o turno pretendido e reconcilia seu estado; uma mensagem
  enfileirada é exibida com estado fiel, pode ser acompanhada até execução ou
  rejeição e não é confundida com resposta já enviada. Cobrir toque repetido,
  rede instável, troca de conversa e retorno ao app.

- [~] **A80 Integrar comandos rápidos com paridade ao Telegram.** Inventariar
  os comandos realmente disponíveis no Telegram e no runtime TUI, mapear
  diferenças de permissão/efeito e implementar descoberta, sugestões ao digitar
  `/`, descrição e execução dos comandos compatíveis no Mobile. Não emular
  comando administrativo como prompt comum nem liberar `slash.exec`,
  `command.dispatch` ou outro RPC sem contrato e autorização específicos.
  Critério de aceite: comandos suportados funcionam com confirmação para ações
  sensíveis e feedback de sucesso/erro; indisponíveis são explicados, não
  exibidos como funcionais. Cobrir argumentos, cancelamento e histórico.

  Implementado em 2026-11-02, com autorização do usuário para a integração:
  sugestões ao digitar `/`, Recursos > Comandos, execução com confirmação para
  alterações, relatórios copiáveis, prefill, Skills e aliases. Descoberta e
  execução usam o id vivo e o mesmo canal do turno, sem repetir mutações após
  resposta perdida. `/stop` usa a interrupção real; desfazer relê o histórico.
  Inventário estático de 104 comandos e diferenças de superfície em
  [mobile-command-inventory-0.22.5.md](../dashboard-api/mobile-command-inventory-0.22.5.md).
  Contrato e evidências em [mobile-commands-0.22.5.md](../dashboard-api/mobile-commands-0.22.5.md).
  Sem alteração do runtime ou dependência nova. Aceite físico pendente.

- [ ] **A76 Ajustar o Markdown das ações no estilo Obsidian.** Reproduzir com
  mensagens reais onde ações, tarefas ou instruções em Markdown aparecem
  incorretamente no chat; comparar o texto original com a renderização e
  corrigir o parser/estilo sem perder semântica (listas de tarefas, callouts,
  links e blocos de código quando presentes). Critério de aceite: as ações
  ficam legíveis e distinguíveis no streaming e ao reabrir a conversa, sem
  expor Markdown cru nem alterar trechos de código ou texto comum.

- [ ] **A77 Atualizar a conversa ao sair e voltar ao app.** Ao retornar do
  background ou reabrir o app, reconciliar a conversa selecionada com o
  histórico/estado remoto antes de apresentá-la como atualizada, preservando
  mensagens locais e o turno em curso. Não duplicar mensagens, perder a
  posição de leitura nem reenviar prompts ou decisões interativas. Critério
  de aceite: uma resposta concluída enquanto o app estava fora aparece ao
  voltar; falha de rede mostra estado recuperável; testes cobrem retorno
  com turno ativo, histórico sem mudanças e troca de conversa durante refresh.

- [~] **A72 Aplicar a persona configurada de ponta a ponta.** A configuração de
  nome/gênero foi validada, mas ainda existem fallbacks visíveis como `Hermes`
  e `Hermes Agent`. Inventariar toda cópia apresentada ao usuário — cabeçalhos,
  estados vazios, mensagens, acessibilidade, notificações, erros, diálogos e
  metadados — e distinguir identidade configurável de nomes técnicos que
  precisam permanecer estáveis. Critério de aceite: com uma persona diferente,
  nenhum texto de produto chama o agente de Hermes; ocorrências técnicas
  inevitáveis ficam justificadas em teste ou documentação.

  Inventário de 2026-10-31: o estado vazio usa `AgentPersona.emptyStateLabel`
  (`HERMES AGENT` só sem persona) e o rótulo de modelo mostra `PADRÃO` sem id
  ou com o alias `hermes-agent`, em vez de `HERMES` ao lado do nome da persona
  no cabeçalho, na bolha e no chip. Ainda não há notificações locais. Ficam
  como Hermes, por nomearem o servidor, o runtime ou o app e não o agente: erros
  de `HermesFailure`, `gateway_repository` e `http_hermes_repository`; chave da
  API e `Hermes API Server` em Conexão; `instructions` enviado ao Hermes;
  `Abrir fora do Hermes?`; saída sinalizada pelo Hermes (`tool.output_risk`);
  o rótulo do app no launcher e o fallback/hint da própria tela de persona.
  Falta conferir no aparelho com uma persona configurada.

- [~] **A65 Criar gestão completa de Skills.** Substituir a ação `tune` por uma
  tela inteira e realocar o atual `Contexto` para Ajustes ou uma ação secundária
  nomeada. Escopo mínimo: listar, buscar/filtrar, ler `SKILL.md`, editar com
  proteção contra perda e ativar/desativar no perfil atual.

  A primeira fase somente leitura já está aceita. O próximo recorte exige
  contrato autenticado real para corpo integral, edição protegida, exclusão com
  confirmação, ativação/desativação persistida e estado inequívoco no catálogo e
  no detalhe. Enquanto a API Server oferecer somente metadados em `/v1/skills`,
  não fingir edição, toggle ou marketplace.

  Medido no 0.22.5: o Dashboard já tem `GET/PUT /api/skills/content` (corpo
  integral e reescrita) e `PUT /api/skills/toggle`, mas nenhuma exclusão de
  skill local. Ver [contrato 0.22.5](../hermes-api/contrato-0.22.5-medido.md).

  Implementado em 2026-10-31: com o Dashboard logado, o catálogo vem dele
  (inclui desativadas, marcadas na lista); o detalhe virou rota
  `/skills/skill?name=` com `SKILL.md` integral e chave de ativação; o editor
  `/skills/skill/edit?name=` pede confirmação ao sair com alterações, relê o
  servidor antes de gravar (o Dashboard não tem versão; quem grava por último
  vence) e mostra a recusa do Dashboard sem fechar. Sem Dashboard, continua
  somente leitura pelo API Server. Falta o aceite em aparelho
  ([USER_TESTING.md](USER_TESTING.md)). Exclusão segue fora: o servidor não
  tem rota para skill local (só `hub/uninstall` para skills do hub).

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

- [~] **A95 Agendamentos.** Listar, pausar, retomar, disparar agora e criar
  rotinas por `/api/jobs*` do API Server (só a chave Bearer). Excluir com
  confirmação. Histórico de execuções e modelos prontos (`/api/cron/*`) exigem
  o Dashboard e ficam para depois.

  Implementado em 2026-11-01: tela em Ajustes > Agendamentos (`/jobs`), com
  ativas antes das pausadas, folha de detalhe com executar agora, pausar,
  retomar e excluir, e criação em `/jobs/new` com proteção ao sair e a recusa
  do servidor visível. "Executar agora" só aparece em rotina ativa, porque no
  servidor ele reativa uma pausada. Servidor sem cron (`501`) mostra
  indisponível. Contrato em
  [05-sessions-jobs.md](../hermes-api/05-sessions-jobs.md). Falta aceite no
  aparelho e, depois, editar rotina (`PATCH`).

- [~] **A96 Imagens geradas pelo agente.** Mostrar na conversa as imagens e
  capturas que o agente referencia (`MEDIA:`), lidas por `GET /api/media` do
  Dashboard, respeitando tipos e pastas que o servidor permite. Sem Dashboard,
  mostrar a referência sem quebrar a mensagem.

  Implementado em 2026-11-02: `MEDIA:<caminho absoluto>` fora de código vira
  figura com o nome do arquivo, revelada com a entrada de tinta; o toque abre
  o visualizador (pinça, toque duplo, arrastar para fechar, Hero). SVG, ICO e
  não imagens ficam como referência com o caminho selecionável; recusa do
  servidor aparece com a causa, e só falha de rede oferece tentar de novo.
  `![alt](data:...)` também vira figura. Aceite no emulador contra o 0.22.5:
  PNG gerado pelo agente em `HERMES_HOME/images` apareceu, ampliou e fechou.
  Contrato em [contrato-0.22.5-medido.md](../hermes-api/contrato-0.22.5-medido.md).
  Falta conferir no aparelho os estados sem Dashboard e de recusa, e decidir
  se vale usar `/api/media/proxy` para URLs do FAL.

- [~] **A97 Saúde, logs e restart do gateway.** Ler `/health/detailed`,
  `/api/system/stats` e `/api/logs` (filtro por nível e busca) e reiniciar o
  gateway com `POST /api/gateway/restart`, acompanhando o status da ação. Não
  oferecer `stop`, que derruba o próprio acesso do app.

  Implementado em 2026-11-02: Ajustes > Servidor (`/server`) mostra a fase do
  gateway com sessões, turnos e plataformas, as verificações e o uso do dia
  do API Server e processador, memória e disco da máquina. Logs em
  `/server/logs`, do mais novo para o mais antigo, com arquivo (agente, erros,
  gateway), nível mínimo e busca no servidor; traceback fica colado ao
  registro e registros longos abrem recolhidos. Reiniciar pede confirmação
  (avisa quando há turno em andamento) e acompanha pedido, parada e subida
  até o `/api/status` mostrar um estado novo; falha mostra o motivo. Aceite
  no emulador contra o 0.22.5 da tela e dos logs reais. **Falta** exercitar
  o reinício num servidor que possa cair por alguns segundos; não foi
  disparado no servidor do usuário sem autorização. Contrato em
  [contrato-0.22.5-medido.md](../hermes-api/contrato-0.22.5-medido.md).

- [ ] **A98 Custo e contexto da conversa.** Mostrar tokens, custo e uso de
  contexto da sessão (`session.usage`, `session.context_breakdown`) e um
  resumo de uso por período (`/api/analytics/usage`). Absorve a parte de
  `session.usage` do B10. Billing parece específico do provider Nous: medir.

  Parte HTTP implementada em 2026-11-02: Ajustes > Uso (`/usage`) com 7, 30 e
  90 dias, custo (cobrado ou estimado) ou, sem custo registrado, tokens em
  destaque; barras de tokens por dia com o dia tocado detalhado; tokens de
  entrada, saída, cache e raciocínio; fatia por modelo. Aceite no emulador
  contra o 0.22.5 com dados reais (provedor por assinatura, custo 0). Tokens
  e custo por conversa já estavam na folha da conversa. **Falta decisão:** uso
  de contexto da sessão viva exige `session.usage` e
  `session.context_breakdown`, que estão fora da allowlist de métodos TUI.
  Billing do Nous não foi medido.

- [~] **A99 Busca no servidor, desfazer e compactar.** Busca em todas as
  conversas por `GET /api/sessions/search`; desfazer o último turno
  (`/undo`, com confirmação) e compactar o contexto
  (`/compress`), ambos só com a sessão ociosa e pelo gateway em A80.

  Busca implementada em 2026-11-02: com dois caracteres ou mais, a lista de
  conversas mostra "No conteúdo das conversas" com os resultados do servidor
  que a lista carregada não tem, trecho com o termo destacado, origem, autor
  e data; tocar abre a conversa. Sem Dashboard a busca local segue sozinha.
  Aceite no emulador contra o 0.22.5 (conversas antigas do Telegram achadas e
  abertas). Desfazer e compactar agora estão acessíveis por `/undo` e `/compress`
  na integração A80, com confirmação e atualização do histórico. Os métodos
  diretos `session.undo` e `session.compress` não foram adicionados à allowlist.

- [ ] **A100 Ligar e desligar toolsets e MCP.** Alternar toolsets
  (`PUT /api/tools/toolsets/{name}` ou `tools.configure`) e servidores MCP
  (`PUT /api/mcp/servers/{name}/enabled`, com teste). Não expor `/env`,
  chaves nem instalação de servidores.

  Implementado em 2026-11-02 pelo Dashboard HTTP (sem `tools.configure`):
  Ajustes > Ferramentas (`/tools`) lista os toolsets com chave, descrição,
  número de ferramentas e aviso de credencial ausente, e os servidores MCP
  com chave (travada para os de plugin) e "Testar conexão", que mostra as
  ferramentas encontradas ou o erro. A chave muda na hora e volta se o
  servidor recusar. Aceite no emulador contra o 0.22.5: lista real e teste
  do MCP homeassistant (11 ferramentas). **Falta** alternar no aparelho: não
  foi feito no servidor do usuário porque reescreve o `config.yaml`.

- [ ] **A101 Aprovar pareamento de plataformas.** Listar pedidos pendentes e
  aprovar ou revogar acesso de Telegram, WhatsApp e afins por
  `/api/pairing*`, com confirmação clara de que aprovar dá acesso ao agente.

  Implementado em 2026-11-02: Ajustes > Acessos (`/pairing`) lista quem pede
  acesso (nome, plataforma, id, há quanto tempo) e quem já tem; aprovar,
  revogar e "Recusar todos" pedem confirmação que diz o que cada ação libera
  ou tira. Pedidos antigos sem id avisam que a aprovação é pelo código no
  computador. Aceite no emulador contra o 0.22.5 só do estado vazio: o
  servidor do usuário não tinha pedidos. **Falta** aprovar um pedido real no
  aparelho.

- [~] **A102 Ouvir a resposta.** Tocar a resposta do agente por
  `POST /api/audio/speak`. Streaming de voz fica fora da primeira versão.

  Implementado em 2026-11-02: "Ouvir" no rodapé da resposta, ao lado das
  cópias, com o Dashboard pareado. Manda o texto de leitura (sem markdown nem
  `MEDIA:`, até 4.000 caracteres cortados em fim de frase), mostra "gerando
  áudio" com a marca, "parar" em âmbar enquanto toca e volta sozinho no fim.
  Uma resposta por vez; tocar outra interrompe a atual e uma síntese atrasada
  é descartada. Dependência nova `audioplayers`. Aceite no emulador contra o
  0.22.5 (síntese em ~6 s, reprodução e volta ao repouso). **Falta** ouvir no
  aparelho e decidir se vale ouvir com a tela bloqueada.

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
  `sessions.changed` e `session.usage`. `tool.output_risk` foi implementado em
  B12, ainda com aceite real específico pendente. Avaliar também
  os campos adicionais de `session.info`. Nenhum dado sem semântica e tratamento
  seguro confirmados vira texto do assistant ou configuração editável.

- [~] **B12 Projetar `message.interim` e `tool.output_risk` com segurança.**
  `message.interim` tem bloco próprio e trata `already_streamed`, inclusive na
  reconstrução do histórico; `tool.output_risk` tem affordance redigida sem
  findings sensíveis nem Markdown do assistant. Modelo, projeção, política de
  redaction e testes implementados em 2026-10-11.
  Falta aceite real de interim/risco na build atual; ver
  [auditoria 0.21.6](../dashboard-api/mobile-streaming-audit-0.21.6.md).

- [~] **B13 Reconciliar eventos TUI após reconexão.** Capturar `seq` e
  `session_id` dos frames e `replay_epoch` de `gateway.ready`. Ao recuperar
  uma conversa, consultar `session.events.since` com o último watermark
  confirmado, mesclar sem duplicar timeline e restaurar `open_requests`.
  Quando `truncated=true` ou o epoch mudar, invalidar o cursor e reconstruir
  pelo snapshot/histórico sem substituir um turno ativo mais completo. Testar
  queda entre `tool.start`/`tool.complete`, aprovação pendente, restart do
  backend e ordem de eventos. O suporte a `open_requests` no `session.resume`
  não substitui o replay dos demais eventos.
  Implementação e fixtures de ordem/dedupe, cursor síncrono, ring truncado e
  epoch concluídos em 2026-10-11. Aceite real da rotina: 10 tools, replay de
  13 eventos após background, um submit e reabertura concluída. Restam aprovação
  pendente, restart e ring expirado, inclusive o limite do snapshot sem watermark
  atômico; ver a auditoria 0.21.6.

- [ ] **B9 Mostrar subagents na timeline.** Reduzir eventos `subagent.*` em um
  bloco aninhado, sem convertê-los em texto do assistant. Cobrir spawn, thinking,
  tool, progress, complete e reconciliação.

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

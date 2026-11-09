# Backlog ativo do Hermes Mobile

Esta é a fonte única de trabalho acionável do Hermes Mobile. Decisões técnicas
duráveis ficam nos contratos em `docs/dashboard-api/` e no histórico Git; o que
já foi aceito ou decidido sem trabalho restante vai para o vault pessoal, em
"Histórico e decisões do loop".

Estados: `[ ]` aberto, `[~]` implementado com validação pendente, `[!]` bloqueado.
O plano de ataque de produto e interface está em
[PRODUCT_INTERFACE_PLAN.md](PRODUCT_INTERFACE_PLAN.md).

## Agora

1. **A104**, **A92** e **A79** implementados; falta o aceite em aparelho.
   **A78** já seleciona vários arquivos; voz com texto ainda espera A105.
2. Próximos itens com decisão tomada em 2026-11-08: B9 (refino dos
   subagentes), A98/B10 (contexto da conversa
   viva) e o pacote da barra de mensagem (A105 design, A78 anexos e voz,
   A106 controles de envio), que começa pelo desenho de
   A105.
3. Aceites em aparelho pendentes: A60, A77, A89 e A91, com roteiros em
   [USER_TESTING.md](USER_TESTING.md).

## Próximo

- [~] **A104 Baixar arquivos citados na conversa.** Pedido do usuário em
  2026-11-08. Hoje um `MEDIA:` que não é imagem aparece só como "Arquivo no
  servidor" (`agent_media_figure.dart`), sem ação: `/api/media` serve apenas
  imagens. Permitir baixar ou abrir o arquivo no aparelho (salvar, compartilhar
  ou abrir com outro app), com nome, tamanho e progresso, e explicar a recusa
  quando o servidor não permitir. Candidatos no Dashboard 0.22.6:
  `/api/files/ticket` + `/api/files/download` e `/api/files/stream`
  (`hermes_cli/web_routers/files.py`); conferir a política de pastas
  permitidas e a autenticação antes de usar. Arquivo baixado não pode ir para
  log nem cache compartilhado.

  Implementado em 2026-11-09: ação **Baixar arquivo** no `MEDIA:` não-imagem,
  bytes/total/progresso, cancelamento e motivo da recusa. `GET
  /api/files/download` usa cookie em header, sem ticket ou token na URL,
  sem redirect; o servidor mantém sua política de pastas e arquivos sensíveis.
  Transferência em fluxo para temporário privado, removido ao concluir, falhar,
  cancelar ou sair; seletor nativo de destino no Android e iOS, sem dependência
  nova. Caminhos com espaços são preservados em diretivas isoladas na linha ou
  entre aspas (a sintaxe antiga cortava no primeiro espaço). Android validado
  com salvamento real de arquivo sintético; 320 dp/180%
  inspecionado, revisão visual `ship`. Runtime pareado já anuncia **0.23.0**:
  duas referências existentes foram recusadas, sem arquivo permitido para
  confirmar sucesso remoto. Falta esse aceite e compilar/testar o iOS em Mac.

## Barra de mensagem

Itens que mexem no mesmo ponto da tela e devem ser trabalhados juntos, com um
desenho único da barra antes de implementar cada um: A105 (design da barra),
A78 (anexos e voz), A106 (controles de envio), A79 (erro do Parar) e o
indicador de contexto de A98. A bandeja de subagentes de B9 (e talvez as
tarefas de B11) fica logo acima da barra e entra no mesmo desenho. Composer
hoje em `chat_screen.dart` (`_Composer`, `_ComposerSurface`, `_ComposerSlot`,
`_ComposerButton`, `_ComposerAttachmentStrip`, `_ComposerTextAction`) e
`attachment_composer_controller.dart`.

- [ ] **A105 Refinar design, animações, alinhamento e responsividade da
  barra de mensagem.** Pedido do usuário em 2026-11-08: a barra tem
  probleminhas e limitações, e o espaço é pouco aproveitado para o lugar mais
  importante da tela. Começar por um levantamento no aparelho (capturas em
  tela estreita, texto a 180%, teclado aberto e fechado, paisagem, várias
  linhas de texto, tira de anexos cheia, gravação, turno em andamento,
  aprovação pendente) e anotar cada defeito de alinhamento, salto e corte,
  medindo a tinta e não a caixa do texto. Depois propor ao usuário um
  desenho da barra inteira, com referência no `design/Hermes.dc.html` e no
  Hermes Desktop (que leva modelo, esforço, microfone e voz na própria barra),
  definindo:
  - o que mora na barra e o que vai para um menu: anexar, voz, modelo e
    esforço, indicador de contexto (A98), comandos e as ações de envio de
    A106;
  - estados: vazio, digitando, com anexos, gravando, turno rodando, turno
    esperando subagente, sem conexão;
  - transições animadas entre estados (troca enviar/parar/microfone,
    crescimento do campo, entrada e saída da tira de anexos), respeitando
    movimento reduzido;
  - comportamento responsivo: altura máxima do campo, quebra dos controles em
    tela estreita e com fonte ampliada, alvos de toque de 48 dp.

  O desenho é aprovado pelo usuário antes de mexer no código (desvio de
  design pede decisão). Critério de aceite: nenhum estado salta ou corta,
  rascunho e anexos sobrevivem a cada transição, e o leitor de tela anuncia
  cada controle.

- [ ] **A78 Vários arquivos de uma vez e voz com texto digitado.** A primeira
  parte (arquivo, voz e legenda no mesmo turno) foi aceita no aparelho em
  2026-11-08. Refino decidido pelo usuário no mesmo dia:
  - **seleção múltipla**: o seletor do sistema deixa escolher vários arquivos
    de uma vez (`openFiles` do `file_selector` em vez de `openFile`, em
    `device_attachment_source.dart`). Cada arquivo continua passando pelo
    limite de 25 MB, e o lote pelos limites do composer (A87: 10 anexos,
    50 MB no total); o que estourar é recusado com o nome do arquivo e o
    resto entra;
  - **gravar com texto já digitado**: o microfone fica disponível ao lado do
    enviar quando há texto. Mostrar os dois no canto direito sem ambiguidade
    sobre qual é a ação principal (enviar continua o primário). A transcrição
    entra antes da legenda, como hoje. O lugar exato sai do desenho de A105.

  Testes: lote com um arquivo grande demais, lote que estoura a contagem,
  gravação iniciada com texto e o texto preservado depois dela.

  Seleção múltipla implementada em 2026-11-09: `openFiles`, leitura sequencial
  limitada pelo orçamento restante, recusas por nome e aproveitamento do resto
  do lote. O seletor bloqueia novo toque enquanto está aberto. Testes cobrem
  tamanho individual, contagem, total e arquivo que cresce durante a leitura.
  Falta aceite do seletor no aparelho. O microfone com texto continua esperando
  o desenho de A105; nenhuma disposição dos controles foi alterada.

- [ ] **A106 Controles granulares de envio durante o turno.** Pedido do
  usuário em 2026-11-08: enfileirar mensagem, orientar o turno em andamento
  (steering) e afins. Absorve a parte de fila e steer que saiu de A79. Hoje,
  com o turno rodando, a barra só oferece Parar; o repositório já tem
  `steer()` sobre `session.steer` (método já na allowlist), mas nenhuma tela
  o usa. Ações a distinguir na interface, sem ambiguidade:
  - **orientar agora** (`session.steer`): o texto entra no turno em curso;
  - **enfileirar**: a mensagem espera o fim do turno e sai como turno novo;
  - **parar e enviar**: interrompe e manda em seguida;
  - **parar** sozinho, como hoje.

  Medir antes no 0.22.6, porque o contrato decide o que é possível:
  - o que o `session.steer` faz de fato (quando é aplicado, se gera evento,
    se falha fora de turno);
  - o que acontece com `prompt.submit` durante um turno (recusa, fila no
    servidor, ou turno concorrente); os frames já trazem `queued`,
    `submission_id` e `user_row_ids`, que o app ignora hoje;
  - se a fila deve morar no servidor ou no app. Fila local precisa
    sobreviver a background e reconexão sem enviar duas vezes nem se perder,
    e precisa poder ser editada ou cancelada antes de sair.

  Na timeline, a mensagem enfileirada aparece com estado fiel ("na fila",
  "enviada", "recusada") e nunca como resposta já entregue; o steer aparece
  como intervenção dentro do turno. No fallback Runs, mostrar só o que o
  contrato oferece (ver a pendência de steer em A94). `prompt.background`
  segue bloqueado sem decisão. Critério de aceite: toque repetido, rede
  instável, troca de conversa e retorno ao app não duplicam nem perdem
  mensagem. Gestos e lugar dos controles saem do desenho de A105.

- [~] **A79 Mostrar o erro do Parar.** Decidido pelo usuário em 2026-11-08:
  por enquanto, só fazer a falha aparecer. Hoje `ChatController.stop()`
  transforma a falha do interrupt em erro da resposta
  (`_failCurrentAssistant`), e sai em silêncio quando não há `runId`. Passa a
  mostrar o motivo no aviso flutuante que o composer já usa
  (`_showComposerError`, um `SnackBar`), sem marcar a resposta como falha,
  porque o turno pode continuar rodando. Fila e steer passaram para A106.

  Implementado em 2026-11-09: o controller devolve o motivo e o composer o
  mostra no `SnackBar`; `/stop` usa a mesma causa. Nem falha de interrupt nem
  ausência de identificação encerram o streaming ou marcam a resposta como
  falha. Regressões de controller e widget confirmam aviso e continuidade.
  Falta o aceite em aparelho.

## Segurança e distribuição

- [~] **A89 Encerrar gravação de áudio no lifecycle.** Cancelar recorder e
  descartar temporários ao sair da tela ou colocar o app em background.

  Implementado em 2026-11-08: a gravação é descartada (o `record` apaga o
  arquivo no `cancel`) quando o app vai para `hidden`/`paused`, quando outra
  rota cobre a conversa e quando o composer é descartado; a tela diz o motivo.
  `inactive` não interrompe, porque o diálogo de permissão do microfone e a
  cortina de notificações passam por ele. Falta conferir no aparelho que o
  indicador de microfone do Android apaga ao sair do app.
- [~] **A91 Confirmar a primeira host key SSH.** Exibir fingerprint e exigir
  confirmação consciente antes de confiar e persistir a chave.

  Implementado em 2026-11-08: na primeira conexão o handshake para no estágio
  `confirmandoHost`; a tela mostra a impressão digital e o comando para
  conferi-la no servidor, com "Confiar e conectar" e "Cancelar". Sem resposta
  em 90 s, ou saindo da sessão, é recusa; só se fixa a chave depois do
  "confio" e da sessão de pé. Falta o aceite contra um SSH real
  ([USER_TESTING.md](USER_TESTING.md)).
- [~] **A92 Conectar a qualquer URL, com avisos de segurança.** Decidido pelo
  usuário em 2026-11-08: tirar a trava. Hoje o API Server só aceita HTTPS e o
  HTTP/WS em claro só vale para o Dashboard em `*.ts.net`; passa a valer
  qualquer esquema `http`/`https` e qualquer host, IP incluído, nas duas
  conexões. Em troca, avisos explícitos e não bloqueantes:
  - no formulário de conexão, ao digitar `http://`: a chave, a senha, o cookie
    e as mensagens trafegam legíveis por quem estiver na rede, a menos que ela
    já seja cifrada (Tailscale, VPN);
  - aviso mais forte para host público fora de tailnet/rede privada;
  - um selo persistente de "conexão sem TLS" em Ajustes e no diagnóstico,
    para o aviso não sumir depois do pareamento.

  Mantém: validação de certificado TLS (aceitar certificado inválido seria
  outra decisão), clientes sem seguir redirect (a credencial não sai para
  outro host) e a regra de credencial por origem (A81). Mexe na
  `network_security_config` do Android (cleartext liberado na base), no ATS
  do iOS, na validação de `hermes_connection.dart` e no texto de
  [seguranca-transporte-tailnet.md](../seguranca-transporte-tailnet.md), do
  README e do HANDOFF, que hoje descrevem a exceção restrita. Testes:
  aceitar `http://` com IP e host público, aviso presente em cada caso,
  nenhum aviso para `https://`.

  Implementado em 2026-11-09: HTTP/HTTPS em qualquer host ou IP nos dois
  acessos, aviso ao digitar HTTP e selo persistente em Ajustes e Captura de
  turno. Hosts fora de rede privada/tailnet recebem aviso reforçado; a
  classificação é apenas textual e não promete VPN. Certificados continuam
  validados pelo sistema; HTTP e handshake WebSocket recusam redirects.
  Android libera cleartext na base; iOS usa `NSAllowsArbitraryLoads`.
  Dashboard segue exigindo origem sem caminho/query/userinfo, e o API Server
  conserva prefixo de caminho. A política Host do servidor continua valendo.
  Falta aceite em aparelho e validação iOS em Mac.
- [ ] **A93 Preparar distribuição Android release.** Definir application ID,
  assinatura release sob custódia apropriada e canal de distribuição; não
  publicar APK release assinado com chave debug. O CI atual só constrói debug.

## Produto e interface

- [ ] **A76 Ajustar o Markdown das ações no estilo Obsidian.** Reproduzir com
  mensagens reais onde ações, tarefas ou instruções em Markdown aparecem
  incorretamente no chat; comparar o texto original com a renderização e
  corrigir o parser/estilo sem perder semântica (listas de tarefas, callouts,
  links e blocos de código quando presentes). Critério de aceite: as ações
  ficam legíveis e distinguíveis no streaming e ao reabrir a conversa, sem
  expor Markdown cru nem alterar trechos de código ou texto comum. Precisa de
  mensagens reais de exemplo do usuário.

- [~] **A77 Atualizar a conversa ao sair e voltar ao app.** Ao retornar do
  background ou reabrir o app, reconciliar a conversa selecionada com o
  histórico/estado remoto antes de apresentá-la como atualizada, preservando
  mensagens locais e o turno em curso.

  Implementado em 2026-11-08: com turno ativo, a retomada que já existia
  segue igual; sem turno, voltar ao app ou à rota do chat relê o histórico
  (Dashboard quando pareado, senão API) e troca a timeline só se o servidor
  estiver à frente. Não mexe com envio em andamento, cartão de aprovação ou
  clarify, nem com outra conversa aberta no meio; não apaga envio local que
  o servidor não tem; sem mudança não reescreve o estado; sem rede mantém a
  tela. Falta aceite no aparelho (conversa continuada no desktop).

- [~] **A94 Acompanhar o contrato do Hermes 0.22.5.** Implementado em
  2026-10-31. Falta: aceite no aparelho (folha de Modelo, Contexto e Skills
  contra o servidor real); relatar ao `hermes-agent` o `500` de `/v1/skills`
  (chamada com `include_editorial`); e decidir se o fallback Runs deve tratar
  `clarify.request`/`/v1/runs/{id}/clarify` e steer.

- [!] **A42 Ícone e splash.** Aguarda arte ou direção visual aprovada pelos
  mantenedores. Não gerar nem substituir a identidade sem esse insumo.

## Recursos do runtime 0.22.5

Aprovados em 2026-11-01 a partir de
[oportunidades-0.22.5.md](../hermes-api/oportunidades-0.22.5.md). Antes de
implementar cada um, medir o contrato no `hermes-agent` e registrá-lo;
operações destrutivas pedem confirmação explícita na interface.

- [ ] **A98 Contexto da conversa viva.** Autorizado pelo usuário em
  2026-11-08: o app passa a chamar `session.usage` e
  `session.context_breakdown` pelo `/api/ws`. Os dois são de leitura e o
  gateway já os atende (o Desktop usa); a "allowlist" que travava era a do
  próprio app, então nada muda no servidor. Mostrar o uso de contexto da
  conversa aberta (quanto da janela está ocupado e por quê) na barra de
  mensagem, junto do seletor de modelo, com o detalhe na folha de detalhes;
  o lugar exato sai do desenho de A105. Medir antes o retorno no 0.22.6:
  `usage` opcional e `plan_gauge` (`events.py:318-351`); billing do Nous não
  foi medido e não entra sem medir. A parte HTTP (Ajustes › Uso por período)
  já foi aceita.

## Notificações

- [~] **A60 Notificações do Hermes e canal arbitrário do agente.** Push com o
  app fechado por UnifiedPush (app ntfy como distribuidor, ntfy self-hosted
  como relay), payload mínimo (tipo e título da conversa) e o plugin próprio
  `server/mobile-push`. Arquitetura em
  [NOTIFICATIONS_ARCHITECTURE.md](NOTIFICATIONS_ARCHITECTURE.md); o plugin
  tem README e testes próprios. Uma notificação pode abrir a conversa, mas
  nunca executar ação do agente. **Falta** instalar o plugin no servidor
  (decisão do usuário) e o roteiro de aparelho em
  [USER_TESTING.md](USER_TESTING.md). iOS fica sem push (UnifiedPush não
  existe lá). Subir o AGP para 9.1 destrava `flutter_local_notifications` 23.

## Gateway TUI e runtime

- [ ] **B9 Subagentes como no Hermes Desktop.** A primeira versão (bloco
  "Subagente i/n" na timeline, implementada em 2026-11-08 contra o contrato
  do 0.22.6) foi testada pelo usuário e precisa de refino. Direção, a partir
  da captura do Desktop enviada no mesmo dia:

  1. **Cartão na conversa**, no ponto em que a delegação aconteceu: ícone de
     estado animado, a tarefa numa linha truncada, selo do modelo do
     subagente, tempo decorrido correndo e um botão de expandir; abaixo, em
     mono, a ferramenta em curso (`Terminal("date --iso-8601=ns")`). Borda
     fina em tom de destaque e fundo levemente tingido. A fala do agente
     principal continua abaixo do cartão.
  2. **Bandeja acima do composer**, recolhível: cabeçalho "1 subagente" (ou
     "N subagentes") com seta e atalho para abrir; cada linha mostra estado,
     tarefa, ferramenta em curso e tempo. Serve para acompanhar o que roda
     em segundo plano sem rolar a conversa. Some quando não há subagente
     ativo.
  3. **Turno pai que espera**: quando o agente principal encerra a fala e
     deixa a delegação rodando, a conversa mostra uma linha de estado
     ("Retoma quando a tarefa em segundo plano terminar"), e o agente
     principal volta a falar quando ela acaba.

  Consequências para o código atual: hoje o fim do turno fecha os subagentes
  abertos (`settleTurnTools`), o que está errado para delegação em segundo
  plano; o ciclo de vida do subagente passa a ser da conversa, não do turno.
  Medir antes no 0.22.6, disparando a rotina da captura ("execute a rotina
  de teste de tools por subagente, nove chamadas de terminal"): se frames
  `subagent.*` chegam depois do fim do turno pai, como a retomada do pai é
  anunciada, se o frame traz o modelo (o contrato medido não lista; sem o
  campo, o selo some) e o que `subagent.list` devolve para repovoar a bandeja
  ao reconectar (método fora da allowlist do app: pede decisão antes de
  usar). Tempo decorrido conta localmente desde o primeiro frame e fecha com
  `duration_seconds`. Tocar no cartão ou na linha abre o detalhe (tarefa
  inteira, ferramentas, resumo). Continua valendo: nada do subagente vira fala
  do assistant, e o histórico persistido não traz os frames (reabrir não
  inventa bloco). Relaciona-se com B14.

- [~] **B0 Validar o live chat contra o runtime publicado.** Auditoria do
  0.22.5 em
  [tui-contrato-0.22.5-medido.md](../dashboard-api/tui-contrato-0.22.5-medido.md).
  Falta: aceite no aparelho de que uma conversa concluída abre pelo histórico
  do Dashboard, e validar o Mobile contra um gateway em session authority
  quando houver um.

- [ ] **B10 Tratar eventos novos do `0.20.1`.** Com A98 autorizado:
  `session.usage` como evento atualiza o mesmo indicador de contexto de A98,
  e `sessions.changed` (sem payload) recarrega a lista de conversas quando
  ela estiver visível, com debounce. Avaliar também os campos adicionais de
  `session.info`. Nenhum dado sem semântica e tratamento seguro confirmados
  vira texto do assistant ou configuração editável.

- [ ] **B14 Tirar subagents da listagem plana e agrupá-los no chat pai.**
  Manter a lista principal só com conversas humanas e exibir no chat pai um
  grupo recolhível de subagents com estado, resumo e acesso aos detalhes, sem
  apagar sessões ou misturar transcrições na fala da Claudia. O vínculo por
  `parent_session_id` sozinho NÃO identifica subagent (branches, resets e
  compressão também são filhos). No 0.22.5, `GET /api/sessions` oculta
  subagents por padrão e cada sessão traz `is_internal_child`, o marcador
  seguro. Antes de prometer agrupamento histórico, validar endpoint autorizado
  de filhos persistidos, paginação, parentesco após compressão e reconexão;
  se não houver metadados suficientes, manter a linha acessível em vez de
  ocultá-la. Qualquer API nova para histórico exige decisão separada. Precisa
  medir eventos disparando turnos no servidor do usuário.

- [ ] **B11 Painel de tarefas por turno.** Medir primeiro `todo.updated` no TUI
  Gateway real: payload, IDs estáveis, vínculo com sessão/turno, ordem,
  parentesco, estados e comportamento em reconexão/histórico. Só então criar um
  modelo Dart e um painel responsivo de leitura com **Tarefas X/Y**. A primeira
  versão não cria, edita, reordena nem conclui itens: qualquer mutação exige RPC
  e autorização confirmados pelo contrato. Pode dividir a bandeja acima do
  composer com B9.

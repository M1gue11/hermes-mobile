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

## Produto e interface

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

- [ ] **A80 Integrar comandos rápidos com paridade ao Telegram.** Inventariar
  os comandos realmente disponíveis no Telegram e no runtime TUI, mapear
  diferenças de permissão/efeito e implementar descoberta, sugestões ao digitar
  `/`, descrição e execução dos comandos compatíveis no Mobile. Não emular
  comando administrativo como prompt comum nem liberar `slash.exec`,
  `command.dispatch` ou outro RPC sem contrato e autorização específicos.
  Critério de aceite: comandos suportados funcionam com confirmação para ações
  sensíveis e feedback de sucesso/erro; indisponíveis são explicados, não
  exibidos como funcionais. Cobrir argumentos, cancelamento e histórico.

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

- [ ] **A72 Aplicar a persona configurada de ponta a ponta.** A configuração de
  nome/gênero foi validada, mas ainda existem fallbacks visíveis como `Hermes`
  e `Hermes Agent`. Inventariar toda cópia apresentada ao usuário — cabeçalhos,
  estados vazios, mensagens, acessibilidade, notificações, erros, diálogos e
  metadados — e distinguir identidade configurável de nomes técnicos que
  precisam permanecer estáveis. Critério de aceite: com uma persona diferente,
  nenhum texto de produto chama o agente de Hermes; ocorrências técnicas
  inevitáveis ficam justificadas em teste ou documentação.

- [~] **A65 Criar gestão completa de Skills.** Substituir a ação `tune` por uma
  tela inteira e realocar o atual `Contexto` para Ajustes ou uma ação secundária
  nomeada. Escopo mínimo: listar, buscar/filtrar, ler `SKILL.md`, editar com
  proteção contra perda e ativar/desativar no perfil atual.

  A primeira fase somente leitura já está aceita. O próximo recorte exige
  contrato autenticado real para corpo integral, edição protegida, exclusão com
  confirmação, ativação/desativação persistida e estado inequívoco no catálogo e
  no detalhe. Enquanto a API Server oferecer somente metadados em `/v1/skills`,
  não fingir edição, toggle ou marketplace.

- [!] **A42 Ícone e splash.** Aguarda arte ou direção visual aprovada pelos
  mantenedores. Não gerar nem substituir a identidade sem esse insumo.

## Notificações

- [ ] **A60 Notificações do Hermes e canal arbitrário do agente.** Entregar em
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

## Gateway TUI e runtime

- [ ] **B0 Validar o live chat contra o runtime publicado.** O cliente TUI e o
  fluxo real já foram validados no aparelho; falta fechar a auditoria de contrato
  do runtime publicado: login, ticket, close codes, `session.list`,
  `session.history` e delta de métodos/eventos. O checkout local serve somente
  para leitura e não deve ser alterado.

- [ ] **B10 Tratar eventos novos do `0.20.1`.** Decidir a semântica de
  `sessions.changed`, `session.usage` e especialmente `tool.output_risk`, que
  hoje é descartado apesar de carregar um sinal de segurança. Avaliar também
  os campos adicionais de `session.info`. Nenhum dado sem semântica e tratamento
  seguro confirmados vira texto do assistant ou configuração editável.

- [ ] **B12 Projetar `message.interim` e `tool.output_risk` com segurança.**
  `message.interim` precisa de bloco próprio e deduplicação por
  `already_streamed`, inclusive ao reabrir histórico; `tool.output_risk` precisa
  de uma affordance redigida que preserve o alerta sem expor findings sensíveis
  nem transformá-los em Markdown do assistant. Implementar somente depois de
  fixar o modelo, a política de redaction e testes de streaming/reabertura.

- [ ] **B13 Reconciliar eventos TUI após reconexão.** Capturar `seq` e
  `session_id` dos frames e `replay_epoch` de `gateway.ready`. Ao recuperar
  uma conversa, consultar `session.events.since` com o último watermark
  confirmado, mesclar sem duplicar timeline e restaurar `open_requests`.
  Quando `truncated=true` ou o epoch mudar, invalidar o cursor e reconstruir
  pelo snapshot/histórico sem substituir um turno ativo mais completo. Testar
  queda entre `tool.start`/`tool.complete`, aprovação pendente, restart do
  backend e ordem de eventos. O suporte a `open_requests` no `session.resume`
  não substitui o replay dos demais eventos.

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
  completo. No REST atual, `GET /api/sessions` oculta subagents por padrão e
  não aceita `include_children`; o parâmetro enviado pelo Mobile é ignorado.
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

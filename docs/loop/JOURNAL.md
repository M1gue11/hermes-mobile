# Checkpoint corrente do loop

Este arquivo não é um log append-only. Ele guarda somente o contexto necessário
para retomar a iteração atual. Os contratos duráveis estão na documentação
versionada; o Git registra as mudanças do repositório.

## 2026-09-12 - saneamento do loop

- O backlog agora contém somente trabalho aberto, em validação ou bloqueado.
- `USER_TESTING.md` contém somente os aceites manuais ainda pendentes: A75, A73
  e A74.
- Não houve mudança de comportamento do aplicativo nesta limpeza.

## 2026-09-12 - simplificação de A73 e A74

- A thread passou para ordem cronológica normal; a leitura pausada não recebe
  mais compensações geométricas por `jumpTo`.
- O fim acompanha métricas já calculadas somente enquanto a intenção permanece
  ativa. Envio, retorno explícito e troca de conversa reatam o acompanhamento.
- Tools, raciocínio e `Mostrar mais ferramentas` pausam antes de divulgar e usam
  apenas animação vertical de altura; redução de movimento troca o estado sem
  criar um render animado.
- Testes automatizados e análise estão verdes; o aceite Android de A73/A74 segue
  pendente em `USER_TESTING.md`.

## 2026-11-02 - recursos do runtime 0.22.5 (A96 a A102)

- Entraram imagens `MEDIA:` (A96), Servidor com saúde, logs e reinício (A97),
  Uso por período (A98, parte HTTP), busca no servidor (A99, parte HTTP),
  Ferramentas (A100), Acessos (A101) e ouvir a resposta (A102), todos pelo
  Dashboard HTTP; nenhum método TUI novo.
- Dependência nova: `audioplayers` (A102), biblioteca consolidada, para tocar
  os bytes de `/api/audio/speak` sem arquivo temporário.
- Validado no emulador contra o 0.22.5 com dados reais. Não foram disparadas
  ações que mudam o servidor do usuário: reiniciar gateway, alternar toolset
  ou MCP e aprovar pareamento ficaram para `USER_TESTING.md`.

## 2026-11-02 - operação a partir da conversa (A103)

- Título abre detalhes da sessão; Recursos reúne Skills, Ferramentas/MCP e
  instruções; o menu Hermes abre Acessos, Uso geral, Agendamentos, Servidor e
  Ajustes. Os destinos anteriores em Ajustes permanecem disponíveis.
- Navegação por tela inteira fecha o seletor e retorna diretamente à conversa.
  Regressões cobrem rascunho, leitura, instruções, conexões e texto ampliado.
- Ferramentas explicam que a mudança é do perfil e vale para novas conversas;
  a verificação inicial da API distingue carregamento, falha e indisponibilidade.
- Metadados longos e ações de copiar/ouvir acomodam texto ampliado; as ações
  recebem alvo mínimo de 48 dp. Nenhuma API, dependência ou método TUI novo.
- Brief: [A103_INTERFACE_BRIEF.md](A103_INTERFACE_BRIEF.md). Aceite em aparelho
  permanece em [USER_TESTING.md](USER_TESTING.md).

## 2026-11-02 — comandos na conversa (A80)

- Integração autorizada pelo usuário e conferida no repositório local do Hermes
  Agent, incluindo a tag alvo v0.22.5 (`56b6a31fed`). Foram consumidos somente
  `commands.catalog`, `complete.slash`, `slash.exec` e `command.dispatch`.
- Catálogo em Recursos e autocomplete do servidor no compositor; resultados,
  confirmações de alterações, aliases, prefill, Skills e histórico local por
  conversa. Payload do modelo e invocação visível permanecem separados.
- O listener de comandos é substituído sem esperar a própria limpeza assíncrona;
  trocar de conversa ou sair da rota fecha a conexão sem bloquear a hidratação.
- Smoke real: sugestões e relatório de `/status` no 0.22.5. Alterações do perfil
  não foram disparadas no servidor do usuário. Nenhuma dependência nova.
- Validação: 825 testes aprovados, análise estática limpa e APK debug instalado
  no emulador. Confirmação de `/undo` inspecionada e cancelada sem executar.
- Revisão Impeccable: `ship`, sem pendências materiais. Corrigido o fallback
  de resultado pendente sem texto; regressão confirma estado em andamento na
  folha e no histórico recente, sem anunciar conclusão.
- Contrato e inventário de 104 comandos em `docs/dashboard-api/mobile-commands-0.22.5.md`
  e `mobile-command-inventory-0.22.5.md`; brief em `A80_COMMANDS_BRIEF.md`.

## 2026-11-08: notificações com o app fechado (A60)

- Decisões do usuário: UnifiedPush com o app ntfy como distribuidor, ntfy
  self-hosted, payload mínimo (tipo e título). Pediu antes uma busca por plugin
  pronto: nenhum serviu, e o nosso segue o molde do signal-notify (MIT).
- `server/mobile-push`: hooks `on_session_end` e `on_human_input_*`, WebPush
  `aes128gcm` cifrado com a chave do aparelho, registro de aparelhos atrás do
  login do Dashboard. 21 testes Python, inclusive o vetor da RFC 8291.
- App: Ajustes › Notificações, `PushController`, isolate headless
  `--unifiedpush-bg`, toque abre a conversa, sem aviso da conversa visível.
  Dependências: `unifiedpush_android` + interface (sem o guarda-chuva, que
  traria BoringSSL e window_manager) e `flutter_local_notifications` 22.
  Gradle: desugaring e exclusão do `tink` JVM, que colidia com o
  `tink-android` do secure storage.
- Corrigidos pelo caminho: `syncedEndpoint` não era zerado depois de um 410
  (o novo registro não voltava ao servidor), e a presença era atualizada
  dentro de uma notificação do GoRouter durante o build.
- Validação: 863 testes Flutter, análise limpa, APK debug no emulador (Android 17)
  contra o Dashboard real: permissão, estado sem distribuidor e "plugin não
  encontrado". Nenhuma ação mudou o servidor do usuário.
- A104 entrou no backlog a pedido do usuário: baixar arquivos citados na
  conversa.
- A88 concluído: o SSE da Runs API e a saída do terminal SSH decodificam UTF-8
  por stream, não por pedaço. Antes, um caractere partido entre dois pacotes
  virava `�` (reproduzido em teste antes da correção).
- A86 concluído: `file.attach` não manda mais `path`. Conferido no
  `tui_gateway/prompt_attachments.py` do 0.22.6: um `path` que existe no host
  ganha dos bytes do `data_url`, então o nome sozinho (fallback sem
  `localPath`) podia anexar um homônimo do servidor no lugar do arquivo do
  telefone.
- A89 implementado: gravação descartada em segundo plano, com outra rota por
  cima ou com o composer descartado (antes o microfone seguia ligado sem dono).
  868 testes. Falta conferir o indicador de microfone no aparelho.
- A81 concluído: chave da API e senha do Dashboard salvas só são reaproveitadas
  com o campo vazio se esquema, host e porta continuam os mesmos; host novo
  pede a credencial nova, e a dica do campo muda enquanto a URL é digitada.
  O teste antigo, que esperava reaproveitar a chave num host novo, foi
  reescrito para o comportamento novo. 871 testes.
- A87 concluído: até 10 anexos e 50 MB somados por mensagem (dois arquivos no
  teto individual de 25 MB). A contagem é checada antes de abrir seletor ou
  microfone; o total, com os bytes em mão, descartando o que não coube. O
  gateway 0.22.6 aceita 256 MB por anexo, então o teto é do celular. Números
  escolhidos pelo loop; ajustar se o uso real pedir. 874 testes.
- A84 concluído: o anexo guarda a sessão em que o `ref_text` foi confirmado e
  a transcrição da voz. Um retry só sobe o que falhou; trocar de conversa
  sobe de novo, porque o `@file:` é relativo ao workspace da sessão. Os
  gerados reescritos pelo build_runner com espaço no fim de linha foram
  restaurados; só `composer_attachment.freezed.dart` muda. 875 testes.
- A85 concluído: com arquivo anexado, `send(requiresGateway: true)` não cai
  para a Runs; o turno falha com a causa e o composer mantém texto e anexos.
  Com instruções do próximo turno ativas (que sempre forçam a Runs), a
  mensagem explica o conflito. O teste de widget de anexo dependia do defeito
  (o fake recusava o turno ao vivo e o `@file:` ia para a Runs); agora ele abre
  um turno e confere que o `@file:` chega ao gateway. 877 testes.
- A91 implementado: a primeira chave SSH espera um "confio" explícito (o
  `onVerifyHostKey` do dartssh2 aceita `Future`, então o handshake fica parado
  na pergunta). Teste de widget cobre a tela e as decisões; o handshake real
  depende de servidor SSH e foi para `USER_TESTING.md`. 878 testes.
- A82 e A83 já estavam resolvidos no código (pendentes completam ao fechar;
  `prompt.submit` sem resposta vira `GatewaySubmissionUncertain` e reconcilia
  sem reenviar; a retomada limpa aprovação e clarify locais e reentrega os
  `open_requests`). Faltavam as regressões das pontas que o backlog cita:
  socket que cai logo depois do `prompt.submit`, e aprovação resolvida fora
  sumindo na retomada enquanto uma ainda aberta volta. Itens fechados.
- A92 documentado em `docs/seguranca-transporte-tailnet.md`: a exceção é por
  nome (inclui Funnel e tailnets alheias), o WireGuard não autentica o serviço
  e o trecho dentro do host é em claro. Clientes HTTP sem redirect (o
  Dashboard nunca redireciona em `/api/`, conferido no 0.22.6). Remover a
  exceção depende de o usuário servir o Dashboard em HTTPS.
- A78 implementado no mínimo que não muda o desenho: microfone visível com
  anexo, escondido só com texto. O controller já compunha arquivo + voz +
  legenda. Gravar com texto digitado fica como decisão de design.
- A77 implementado: `_resumeVisibleConversation` saía cedo sem turno ativo, e
  uma conversa continuada em outro lugar só aparecia ao reabri-la. Agora relê
  o histórico com guardas (ver backlog). Voltar de Skills/Ferramentas também
  relê: um GET por volta. 886 testes.
- Triagem do que sobrou: A79 pede reproduzir o bug do Parar no aparelho (sem
  descrição do sintoma); A76 pede mensagens reais de exemplo; A98/B10 esperam
  liberar `session.usage` na allowlist; B11/B14 pedem medir eventos disparando
  turnos no servidor do usuário; A90, A92 e A93 esperam decisão. A100/A101
  estavam como abertos, mas já implementados: passaram a `[~]`. B9 é viável:
  no 0.22.6 todo `subagent.*` traz `goal`, `task_count` e `task_index`
  (`tui_gateway/contracts/events.py`), com `subagent_id` opcional.
- B9 implementado: `TurnActivity.subagent` + `SubagentRun`, `RunEvent.subagent`
  no adapter TUI, agregação no controller e linha na timeline cronológica.
  `settleTurnTools` também fecha subagents abertos, então nenhuma chamada
  nova precisou ser espalhada. 894 testes.

## Estado acionável

Atualizado em 2026-11-08 com as respostas do usuário; o detalhe de cada item
está em `BACKLOG.md`.

- Próximo item: A104 (baixar arquivos citados na conversa).
- Pacote da barra de mensagem (pedido em 2026-11-08), a trabalhar junto e a
  partir de um desenho aprovado: A105 (design, animações, alinhamento e
  responsividade), A78, A106 (enfileirar, steer, parar e enviar), A79 e o
  indicador de A98.
- Decididos e prontos para implementar: B9 (refino no molde do Hermes
  Desktop), A78 (seleção múltipla e voz com texto digitado), A92 (qualquer
  URL com avisos de segurança), A98/B10 (`session.usage` e
  `session.context_breakdown` autorizados; a allowlist era só do app) e A79
  (mostrar o erro do Parar no aviso do composer).
- A90 fechado: imagens remotas no Markdown continuam carregando sozinhas.
- A78 (arquivo, voz e legenda no mesmo turno) aceito no aparelho; B9 testado
  e devolvido para refino.
- Aceites em aparelho pendentes: A60, A77, A89, A91.
- A60: instalar `server/mobile-push` no servidor (decisão do usuário).
- Esperam o usuário: A93 (application ID e assinatura release), A76
  (mensagens reais com Markdown errado), B11/B14 (medir eventos disparando
  turnos no servidor), subir o AGP para 9.1 (destrava
  `flutter_local_notifications` 23 e `compileSdk` 37).
- Os métodos diretos `session.undo` e `session.compress` seguem fora da
  allowlist; desfazer e compactar usam os comandos confirmados de A80.

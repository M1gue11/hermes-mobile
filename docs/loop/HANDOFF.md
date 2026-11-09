# Passagem de bastão atual

Hermes Mobile é um app Flutter cliente do agente Hermes. Leia
[README.md](../../README.md), [BACKLOG.md](BACKLOG.md) e somente então o código
afetado.

## Checkpoint

- Loop de 2026-11-09 (sem push): A104 download e salvamento nativo de arquivos,
  A78 seleção múltipla, A79 aviso de falha do Parar e A92 HTTP/HTTPS com avisos.
  Nenhuma dependência ou método TUI novo. Aceites e limites em BACKLOG e
  USER_TESTING. A104 recebeu revisão visual `ship`; screenshots de emulador em
  `build/loop-review/`. A resolução de teste foi restaurada a 1344×2992,
  densidade 480 e fonte 100%. O runtime pareado já anuncia **0.23.0**;
  esse smoke só verificou leitura de status/histórico e recusas de download,
  não uma auditoria de paridade de todos os contratos.
  Validação final: **934 testes**, `flutter analyze` limpo, `git diff --check`
  limpo e APK debug normal compilado/instalado. HTTP por IP confirmado no
  Android contra servidor local via adb; revisão visual A104/A92 `ship`.

- Loop de 2026-11-08 (commits locais em `dev`, sem push): A60 push com o app
  fechado (plugin `server/mobile-push` + UnifiedPush), A81, A84, A85, A86,
  A87, A88, A89, A91, A92 (parcial), A77, A78, B9, e regressões de A82/A83.
  894 testes, análise limpa, APK debug no emulador sem erro na abertura a
  frio e na volta do segundo plano. O que ficou para o usuário (decisões,
  aceites em aparelho, plugin no servidor) está no fim de `JOURNAL.md`.

- Atualização de streaming de 2026-10-11: análise limpa, 690 testes passaram,
  APK debug compilado e instalado. Rotina remota validada com 10 tools, replay
  de 13 eventos após background, um único submit e reabertura com resposta e
  saída da última tool preservadas. A auditoria 0.21.6 registra também a
  correção de perda de output/risco no snapshot compacto.

- O baseline registrado no último pacote foi `flutter analyze` limpo, suíte de
  testes verde e APK debug compilado.
- O pacote de Ajustes, a lista de conversas, a abertura inicial, a timeline
  operacional, o Markdown, os primitivos compartilhados e o catálogo de Skills
  somente leitura foram validados em aparelho; revalidar ao mudar o runtime.
- Aceitos no aparelho até 2026-11-08: A65, A72 a A75, A78 (primeira parte),
  A80, A95 a A103 e B12/B13; o registro está no vault pessoal ("Histórico e
  decisões do loop"). As validações ainda abertas (A60, A77, A89, A91) vivem
  em [USER_TESTING.md](USER_TESTING.md). A94 segue aberto (aceite e relato
  do `500` de `/v1/skills`).
- Decisões do usuário em 2026-11-08, já no backlog: A104 é o próximo item;
  B9 volta para refino no molde do Hermes Desktop (cartão na conversa e
  bandeja acima do composer); A78 ganha seleção múltipla e voz com texto;
  A92 libera qualquer URL com avisos de segurança; A98/B10 autorizados (a
  allowlist era só do app); A79 se reduz a mostrar o erro do Parar; A90
  fechado mantendo imagens remotas carregando sozinhas.
- A60 foi decidido e implementado em 2026-11-08 (UnifiedPush + ntfy
  self-hosted + plugin `server/mobile-push`); falta instalar o plugin no
  servidor e o aceite no aparelho.

## Fatos que evitam regressões

- `design/Hermes.dc.html` é referência visual, não código para copiar.
- `DesignScale` adapta o canvas de 390 px; não reescalar fontes manualmente.
- Usar `serifIn`/`monoIn` para peso real; `copyWith(fontWeight:)` pode escolher
  uma face inexistente.
- A thread respeita quem está relendo. Conversas curtas começam no topo; threads
  longas usam lista cronológica lazy e abrem sincronizadas com o fim.
- O acompanhamento do fim só permanece ativo quando a intenção da pessoa está
  ativa. Divulgação da timeline e rolagem manual pausam sem corrigir o offset;
  mudanças de altura só sincronizam o fim durante o acompanhamento.
- Reconnect nunca reenvia prompt ou resposta interativa.
- Retomada usa sessão, epoch e sequência quando o servidor oferece replay;
  deltas já entregues não são aplicados novamente. Snapshot fallback e
  transformação terminal têm semânticas próprias: comprimento não é identidade.
- Runtime alvo atual: Hermes 0.22.5. O delta para o cliente está em
  [../hermes-api/contrato-0.22.5-medido.md](../hermes-api/contrato-0.22.5-medido.md).
  Skills não fazem parte do boot; um recurso opcional que falha não pode
  derrubar o seletor de modelos. No boot, `AsyncError` é o do `dart:async`,
  não o homônimo do Riverpod.
- Skills: o catálogo vem do Dashboard quando há sessão (gerenciável) e do API
  Server sem ela (somente leitura). Não oferecer edição ou chave sem o
  Dashboard, e não gravar `SKILL.md` sem reler o servidor antes.
- Histórico concluído do Dashboard usa `GET /api/sessions/{id}/messages` com o
  id durável; não abra sessão live apenas para hidratar a tela.
  `session.history` do TUI só aceita o id vivo (4001 para o durável).
- O transcript pode conter user e segmentos intermediários em curso; `inflight`
  continua separado e pode reter erro com `running=false`. Não adotar a resposta
  do turno anterior como parcial do atual.
- `reasoning.delta`, `thinking.delta` e `reasoning.available` têm semânticas
  diferentes. O contrato medido está em
  [../dashboard-api/tui-eventos-0.20.1-medido.md](../dashboard-api/tui-eventos-0.20.1-medido.md).
- O delta atual, os ajustes de streaming e a validação ainda pendente estão em
  [../dashboard-api/mobile-streaming-audit-0.21.6.md](../dashboard-api/mobile-streaming-audit-0.21.6.md).
- `tool.complete` do TUI carrega `result`, `args` e `tool_id`; a Runs API continua
  sendo um fallback mais pobre por contrato.
- Segredos nunca entram em terminal, log, screenshot, teste ou documentação.
- Na edição de conexões, segredo vazio significa preservar o valor atual, só
  enquanto esquema, host e porta não mudam (A81): host novo exige chave ou
  senha nova, para a credencial salva nunca ir a outra máquina. Falha
  após mutação exige rollback das duas conexões; somente “Esquecer conexões” pode
  limpar deliberadamente o pareamento.
- Copy de persona vem de `AgentPersona`; referências técnicas e de produto não
  devem ser renomeadas com a persona.
- Respeitar a política de Host e origem da instalação Dashboard configurada;
  não contornar validações para conectar.
- A92: app aceita HTTP/HTTPS em qualquer host/IP, com aviso no formulário,
  em Ajustes e no diagnóstico. O hostname não prova VPN. Certificados continuam
  validados; HTTP e handshake WS não seguem redirects. A API aceita prefixo de
  caminho; Dashboard continua exigindo somente origem, sem userinfo/query.
- A104 usa cookie em header em `/api/files/download`, não abre URL autenticada
  em outro app nem contorna as pastas permitidas do servidor. Bytes passam por
  arquivo temporário privado e são exportados pelo seletor do sistema. Flutter
  usa `code_cache` em Android recente: a validação nativa admite esse diretório
  e `cache`, exclusivamente para subpastas `hermes-download-*`.
- `/chat` é filha de `/`, a navegação usa `go`, e o roteador é criado uma vez em
  `HermesApp`.
- Não alterar o runtime Hermes como parte de uma mudança do cliente móvel.
  Código que roda no servidor vive como plugin em `server/` e é instalado pelo
  usuário; `server/mobile-push` tem testes próprios (`uv run --with
  cryptography --with fastapi --with httpx python -m unittest`).
- Push: o `main` recebe `--unifiedpush-bg` quando o distribuidor acorda o app
  fechado; esse caminho não monta UI nem `ProviderScope`. Fora da tela o
  `ChatController` solta os listeners do turno, então aviso de fim de turno
  em segundo plano só vem do servidor.
- Android: o conector UnifiedPush traz `tink` e o `flutter_secure_storage`
  traz `tink-android`; o Gradle exclui o primeiro. Subir para
  `flutter_local_notifications` 23 exige AGP 9.1 e `compileSdk` 37.

## Limites

Não ler ou imprimir credenciais. Não adicionar dependência, serviço externo,
método TUI ou desvio relevante de design sem decisão do usuário.

Contratos e evidências técnicas ficam em `docs/dashboard-api/`; roteiros
pendentes de aparelho ficam em [USER_TESTING.md](USER_TESTING.md).

---
version: 1
slug: "lib-features-chat-widgets-gateway-commands-dart"
primary_target: "lib/features/chat/widgets/gateway_commands.dart"
related_targets: ["lib/features/chat/gateway_commands_provider.dart","lib/domain/models/gateway_command.dart","test/features/gateway_commands_test.dart"]
---

# A80 — comandos na conversa

- **Modo e escopo:** extensão local de operação (`Operate`), Android-first,
  preservando DESIGN.md e a composição aprovada em A103.
- **Tarefa:** descobrir comandos do Hermes, preparar argumentos e executar uma
  ação sem voltar à lista nem tratar um comando administrativo como pergunta.
- **Entradas:** digitar `/` abre sugestões do servidor acima do compositor;
  Recursos > Comandos abre catálogo pesquisável, descrições e resultados recentes
  daquela conversa. Selecionar insere texto para revisão, sem executar.
- **Interação:** execução explícita pelo botão Enviar/Executar. Leituras simples
  não interrompem; alterações e comandos personalizados pedem confirmação com
  invocação e alcance. Cancelar ou falhar preserva o texto. Paths como `/usr/bin`
  permanecem mensagens normais; argumentos multilinha e Unicode são preservados.
- **Resultados:** texto abre folha selecionável com cópia; `prefill` prepara
  texto sem enviar; `send`/`skill` iniciam um único turno, mostrando a invocação
  humana e mantendo o payload do modelo fora da apresentação e da busca.
  Aliases têm limite e detecção de ciclo. Respostas pendentes não viram sucesso.
- **Continuidade:** catálogo, autocomplete e execução usam a sessão viva correta.
  O transporte preparado é reaproveitado no próximo turno; consultas durante
  streaming não roubam a conexão nem acionam Parar. Troca de conversa não envia
  diretivas à nova sessão. Histórico/modelo/título são relidos após alterações.
- **Limites:** não reproduzir o catálogo estático no app. Comandos de terminal
  aparecem com explicação e sem execução. Recusas do servidor são apresentadas;
  timeout ou perda de resposta não dispara retry/fallback de uma mutação.
  Resultados recentes ficam em memória nesta abertura do aplicativo, por conversa.
- **Contrato:** `commands.catalog`, `complete.slash`, `slash.exec` e
  `command.dispatch`, verificados no código da tag v0.22.5 do repositório local
  do usuário. Sem dependência nova nem alteração do Hermes Agent ou do servidor.

## Evidência e revisão — 2026-11-02

- **Integração visual:** a superfície usa os tokens e sheets nativos do
  Caderno de Operações: papel quente escuro, conteúdo em Newsreader, identificação
  técnica em JetBrains Mono e âmbar para ação. Não acrescenta tokens nem regras
  ao sistema global.
- **Revisão:** disposição final `ship`. O único achado material — resposta
  pendente sem saída anunciada como concluída — foi corrigido com
  `_commandOutput` compartilhado. A regressão de widget verifica o texto de ação
  em andamento na folha real e no registro recente, sem conclusão, atualização
  de histórico ou envio de prompt.
- **Verificação:** 825 testes aprovados, `flutter analyze` limpo e APK debug
  compilado e instalado no emulador Android. Smoke real contra o runtime 0.22.5
  confirmou autocomplete e relatório de `/status`; a confirmação de `/undo`
  foi capturada e cancelada. Contrato e limites em
  [mobile-commands-0.22.5.md](/docs/dashboard-api/mobile-commands-0.22.5.md).
- **Evidência visual:** `build/a80-review/` contém `final-suggestions.png`,
  `final-catalog.png`, `confirmation.png`, `status.png`, `large-suggestions.png`
  e `large-catalog.png`. A revisão nativa incluiu escala de fonte 2.0, restaurada
  para 1.0; uma execução do detector retornou `[]`.
- **Aceite manual restante:** uso físico conforme
  [USER_TESTING.md](/docs/loop/USER_TESTING.md), compatibilidade iOS e ações que alteram o
  perfil não foram certificados pelo smoke. A captura de `/undo` comprova a
  confirmação e seu cancelamento, sem provar a mutação em produção.

Esta evidência descreve apenas A80; escolhas locais de composição e resultados
da revisão não são novas regras de DESIGN.md.

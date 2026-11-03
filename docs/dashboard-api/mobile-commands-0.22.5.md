# Comandos no Mobile — contrato v0.22.5

Implementação autorizada pelo usuário em 2026-11-02. Fonte: Hermes Agent,
tag `v0.22.5`, commit
`56b6a31fededdf7364e1a0a79548d144e7fd81a3`. O checkout local estava em
`v0.22.6-42-ga92fb5e7c3`; a integração foi verificada também na tag alvo.
Nenhum arquivo do Hermes Agent ou configuração do servidor foi alterado.

## Métodos consumidos

| Método | Parâmetros usados | Resposta consumida |
|---|---|---|
| `commands.catalog` | `session_id` vivo | `pairs`, `canon`, `categories`, `commands` (`argument_mode`, `desktop`), `skills`, `plugin_commands`, `sub`, `warning` |
| `complete.slash` | `session_id` vivo, `text` até o cursor | `items[].text`, `items[].meta`, `replace_from` |
| `slash.exec` | `session_id` vivo, `command` sem a primeira `/` | `output`/`warning`, ou diretiva com `type` |
| `command.dispatch` | `session_id` vivo, `name`, `arg` preservado | `exec`, `plugin`, `alias`, `send`, `skill`, `prefill` |

Fontes: `tui_gateway/contracts/tools_commands.py`,
`contracts/profiles_vault_complete_foreign_subagents.py`, `methods_tools.py`,
`command_discovery.py` e `apps/shared/src/slash.ts`. A apresentação de Skills
segue `apps/shared/src/skill-scaffold.ts`.

`stored_session_id` nunca substitui o id vivo nesses métodos. A conexão usada
na descoberta permanece sob o ciclo de vida do ChatController; se uma diretiva
iniciar turno, o mesmo socket é adotado pelo envio e pelo streaming.

## Execução e recusas

- O cliente usa `slash.exec` primeiro. Só `-32601` ou uma recusa explícita de
  roteamento conhecida (`4018` com o texto exato medido no código) permite
  `command.dispatch`. Erro de worker, script, timeout ou desconexão não permitem
  uma segunda execução por outro método.
- `output`, `exec` e `plugin` são relatórios. `alias` redireciona com argumentos,
  limite de oito etapas e detecção de ciclo. `prefill` prepara texto e relê o
  histórico — `/undo` já o alterou antes de devolver essa diretiva.
- `send` e `skill` devolvem o payload para um único `prompt.submit`; a UI mostra
  `display` ou a invocação original. O domínio guarda texto e apresentação
  separadamente para preservar histórico de modelo e impedir exposição do corpo.
- `status: pending` continua identificado como execução em andamento no Hermes.
  O orçamento de 11 minutos acompanha o teto de espera de compactação do Desktop.
- Sem argumentos, `/model`, `/sessions`, `/commands`, `/new`/`/reset`/`/clear`
  e `/stop` reaproveitam os controles reais do aplicativo. `/stop` interrompe a
  execução atual, não um worker auxiliar. Alterações pedem confirmação; consulta
  simples não. Quick commands e plugins nunca ganham dispensa por terem nome
  igual ao de um comando de leitura.
- Métodos diretos `session.undo` e `session.compress` permanecem fora da allowlist:
  essas ações são acessadas pelos comandos confirmados do gateway. Uso de contexto
  estruturado (`session.usage`/`context_breakdown`) continua sendo outro recorte.

## Descoberta e diferenças de superfície

O [inventário estático](mobile-command-inventory-0.22.5.md) registra o catálogo
canônico e as diferenças declaradas para plataformas de mensagem. O aplicativo
não copia esse inventário: plugins, Skills e comandos personalizados vêm do perfil
da sessão no servidor. Terminal indisponível recebe explicação; outras recusas
de argumentos/capacidade permanecem sob a autoridade do Hermes.

`replace_from` é um índice Python de caracteres; o Mobile o converte para offsets
UTF-16 antes de inserir uma sugestão. O debounce é cancelado ao descartar a busca.
Argumentos multilinha mantêm o conteúdo interno. Um caminho `/usr/local` e texto
que apenas contém `/` não são interpretados como comando.

## Evidência e aceite

- Suíte completa: 825 testes aprovados; `flutter analyze` sem apontamentos.
  APK debug compilado e instalado no emulador Android.
- Smoke real contra o runtime 0.22.5: autocomplete de `/status` e execução com
  relatório real na folha de resultados, sem envio como pergunta ao agente.
- Testes de contrato: ids vivos, argumentos multilinha, parsing de diretivas,
  fallback somente por recusa de roteamento e ausência de segunda execução em falha.
- Regressões móveis: confirmação/cancelamento, rascunho, prefill/desfazer,
  Skill enviada uma vez, ciclo de aliases, resultado perdido, troca de conversa,
  consultas durante streaming, argumentos Unicode, texto ampliado e falta de Dashboard.
- Resposta pendente sem texto apresenta ação em andamento, tanto na folha de
  resultado quanto no histórico recente, sem anunciar conclusão nem reler histórico.
- Ações que alteram o perfil do usuário não fazem parte do smoke automático.
  Aceite físico permanece em `docs/loop/USER_TESTING.md`.

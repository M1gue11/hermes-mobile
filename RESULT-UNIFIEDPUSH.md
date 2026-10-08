# Resultado — P2 e investigação UnifiedPush (2026-10-07)

Worktree exclusivo `/home/miguel/.hermes/workspace/hermes-mobile-unifiedpush-20261007`.
Branch `feat/unifiedpush-client-20261007`; baseline
`caa81d69436474ee1a1592adbe33635c925f2805`. Entrega parcial autorizada pelo
bloqueio de resolução UnifiedPush. Sem prontidão de push/Android/produção.

## Código entregue

- `lib/features/chat/chat_controller.dart:885,1262,1748`: os dois caminhos idle
  projetam apenas a resposta final persistida remota, sem usar a fase da bolha
  mesclada. Histórico vazio ou cauda de tools sem resposta não autoriza terminal.
  Sem alteração do lifecycle da bolha, do envio ou da limpeza do registro ativo.
- `lib/features/notifications/notification_inbox.dart:18,31,339`: proveniência
  explícita na entrada/slot, preservada ao marcar lida. Aviso local provisório
  não ocupa o cache terminal; terminal remoto posterior pode substituí-lo.
- `test/features/notification_controller_test.dart:54,194`: erro neutro real de
  interrupt via fake de teste, hide/resume idle com histórico vazio e projeção
  terminal subsequente (conclusão/cancelamento/falha) no mesmo slot; outro teste
  percorre disconnect/reconcile com resposta persistida remota e sem submit.
  A etapa posterior ao idle exercita diretamente a API de projeção da inbox,
  não promete listener ativo após o chat limpar seu registro. Snapshot terminal
  por controller já tem regressões neste arquivo. Execução Flutter bloqueada.
- `test/support/fake_gateway_repository.dart:109,148`: injeção neutra de erro de stop.
- `prototypes/notifications/cli.py:17,75`: staging exclusivo 0600 no mesmo diretório,
  schema + application_id antes de publicação, close/fsync e renameat2 exclusivo,
  seguido de fsync do diretório. Nenhum replace de destino existente. Guardas de
  scratch/path/symlink/hardlink/uid/0600 e leitura da identidade antes de Store.
  DB com identidade mas schema ausente é rejeitado sem reparo. Requer Linux/libc
  com renameat2; indisponibilidade falha fechada. Staging órfão não é adotado nem
  apagado por outra abertura. Defesa contra troca maliciosa de path entre check
  e abertura SQLite continua fora do contrato, em diretório controlado.
- `prototypes/notifications/test_core.py:232,275`: seis crashes reais os._exit em
  subprocessos, antes de schema/identity e após identity/fsync/publicação/fsync
  de diretório. Próxima abertura reconhece/cria apenas DB completo. Corrida com
  arquivo alheio, vazio preexistente, identity sem schema e hardlink rejeitados;
  bytes alheios preservados. Smoke CLI em processos novos sem transporte.

## Contrato oficial investigado e bloqueio

[pub.dev](https://pub.dev/packages/unifiedpush) apresenta **unifiedpush 6.2.0**,
publisher **unifiedpush.org**. O README contém exemplos antigos registerApp;
a [referência com implementação](https://pub.dev/documentation/unifiedpush/latest/unifiedpush/UnifiedPush/register.html)
identifica 6.2.0 e confirma `Future<void> register({String instance, List<String>?
features, String? messageForDistributor, String? vapid})` com parâmetros nomeados.
[initialize e implementação](https://pub.dev/documentation/unifiedpush/latest/unifiedpush/UnifiedPush/initialize.html)
recebe callbacks endpoint/registrationFailed/unregistered/message/tempUnavailable,
retorna Future<bool> indicando distribuidor registrado e não faz enrollment.
[PushMessage](https://pub.dev/documentation/unifiedpush/latest/unifiedpush/PushMessage-class.html)
contém Uint8List content e bool decrypted; somente true autoriza tratar plaintext.
[PushEndpoint](https://pub.dev/documentation/unifiedpush/latest/unifiedpush/PushEndpoint-class.html)
contém url, pubKeySet e temporary. Nenhum desses valores foi criado/coletado/logado.
O README documenta `main(List<String> args)` e `--unifiedpush-bg` sem runApp.

Tentativa real com `unifiedpush: 6.2.0` fixo falhou (exit 69, socket para pub.dev).
Nenhuma versão foi resolvida, baixada ou compilada; a fonte consultada foi a
implementação exibida na referência oficial, não um pacote local resolvido.
Dependência provisória removida: pubspec/lock idênticos ao baseline; SDK ^3.12.2
preservado. Dart executado: **3.12.2, linux_arm64**. **Dependências novas: nenhuma**; unifiedpush/flutter_local_notifications
não integram esta entrega. Sem stub, serviço Android, UI opt-in, parser, callback
ou headless fictício. main e Android não foram alterados.

Java não encontrado no PATH pela consulta `command -v java`. Build Android não
executada; tests/analyze não são evidência de APK. Enrollment autenticado,
backend, revogação/ACL e ntfy continuam pendentes. Registro no distribuidor não
é cadastro server-side. Texto exigido para futura UI: “Backend pendente —
enrollment autenticado ainda não existe”. Não houve envio ou alteração de servidor.

## Validação Codex e logs

SDK/cache: `/home/miguel/.hermes/cache/scratch/flutter-notifications-sdk/bin/flutter`
e PUB_CACHE `/home/miguel/.hermes/cache/scratch/notifications-pub-cache`.
Todos os logs abaixo ficam em `/home/miguel/.hermes/cache/scratch/`.

| Comando | Resultado | Log |
| --- | --- | --- |
| flutter pub get original | exit 69, DNS pub.dev | unifiedpush-pub-get.log |
| flutter pub get com unifiedpush 6.2.0 | exit 69, resolução bloqueada | unifiedpush-resolution.log |
| flutter pub get --offline original | exit 0, lock preservado | unifiedpush-offline-pub-get.log |
| flutter analyze --no-pub | exit 0, No issues found | unifiedpush-analyze.log |
| flutter test --no-pub foco controller/inbox | Codex: bloqueado no loading; PO: exit 0, **48 testes** | unifiedpush-po-focused-final.log |
| flutter test --no-pub --reporter compact completo | PO: exit 0, **727 testes**; All tests passed | unifiedpush-po-full-final.log |
| flutter analyze --no-pub | PO: exit 0, No issues found | saída canônica; Codex: unifiedpush-analyze.log |
| flutter pub get --offline | exit 0, dependências preservadas | saída canônica |
| python -m unittest discover -s prototypes/notifications -p test_*.py -v | PO: exit 0, **16 testes** | unifiedpush-po-python-tests.log |
| python -m py_compile core.py cli.py test_core.py | exit 0 | unifiedpush-pycompile.log |
| smoke CLI status/restart/0600 | exit 0 | unifiedpush-smoke.log |
| git diff --check | exit 0 | verificação direta |

A primeira análise --no-pub sem package_config (pub get remoto falhou) produziu
URIs não resolvidos; não foi usada como resultado de código. Recuperação offline
permitiu a análise real. Codegen não necessário. Sem bypass do sandbox.
Roteiro futuro de aparelho (foreground/background/lock/swipe/offline/force-stop/
segundo distribuidor) em docs/loop/USER_TESTING.md; arquitetura e HANDOFF atualizados.

## Git / commit local

O Codex tentou `git add` antes da aceitação e recebeu **exit 128** porque os
metadados compartilhados do worktree estavam read-only:
`/home/miguel/.hermes/cache/scratch/hermes-mobile-second-review/.git/worktrees/hermes-mobile-unifiedpush-20261007/index.lock`.
A PO não moveu metadados, não alterou mounts e não usou bypass; depois da revisão e
validação canônica, o commit local foi criado com identidade `git -c`, sem alterar
configuração global. O status atual e o SHA foram verificados no fechamento com
`git status --short --branch` e `git rev-parse HEAD`. Sem push/PR/merge/deploy.

## Rodada corretiva 1 — finding P2 do review

- `lib/features/chat/chat_controller.dart:1748`: `toolCalls: []` agora permite
  projetar o terminal da resposta assistant persistida remota. Lista não vazia
  e shape não-lista não nulo continuam rejeitados; guardas de histórico vazio,
  papel assistant e conteúdo não vazio preservadas.
- `test/features/notification_controller_test.dart:121`: seis regressões para
  hide/resume e disconnect/reconcile, com lista vazia, lista não vazia e mapa.
  Lista vazia exige aviso de conclusão com proveniência remoteTerminal; os
  demais shapes não autorizam aviso. Verificam um único submit original e nenhum
  submit no turno retomado. Testes anteriores de vazio/local provisional mantidos.
- Apenas controller, arquivo de testes e este relatório alterados nesta rodada.
  Sem alteração de Gateway, SQLite, Android/UP, infraestrutura, credenciais ou SDK.

Comandos usando o SDK e PUB_CACHE já indicados acima, sem bypass:

| Comando | Resultado | Log em scratch |
| --- | --- | --- |
| dart format lib/features/chat/chat_controller.dart test/features/notification_controller_test.dart | exit 0 | unifiedpush-corrective-1-format.log |
| flutter analyze --no-pub | exit 0, No issues found | unifiedpush-corrective-1-analyze.log |
| flutter test --no-pub test/features/notification_controller_test.dart test/features/notification_inbox_test.dart | exit 1, 0 testes executados; dois erros de loading por bind 127.0.0.1 proibido (errno 1) | unifiedpush-corrective-1-focused-tests.log |
| git diff --check | exit 0 | unifiedpush-corrective-1-diff-check.log |

Regressões executadas pela PO após a rodada corretiva: foco **48 passes** e suíte
completa **727 passes**, ambos exit 0. `flutter analyze --no-pub` e `flutter pub get
--offline` também passaram. O build APK foi tentado e bloqueado exatamente por
`[!] No Android SDK found` (Java/ANDROID_HOME/ANDROID_SDK_ROOT ausentes); testes
Flutter não são evidência de APK. A revisão final Codex read-only válida não
encontrou regressões acionáveis (log `unifiedpush-codex-rereview-final-20261007.log`).

As duas primeiras invocações de review são apenas erros de execução, não findings:
`unifiedpush-codex-review-20261007.log` rejeitou prompt posicional combinado com
`--base`; `unifiedpush-codex-review-valid-20261007.log` rodou fora do worktree e
falhou por diretório não confiável. A invocação válida seguinte usou `workdir` do
worktree e `--base`, exit 0; a re-review final também exit 0. Nenhum `--skip-git-repo-check`
foi usado.

Commit local final criado após revisão/testes com a mensagem
`fix: harden notification resume and db init`; o SHA foi verificado com
`git rev-parse HEAD` no fechamento. Não houve push/PR/merge/deploy.

# UnifiedPush bootstrap — 2026-10-08

Worktree exclusivo: `/home/miguel/.hermes/workspace/hermes-mobile-unifiedpush-20261007`.
Branch `feat/unifiedpush-client-20261007`; baseline
`f4b5eaff166ad70fa8a4ab458b52e251cd909b45`.
Implementação parcial com bloqueios explícitos; não representa entrega Android.

## Composição implementada

- `lib/main.dart:53`, `main(List<String> args)`: dispatch de `--unifiedpush-bg`
  antes de WidgetsFlutterBinding, restauração foreground, settings e runApp.
  O serviço oficial cached `UnifiedPushService.kt:59` chama
  DartEntrypoint.createDefault com esse argumento. Não há target alternativo.
- `lib/features/notifications/unifiedpush_entrypoint.dart:9`,
  `bootstrapPushHeadless`: BindingBase + SchedulerBinding + ServicesBinding,
  somente runtime/store UnifiedPush. Não executa UI, Gate, ProviderScope,
  connection store, chat ou socket. Imports do main são declarações Dart;
  o branch headless não inicializa os objetos foreground.
  SDK oficial `sky_engine/lib/ui/natives.dart:12` proíbe
  DartPluginRegistrant.ensureInitialized no root isolate. O novo engine do serviço
  é root e usa o registrant gerado pelo engine; a chamada explícita fica guardada
  por RootIsolateToken.instance == null para isolate secundário.
- `lib/main.dart:60` e `push_runtime.dart:18`, `startPushForeground`: startup
  Android antes de settings/runApp, usando o mesmo singleton da PushControls.
  Unsupported não chama adapter. Consentimento persistido pode ser restaurado;
  default continua off. Nenhuma API de permissão OS é chamada.
- `lib/features/notifications/push_controller.dart:56`, `start`: fila serializada, early return após startup
  saudável ou supressão. Callbacks só são instalados enquanto initialized=false.
  Falha transitória permite retry de startup, sem reinstalar callbacks bem
  instalados; register falho pode ser repetido por retry explícito. Unregister
  suprime imediatamente mesmo com falha de persistência, e start não reativa.
- `lib/features/notifications/unifiedpush_adapter.dart:48`, `initialize`: preserva callbacks instalados
  mesmo se a consulta posterior ao distribuidor falhar. Existência de distribuidor
  não é tratada como registro concluído nem como enrollment.
- `lib/features/notifications/push_controller.dart:29`, `backendEnrolled`, e
  callback message em `push_controller.dart:128`: enrollment é
  **sempre false** nesta fatia. Nenhuma mensagem pré-enrollment alcança
  PushNoticeReceiver/sink, mesmo decrypted=true. Não foi implementada uma forma
  local de declarar emissor autenticado. Parser fechado/dedupe e texto fixo
  `Hermes / Novo aviso operacional` permanecem na abstração isolada existente.

A injeção MainStartupOverrides é restrita a uma zona de teste; runMainForTest
chama o main real. Testes de composição cobrem dispatch antecipado, execução
normal uma vez, ordem binding/receiver/settings/runApp, fallback das preferências,
forma Splash/Gate e consentimento restaurado com chamadas main+sheet idempotentes.
O seam antigo bootstrapPush, desconectado do main, foi removido e suas regressões
foram transferidas para a composição real. Spy no sink cobre mensagens bloqueadas;
regressões de callbacks, storage, registro/revogação e plataformas foram mantidas.

## Ponte Android oficial — lacuna de implementação resolvida

O PO disponibilizou o pacote oficial **flutter_local_notifications 22.3.1**
(SDK ^3.10, Flutter >=3.38.1) no cache autorizado. O app adiciona o pin exato e
lock atualizado, resolvido por pub get offline exit **0**. O relato anterior de
cache ausente/exit 69 está superado; não foi necessária rede nesta continuação.

AndroidPushNotifier é o sink default real do PushController. O receiver exige
notifier explícito; o default Noop foi removido. Instanciação não inicializa
plugin. O gate backendEnrolled=false/opt-in e main real foram preservados.
Nenhuma mensagem de produção chega ao sink antes do enrollment autenticado.
O caminho real do sink é exercitado independentemente pelos novos testes.

APIs oficiais cached inspecionadas: FlutterLocalNotificationsPlugin.initialize
(settings nomeado), show (id/title/body/notificationDetails nomeados),
AndroidFlutterLocalNotificationsPlugin.createNotificationChannel e
areNotificationsEnabled. initialize, show, channel setup e status Android usam
applicationContext registrado em onAttachedToEngine (Java oficial), sem Activity
nesses caminhos. Não há pedido de permissão, callback de tap/background response,
plugin custom ou channel próprio. O engine root usa registro gerado existente.
Compatibilidade em fonte não equivale a validação do engine em aparelho.

O sink cria canal hermes_operational_v1/high, usa drawable ic_stat_hermes,
visibility private e id local constante 1. Ignora argumentos externos e só
encaminha Hermes / Novo aviso operacional. Payload omitido vira string vazia
no MethodChannel oficial. Não encaminha envelope, event_id ou texto arbitrário.
Unsupported, initialize=false, permission status false/null e exceções
(incluindo MissingPluginException e PlatformException de canal/show) são
absorvidos sem logs. Falhas permitem retry de inicialização. Desugaring
com.android.tools:desugar_jdk_libs:2.1.4 adicionado conforme README oficial;
AGP existente 9.0.1 satisfaz mínimo 8.11.1. Permissão POST_NOTIFICATIONS é
declarada no manifest do pacote; nunca solicitada automaticamente.

Testes novos usam o plugin real e mock de binary messenger/MethodChannel oficial,
sem sockets próprios: initialize/channel/show, valores fixos/payload vazio,
idempotência, permissões, unsupported, init=false, plugin ausente e falhas com
retry em cada chamada. Parser direto segue sem dependência Flutter.

Inventário: Dart ^3.12.2; unifiedpush_android 3.5.0;
unifiedpush_platform_interface 4.0.0; flutter_secure_storage 10.3.1;
flutter_local_notifications **22.3.1**. O wrapper unifiedpush permanece ausente.
Novas transitivas estão no lock e no USER_TESTING.

## Validação da execução anterior (histórico)

A tabela abaixo é do bootstrap anterior, antes do sink oficial; os resultados
desta continuação constam na seção final.

## Validação e logs anteriores

Todos os logs e kernels ficam em `/home/miguel/.hermes/cache/scratch`.
SDK: `flutter-notifications-sdk`; PUB_CACHE: `notifications-pub-cache`.

| Verificação | Exit / contagem | Log |
| --- | --- | --- |
| flutter pub get --offline, app completo | 0 | bootstrap-pub-get.log |
| dart format, arquivos editados | 0 | bootstrap-format*.log |
| flutter analyze --no-pub, fontes finais | 0 | bootstrap-analyze-last.log |
| flutter test --no-pub test/features/notifications | 1; 0 testes executados, 4 arquivos falharam no loading | bootstrap-focused-last.log |
| flutter test --no-pub, suíte completa tentada | 130, interrompida após 77 falhas de loading; 0 testes executados | bootstrap-full.log |
| dart run push_notice_check.dart | 0, display-parser-direct.log; parser/dedupe passou | bootstrap-parser.log |
| dart push_notice_check.dart, execução direta | 0, display-parser-direct.log; parser/dedupe passou | bootstrap-parser-direct.log |
| Kernel do main padrão | 0, frontend 0 erros | bootstrap-main-kernel-last.log |
| Kernel da função headless, wrapper de compilação em scratch | 0, frontend 0 erros | bootstrap-bootstrap-headless-check-kernel-last.log |
| Kernel dos 4 arquivos de testes focados | 0 cada, frontend 0 erros | bootstrap-*-kernel-last.log |
| git diff --check | 0 | bootstrap-diff-check.log |

Os testes Flutter não ficaram verdes: ServerSocket.bind em 127.0.0.1:0 falha
com `Operation not permitted, errno = 1` neste sandbox. As primeiras tentativas
focadas também terminaram com exit 1 pelo mesmo bloqueio. A suíte completa foi
interrompida para evitar repetir a mesma falha em todos os 88 arquivos. Compilar
kernel não equivale a executar as regressões. Uma tentativa inicial de frontend
usou dart para snapshot AOT e retornou 255; corrigida para dartaotruntime.
Uma rodada de compilação em subprocesso foi interrompida com 130; a rodada final
usa stdin fechado e seus resultados são os da tabela.

Java/javac não foram encontrados no PATH, e `/opt/android-sdk` e
`/home/miguel/Android/Sdk` não existem. APK não foi tentado sem toolchain real;
nenhuma instalação ou config global foi feita. Não há validação em telefone,
engine Android, banner, background/swipe/force-stop/offline, ntfy ou Tailscale.
Enrollment, autorização de produtor, ACL/backend e validação OS seguem pendentes.
A supressão em memória após falha de storage não garante opt-out após restart.

Revisão própria do diff: escopo limitado a main/notificações, testes e docs;
nenhum arquivo gerado ou segredo incluído. A81–A93/backlog e os roteiros pendentes
foram preservados. **Commit local bloqueado**, sem push/merge/deploy.

Após as validações, git add dos 11 arquivos autorizados retornou **128**:
Unable to create
`/home/miguel/.hermes/cache/scratch/hermes-mobile-second-review/.git/worktrees/hermes-mobile-unifiedpush-20261007/index.lock`:
Read-only file system. Esse é o diretório administrativo real apontado pelo
worktree; fica fora das raízes graváveis concedidas neste ambiente. Nenhum commit
foi criado, e não se mudou worktree, branch, gitdir ou configuração para contornar
a restrição. As mudanças ficam disponíveis para revisão/commit em ambiente com
escrita autorizada nesse diretório. Este relato não substitui revisão independente
nem aceite em aparelho.

## Continuação — validação da ponte oficial

SDK absoluto: /home/miguel/.hermes/cache/scratch/flutter-notifications-sdk/bin/flutter.
PUB_CACHE: /home/miguel/.hermes/cache/scratch/notifications-pub-cache.
Logs desta rodada em `/home/miguel/.hermes/cache/scratch/display-*.log`; kernels em `/home/miguel/.hermes/cache/scratch/display-*.dill`.

| Verificação | Exit | Evidência |
| --- | --- | --- |
| flutter pub get --offline | 0 | display-pub-get.log; 9 novas dependências |
| dart format | 0 | display-format.log |
| flutter analyze --no-pub | 0 | display-analyze-final.log; No issues found |
| flutter test --no-pub test/features/notifications | 1 no runner; wrapper com tail saiu 0 | display-focused.log; 0 executados, 5 loading failures |
| flutter test --no-pub android_push_notifier_test.dart | 1, capturado diretamente por subprocess | display-boundary-focused.log; localhost errno 1 |
| dart direto push_notice_check.dart | 0 | display-parser-direct.log; parser/dedupe passou |
| Kernel main, headless e 5 testes focados | 0 cada | display-*-kernel.log; frontend 0 erros; controller recompilado após teste adicional |
| git diff --check | 0 | revisão final |

Uma tentativa de --help no frontend do diretório engine não era snapshot AOT
executável (wrapper shell saiu 0 após imprimir a falha). As compilações efetivas
usaram dartaotruntime + dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot,
com stdin fechado. Compilação não substitui execução de teste. A segunda tentativa
focou somente o novo boundary para capturar exit exato, sem repetir suíte completa.

Java/javac e diretórios Android SDK continuam ausentes. APK não tentado. Nenhum
engine Android, banner, aparelho, permissão nativa ou enrollment foi verificado.
Ícone preservado para resource shrinking por res/raw/keep.xml. Gate de enrollment,
main composition, regressões backend/pre-enrollment, A81–A93 e scripts de aparelho
foram preservados. Nenhum backend/Gateway/infra, crypto, push/merge/deploy.
Mudanças permanecem sem commit; restrição de escrita do gitdir já comprovada
no histórico acima e os.access(gitdir, os.W_OK)=false nesta rodada, sem nova
tentativa de escrita ou contorno.

## Corrective pass — platform seam (2026-10-08)

O PO executou a suíte focada real após a rodada anterior e relatou **8 falhas
somente em android_push_notifier_test.dart**: calls vazio porque o gate de
AndroidPushNotifier.display observava a plataforma host apesar do override do
teste. Esse resultado não foi verde e não é substituído pelo histórico de kernels.

Correção limitada ao notifier, seu teste e este registro: constructor recebe
TargetPlatform? platform, marcado @visibleForTesting; sem injeção, display mantém
kIsWeb e defaultTargetPlatform == Android. Todos os casos Android passam Android
explicitamente; o teste unsupported passa cada plataforma não Android. O plugin
oficial, mock existente do messenger, assertions, valores fixos e tratamento de
falhas foram preservados. Nenhuma chamada de plugin foi fabricada para contornar
o gate. Nenhum caller de produção injeta plataforma.

SDK usado: `/home/miguel/.hermes/cache/scratch/flutter-notifications-sdk/bin/flutter`;
dart format via o `bin/dart` desse mesmo SDK. Todos os comandos SDK usaram
`PUB_CACHE=/home/miguel/.hermes/cache/scratch/notifications-pub-cache`.

| Comando | Exit / resultado exato | Log |
| --- | --- | --- |
| dart format lib/features/notifications/android_push_notifier.dart test/features/notifications/android_push_notifier_test.dart | 0; Formatted 2 files (0 changed) | /home/miguel/.hermes/cache/scratch/display-corrective-format.log |
| flutter analyze --no-pub, tentativa inicial | 1; 1 info prefer_initializing_formals | /home/miguel/.hermes/cache/scratch/display-corrective-analyze.log |
| flutter analyze --no-pub, após corrigir constructor | 0; No issues found (2.4s) | /home/miguel/.hermes/cache/scratch/display-corrective-analyze-final.log |
| flutter test --no-pub test/features/notifications/android_push_notifier_test.dart | 1; 0 testes executados, 1 falha de loading; ServerSocket 127.0.0.1:0, Operation not permitted, errno = 1 | /home/miguel/.hermes/cache/scratch/display-corrective-focused.log |
| git diff --check | 0 | /home/miguel/.hermes/cache/scratch/display-corrective-diff-check.log |

A tentativa de teste ocorreu com a injeção já aplicada, antes da correção puramente
estilística do constructor. Não houve retry do socket nem execução da suíte
completa. A suíte opcional do diretório notifications foi omitida após o bloqueio
no runner. Portanto, as 8 regressões relatadas pelo PO ainda precisam de execução
em ambiente que permita o socket do Flutter; não há alegação de testes verdes.
Diff revisado, incluindo conteúdo dos arquivos ainda untracked que git diff não
exibe. Nenhum arquivo alheio ao corrective pass foi editado, nenhum commit criado.
Esta rodada não valida produção, engine/aparelho Android ou APK.


## Corrective pass — official Dart platform registration (2026-10-08)

O PO rerodou o teste real após a injeção de plataforma e relatou 8 falhas:
a implementação Dart oficial não estava registrada no teste Flutter puro;
initialize/show documentados tornam-se no-ops quando a plataforma não é resolvida.
Correção apenas em test/features/notifications/android_push_notifier_test.dart:
import explícito da interface oficial, preservação da instância anterior,
AndroidFlutterLocalNotificationsPlugin.registerWith() no setUp após selecionar
Android, e restauração da instância no tearDown. O mock do MethodChannel oficial
e todas as assertions de valores fixos permanecem intactos. Não há fake plugin
nem alteração de produção. Import Android limitado com show; supressão local de
depend_on_referenced_packages para acessar a interface transitiva oficial sem
alterar pubspec ou lock.

CWD exclusivo: `/home/miguel/.hermes/workspace/hermes-mobile-unifiedpush-20261007`.
SDK absoluto: `/home/miguel/.hermes/cache/scratch/flutter-notifications-sdk/bin/flutter`;
format via `/home/miguel/.hermes/cache/scratch/flutter-notifications-sdk/bin/dart`.
Todos os comandos SDK usaram
`PUB_CACHE=/home/miguel/.hermes/cache/scratch/notifications-pub-cache`.
O alvo de format/test foi o caminho absoluto do arquivo acima.

| Comando | Exit / resultado exato | Log |
| --- | --- | --- |
| dart format android_push_notifier_test.dart | 0; Formatted 1 file (0 changed) in 0.01 seconds | /home/miguel/.hermes/cache/scratch/display-registration-format.log |
| flutter analyze --no-pub, inicial | 1; 2 infos: unnecessary_import e depend_on_referenced_packages | /home/miguel/.hermes/cache/scratch/display-registration-analyze.log |
| flutter analyze --no-pub, imports corrigidos | 0; No issues found! (ran in 2.5s) | /home/miguel/.hermes/cache/scratch/display-registration-analyze-final.log |
| flutter test --no-pub android_push_notifier_test.dart | 1; 0 testes executados, 1 falha de loading; Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0; Some tests failed. | /home/miguel/.hermes/cache/scratch/display-registration-focused.log |
| git diff --check | 0 | /home/miguel/.hermes/cache/scratch/display-registration-diff-check.log |

A única tentativa de teste ocorreu após registro/restauração, antes do ajuste
exclusivamente de imports/lint. Não houve retry nem execução da suíte completa.
O bloqueio ocorre no runner antes de carregar o teste; não há alegação de testes
verdes ou validação Android nativa. Apenas o teste e este registro foram editados
nesta rodada; nenhum commit criado.
A final test-only ordering correction was validated on 2026-10-08:
`AndroidFlutterLocalNotificationsPlugin.registerWith()` now runs before reading
and saving `FlutterLocalNotificationsPlatform.instance` in setUp. tearDown
restores that saved instance, then clears the mock MethodChannel handler and
platform override. The official MethodChannel boundary and all assertions remain.

Commands used `PUB_CACHE=/home/miguel/.hermes/cache/scratch/notifications-pub-cache`
and absolute SDK executables under
`/home/miguel/.hermes/cache/scratch/flutter-notifications-sdk/bin/`.
The test and format target was the absolute path
`/home/miguel/.hermes/workspace/hermes-mobile-unifiedpush-20261007/test/features/notifications/android_push_notifier_test.dart`.

| Final ordering check | Exact result | Log |
| --- | --- | --- |
| flutter test --no-pub (only android_push_notifier_test.dart) | Exit 1; 0 tests executed, 1 loading failure: Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0; Some tests failed. | /home/miguel/.hermes/cache/scratch/display-final-order-focused.log |
| dart format (only android_push_notifier_test.dart) | Exit 0; Formatted 1 file (0 changed) in 0.01 seconds. | /home/miguel/.hermes/cache/scratch/display-final-order-format.log |
| flutter analyze --no-pub | Exit 0; No issues found! (ran in 2.5s) | /home/miguel/.hermes/cache/scratch/display-final-order-analyze.log |
| git diff --check | Exit 0; no output | /home/miguel/.hermes/cache/scratch/display-final-order-diff-check.log |

The runner failed before loading the test; this result does not establish that
the tests pass. Only the requested test and this validation record were edited
in this correction. No commit was created.

## Validação PO final — 2026-10-08

Com o cache oficial prefetched fora do sandbox e após a correção de registro Dart
do plugin no teste, a PO executou a suíte completa no mesmo worktree com o SDK
absoluto e PUB_CACHE autorizado:

| Comando | Exit / resultado | Log |
| --- | --- | --- |
| `flutter pub get --offline` | 0; dependências resolvidas | `po-round2-pub-get.log` |
| `dart format` dos arquivos Dart de escopo | 0; 14 arquivos, 0 alterados | `po-final-format.log` |
| `flutter analyze --no-pub` | 0; No issues found | `po-final-analyze.log` |
| parser direto `push_notice_check.dart` | 0; checks fechados passaram | `po-final-parser.log` |
| kernels main, headless wrapper e 4 testes de integração/notifier | 0 cada; frontend sem erros | `po-final-*.log` |
| `flutter test --no-pub` suíte completa | **0; 763 testes passaram** | `po-final-full.log` |
| `flutter test` isolado do notifier | 1; runner bloqueado antes do loading por `ServerSocket 127.0.0.1:0 errno=1` | `po-round2-notifier-focused-final2.log` |
| `git diff --check` | 0 | validação final |

A suíte completa executou e passou os 9 casos de `android_push_notifier_test.dart`
(+124 a +136), os 3 casos de `main_bootstrap_test.dart` (+125 a +127) e o teste
de produção que confirma `AndroidPushNotifier` como sink default com
`backendEnrolled=false` (+137). O teste isolado continua sujeito ao bloqueio do
runner, mas não é usado para substituir a evidência da suíte completa.

A ponte continua não validada em engine Android/APK/aparelho: Java, javac e SDK
Android permanecem ausentes. Isso não é confundido com o sucesso Dart: não há
alegação de banner, permissão concedida, delivery, enrollment, ACL, backend ou
prontidão. Não houve push, merge, deploy ou commit nesta rodada.

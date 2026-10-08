# UnifiedPush receiver — 2026-10-07

Dependency resolution: **SUPERADO** in the real full app, offline. Implementation
remains experimental; this is not enrollment or proof of Android delivery.

## Official dependency choice

Inspected actual cached pubspecs and Dart/native sources under
`/home/miguel/.hermes/cache/scratch/notifications-pub-cache/hosted/pub.dev`.
`unifiedpush 6.2.0` requires `unifiedpush_linux ^1.0.0`, which requires
`webpush_encryption ^1.0.0` → `webcrypto ^0.6.0` → `hooks ^1.0.0`.
The app's google_fonts/path_provider/path_provider_foundation/objective_c 9.4.1
chain requires `hooks ^2.0.0`. Those ranges are disjoint. The isolated package
probe did not prove full-app resolution. The top-level package is removed.

Pinned official `unifiedpush_android 3.5.0` and
`unifiedpush_platform_interface 4.0.0`; no dependency override or SDK weakening.
Android pubspec declares native `org.unifiedpush.flutter.connector.Plugin` and
Dart `UnifiedPushAndroid`; its registerWith sets UnifiedPushPlatform.instance.
Flutter's generated .flutter-plugins-dependencies includes this Android plugin
with native_build=true. Actual native registration execution/APK remain untested.

The small adapter reproduces the inspected official wrapper semantics:
initializeCallback, initializeOnTempUnavailable, then getDistributor != null;
register stable instance with empty features/null distributor message/null VAPID;
same instance for unregister. Package data constructors are
PushMessage(content, decrypted), PushEndpoint(url, keys, temporary: bool).
Callbacks are guarded without logging their arguments.

## Receiver and state

Opt-in defaults off. Selection/default choice requires explicit consent. Endpoint
and key material remain private to the controller's secure storage namespace;
UI exposes only presence and generic status. Registration/endpoint success always
leaves backend enrollment pending. No permission API is invoked.

Only decrypted bounded bytes are accepted: strict UTF-8, 1024 bytes/512 codepoints,
closed four-field version 1 schema, event_id restricted to 1–64 ASCII identifier
characters, fixed completion/error categories and matching fixed summaries.
Rich/unknown fields and arbitrary text are rejected. Dedupe is bounded to 256
(scope, event_id) pairs per process, not a durable delivery ledger. Decryption
does not establish issuer authentication; server enrollment/ACL remain absent.
Message work is serialized, capped at 32 queued messages, and oversized messages
are rejected before queueing. Callback storage/registration errors are redacted.

Revoke suppresses reception synchronously at its public entry, before queueing
or IO, including pending messages. It persists opt-out before native
unregister, and preserves endpoint/selection on failure for retry. A persistence
failure cannot guarantee suppression after process restart; retry is required.
The unregistered callback also suppresses delivery and marks registration inactive
synchronously; read/write failure keeps suppression in memory and safe retry data,
with a generic failure status. No registration switching is allowed before revocation. No payload/endpoints/keys
are logged by this implementation.

Opening NotificationSheet/PushControls starts the foreground receiver once per
runtime controller from initState. Unsupported platforms do not call start or the
adapter. The listener is owned by the widget lifecycle; reopening does not repeat
initialization. After initialization, the switch permits explicit opt-in and
selection. This path does not initialize chat/socket or request OS permission.

## Headless and Android limitations

Separate headless main imports no app main, widgets, Riverpod, chat, socket, or
global secret store. It uses BindingBase with SchedulerBinding/ServicesBinding
and DartPluginRegistrant, initializes only this receiver, and never registers or
runs UI. It compiles to Flutter kernel.

It is NOT wired into the normal build. Cached UnifiedPushService.kt invokes
DartEntrypoint.createDefault() with --unifiedpush-bg; it cannot select this separate
library/function through the current adapter. Building with this file as -t would
replace the normal main for all launches, not solve normal/headless routing.
main.dart and normal bootstrap are unchanged. The backgroundNoUI unit test covers
the experimental bootstrap seam, not real Android service startup.

GenericPushNotifier defaults to NoopPushNotifier. Its test verifies only fixed
local text (Hermes / Novo aviso operacional), once per accepted event; no received
text or event identifier reaches it. No native OS display bridge or
flutter_local_notifications added. Android banner/APK unproven: no Java/Android SDK.
Enrollment, producer authorization, ntfy/server ACL, device foreground/background,
swipe/force-stop/offline behavior, and delivery remain pending.

## Validation evidence

All logs and kernel artifacts are under `/home/miguel/.hermes/cache/scratch`.
Flutter SDK: flutter-notifications-sdk; PUB_CACHE: notifications-pub-cache.

| Command/check | Exact exit | Log |
| --- | --- | --- |
| flutter pub get --offline (full app) | 0 | receiver-pub-get.log |
| dart format changed Dart (all invocations) | 0 | receiver-format*.log |
| Initial flutter analyze --no-pub | 1 | receiver-analyze.log |
| Final flutter analyze --no-pub | 0 | receiver-analyze-final.log |
| Focused Flutter tests | 0, **22 tests passed** | `po-final5-focused-all.log` |
| Flutter full suite | not rerun in PO pass; prior Codex attempt stopped at repeated localhost socket failures | `receiver-full-tests.log` |
| git diff --check | 0 | receiver-diff-check.log |

A análise inicial encontrou o erro de API do binding e um import desnecessário;
ambos foram corrigidos. A execução focal final passou com 22 testes verdes;
kernel compilation prova compilação de fonte, não execução nem build Android. O
parser/dedupe standalone também passou. A suíte Flutter completa não foi aceita
como verde: a tentativa disponível parou em falhas repetidas de socket localhost.
Tests present cover backgroundNoUI, fake official callbacks, accepted/rejected/
dedup payload, initialize false/true, defaultChoice/selection, permissionNoAction,
registration failure/retry, unregister/revoke, startup retry and storage error
state, generic notifier.

Architecture and USER_TESTING updated; prior result, backlog A81–A93 and old
scripts preserved. No push/merge/PR/deploy, Gateway, infrastructure or main.dart
edits; commit local criado nesta branch.

## Final corrective validation — 2026-10-07

Logs use `receiver-last-*` under `/home/miguel/.hermes/cache/scratch`.

| Command/check | Exit | Log |
| --- | --- | --- |
| dart format (three push files and controller tests) | 0 | receiver-last-format.log |
| flutter pub get --offline | 0 | receiver-last-pub-get.log |
| flutter analyze --no-pub | 0 | receiver-last-analyze.log |
| flutter test --no-pub test/features/notifications | 0, **22 testes passed** | po-final5-focused-all.log |
| dart run test/features/notifications/push_notice_check.dart | 0 | receiver-last-parser.log |

A execução focal final passou, com 22 testes verdes. Regressões cobrem mensagem
pendente durante revoke com persistência falha, callbacks unregistered com falha
de leitura/escrita, retry de registro inicial e restaurado, retry após falha
transitória de storage e inicialização foreground idempotente, enable/seleção
explícitos e plataformas unsupported. Falhas de escrita deixam opt_in persistido
como true; somente a supressão em processo é afirmada. A limitação P1 do
roteamento headless pelo main padrão e a restauração foreground condicionada à
abertura do painel continuam abertas por restrição de não alterar main.dart.

Headless and all three focused test sources compile to kernel: exit 0 each,
frontend output reports 0 errors. Logs: receiver-last-unifiedpush_entrypoint-compile.log,
receiver-last-push_controller_test-compile.log,
receiver-last-official_push_adapter_test-compile.log and
receiver-last-push_notice_test-compile.log. Two preliminary invocations using the
engine snapshot failed with exit 255 (attempt/attempt2 logs preserved); that cached
snapshot is x86-64 despite its linux-arm64 directory. Compilation succeeds with
the Dart SDK's actual ARM64 frontend snapshot. Compilation is not test execution.

git diff --check: exit 0 (receiver-last-diff-check.log). Preservation review:
no tracked deletions; README, backlog and prior scripts remain present and unchanged.
No commit, main.dart, Gateway, infrastructure or secret changes in this round.

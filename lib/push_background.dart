import 'dart:async';

import 'data/config/app_settings_store.dart';
import 'data/config/dashboard_session_store.dart';
import 'data/config/push_registration_store.dart';
import 'data/gateway/dashboard_gateway_repository.dart';
import 'data/platform/system_local_notifier.dart';
import 'data/platform/unified_push_transport.dart';
import 'domain/models/push_notice.dart';
import 'domain/repositories/push_transport.dart';
import 'features/notifications/notice_presenter.dart';
import 'features/settings/agent_persona.dart';

/// Argumento com que o conector UnifiedPush sobe o `main` sem Activity.
const unifiedPushBackgroundArg = '--unifiedpush-bg';

/// Entrada sem interface: o app está fechado e o distribuidor acordou o
/// processo com um push ou com um endpoint novo.
///
/// Não há [ProviderScope] aqui; as peças são as mesmas que o
/// [PushController] usa, montadas à mão.
Future<void> runPushBackground() async {
  final transport = UnifiedPushTransport();
  final notifier = SystemLocalNotifier();
  const store = SecurePushRegistrationStore();
  final persona = await _persona();

  transport.events.listen((event) async {
    try {
      switch (event) {
        case PushMessageReceived(:final bytes):
          final notice = PushNotice.tryParse(bytes);
          if (notice == null || !(await store.read()).enabled) return;
          switch (decideNotice(notice, persona: persona)) {
            case ShowNotice(:final notice):
              await notifier.show(notice);
            case CancelNotice(:final id):
              await notifier.cancel(id);
            case IgnoreNotice():
              break;
          }
        case PushEndpointIssued(temporary: false):
          await _renewEndpoint(store, event);
        default:
          break;
      }
    } catch (_) {
      // Sem tela para mostrar a falha; a próxima abertura do app reconcilia.
    }
  });
  await transport.initialize();
}

/// O distribuidor trocou o endpoint com o app fechado. Sem avisar o servidor,
/// os pushes seguintes iriam para um endereço morto até a próxima abertura.
Future<void> _renewEndpoint(
  PushRegistrationStore store,
  PushEndpointIssued event,
) async {
  final stored = await store.read();
  var next = (
    deviceId: stored.deviceId,
    enabled: stored.enabled,
    endpoint: event.url,
    p256dh: event.p256dh,
    auth: event.auth,
    syncedEndpoint: stored.syncedEndpoint,
  );
  await store.save(next);
  if (!stored.enabled || stored.syncedEndpoint == event.url) return;
  await DashboardGatewayRepository(
    store: const SecureDashboardSessionStore(),
  ).registerPushDevice((
    deviceId: stored.deviceId,
    endpoint: event.url,
    label: 'Hermes Mobile',
    p256dh: event.p256dh,
    auth: event.auth,
  ));
  next = (
    deviceId: next.deviceId,
    enabled: next.enabled,
    endpoint: next.endpoint,
    p256dh: next.p256dh,
    auth: next.auth,
    syncedEndpoint: event.url,
  );
  await store.save(next);
}

Future<AgentPersona> _persona() async {
  try {
    final stored = await const SecureAppSettingsStore().read();
    return AgentPersona(
      name: stored?.agentName?.trim() ?? '',
      gender: AgentGender.values
          .where((gender) => gender.name == stored?.agentGender)
          .firstOrNull,
    );
  } catch (_) {
    return const AgentPersona();
  }
}

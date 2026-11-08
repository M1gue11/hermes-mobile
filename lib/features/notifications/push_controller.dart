import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config/push_registration_store.dart';
import '../../data/gateway_repository_provider.dart';
import '../../data/platform/system_local_notifier.dart';
import '../../data/platform/unified_push_transport.dart';
import '../../domain/models/push_notice.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../../domain/repositories/local_notifier.dart';
import '../../domain/repositories/push_transport.dart';
import '../chat/chat_controller.dart';
import '../settings/settings_provider.dart';
import 'notice_presenter.dart';
import 'push_state.dart';

export 'push_state.dart';

final pushTransportProvider = Provider<PushTransport>(
  (ref) => UnifiedPushTransport(),
);

final localNotifierProvider = Provider<LocalNotifier>(
  (ref) => SystemLocalNotifier(),
);

final pushRegistrationStoreProvider = Provider<PushRegistrationStore>(
  (ref) => const SecurePushRegistrationStore(),
);

/// Quanto esperar o distribuidor entregar o endpoint depois do registro.
final pushEndpointTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// O app em primeiro plano e com a tela de conversa visível. Atualizado pelo
/// [HermesApp], que é quem enxerga o ciclo de vida e o roteador.
typedef AppPresence = ({bool resumed, bool onChat});

final appPresenceProvider = NotifierProvider<AppPresenceNotifier, AppPresence>(
  AppPresenceNotifier.new,
);

class AppPresenceNotifier extends Notifier<AppPresence> {
  @override
  AppPresence build() => (resumed: true, onChat: false);

  void update({bool? resumed, bool? onChat}) {
    final next = (
      resumed: resumed ?? state.resumed,
      onChat: onChat ?? state.onChat,
    );
    if (next != state) state = next;
  }
}

final pushControllerProvider = NotifierProvider<PushController, PushSetupState>(
  PushController.new,
);

/// Liga e desliga os avisos, registra o aparelho no distribuidor UnifiedPush
/// e no plugin `mobile-push` do servidor, e transforma cada push recebido com
/// o app aberto em aviso do sistema.
///
/// Com o app fechado quem recebe é `push_background.dart`, que usa as mesmas
/// regras de [decideNotice]. O app não deduz avisos da conversa por conta
/// própria: fora da tela o [ChatController] solta os listeners do turno, então
/// só o servidor sabe quando um turno termina em segundo plano.
class PushController extends Notifier<PushSetupState> {
  StreamSubscription<PushTransportEvent>? _events;
  StoredPushRegistration? _stored;
  Completer<PushEndpointIssued>? _endpointWaiter;

  PushTransport get _transport => ref.read(pushTransportProvider);
  PushRegistrationStore get _store => ref.read(pushRegistrationStoreProvider);
  LocalNotifier get _notifier => ref.read(localNotifierProvider);

  @override
  PushSetupState build() {
    ref.onDispose(() => _events?.cancel());
    unawaited(_boot());
    return const PushSetupState();
  }

  Future<void> _boot() async {
    try {
      _events = _transport.events.listen((event) => unawaited(_onEvent(event)));
      final stored = _stored = await _store.read();
      if (!stored.enabled) {
        state = state.copyWith(phase: PushPhase.off);
        return;
      }
      state = state.copyWith(
        enabled: true,
        endpointHost: _host(stored.endpoint),
        synced:
            stored.endpoint != null && stored.endpoint == stored.syncedEndpoint,
      );
      await _transport.initialize();
      unawaited(refreshServer());
      final distributor = await _transport.currentDistributor();
      if (distributor == null) {
        state = state.copyWith(phase: PushPhase.needsDistributor);
        return;
      }
      state = state.copyWith(
        distributor: distributor,
        phase: state.synced ? PushPhase.active : PushPhase.registering,
      );
      // O conector pede o registro a cada abertura; o distribuidor responde
      // com o endpoint, e um endpoint novo é sincronizado em [_onEvent].
      await _transport.register();
    } catch (_) {
      // Armazenamento ou plugin de plataforma indisponível: o resto do app
      // segue, e a tela de notificações mostra o estado desligado.
      if (state.phase == PushPhase.loading) {
        state = state.copyWith(phase: PushPhase.off);
      }
    }
  }

  Future<void> enable() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: null, permissionDenied: false);
    try {
      if (!await _notifier.requestPermission()) {
        state = state.copyWith(busy: false, permissionDenied: true);
        return;
      }
      await _save(enabled: true);
      state = state.copyWith(enabled: true);
      unawaited(refreshServer());
      await _transport.initialize();
      var distributor = await _transport.currentDistributor();
      if (distributor == null) {
        final found = await _transport.distributors();
        if (found.isEmpty) {
          state = state.copyWith(
            busy: false,
            phase: PushPhase.needsDistributor,
            distributors: const [],
          );
          return;
        }
        if (found.length > 1) {
          state = state.copyWith(
            busy: false,
            phase: PushPhase.choosingDistributor,
            distributors: found,
          );
          return;
        }
        distributor = found.single;
        await _transport.useDistributor(distributor);
      }
      await _registerWith(distributor);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error: 'Não foi possível ligar as notificações neste aparelho.',
      );
    }
  }

  Future<void> chooseDistributor(String distributor) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      await _transport.useDistributor(distributor);
      await _registerWith(distributor);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error: 'O distribuidor não aceitou o registro.',
      );
    }
  }

  Future<void> _registerWith(String distributor) async {
    state = state.copyWith(
      busy: true,
      distributor: distributor,
      phase: PushPhase.registering,
    );
    final waiter = _endpointWaiter = Completer<PushEndpointIssued>();
    await _transport.register();
    try {
      await waiter.future.timeout(ref.read(pushEndpointTimeoutProvider));
    } on TimeoutException {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error:
            'O distribuidor não respondeu. Abra o app ntfy e confira se ele '
            'está conectado ao seu servidor.',
      );
      return;
    } on PushRegistrationFailedException catch (error) {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error: error.message,
      );
      return;
    } finally {
      if (identical(_endpointWaiter, waiter)) _endpointWaiter = null;
    }
    await _sync();
  }

  /// Desliga localmente mesmo se o servidor estiver fora: o endpoint
  /// cancelado passa a responder 410 e o plugin remove o aparelho sozinho.
  Future<void> disable() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: null);
    final deviceId = _stored?.deviceId;
    if (deviceId != null) {
      try {
        await _gateway()?.removePushDevice(deviceId);
      } catch (_) {}
    }
    try {
      await _transport.unregister();
    } catch (_) {}
    await _save(
      enabled: false,
      endpoint: null,
      p256dh: null,
      auth: null,
      syncedEndpoint: null,
    );
    state = PushSetupState(
      phase: PushPhase.off,
      pluginAvailable: state.pluginAvailable,
      serverEncryption: state.serverEncryption,
    );
  }

  /// Tenta de novo o passo que falhou: registro no distribuidor ou no servidor.
  Future<void> retry() async {
    final distributor = state.distributor;
    if (_stored?.endpoint != null && distributor != null) {
      state = state.copyWith(busy: true, error: null);
      await _sync();
      return;
    }
    await enable();
  }

  Future<void> sendTest() async {
    final deviceId = _stored?.deviceId;
    final gateway = _gateway();
    if (state.busy || deviceId == null || gateway == null) return;
    state = state.copyWith(busy: true, error: null, lastTest: null);
    try {
      final result = await gateway.testPushDevice(deviceId);
      state = state.copyWith(busy: false, lastTest: result);
      if (result.gone) {
        // O servidor já removeu o aparelho; o endpoint que vier, mesmo
        // repetido, precisa ser registrado de novo.
        await _save(syncedEndpoint: null);
        state = state.copyWith(synced: false, phase: PushPhase.registering);
        await _transport.register();
      }
    } on GatewayOperationException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
    } on GatewayAuthenticationRequired catch (error) {
      state = state.copyWith(busy: false, error: error.message);
    }
  }

  /// Pergunta ao servidor se o plugin existe e se este aparelho está nele.
  Future<void> refreshServer() async {
    final gateway = _gateway();
    final deviceId = _stored?.deviceId;
    if (gateway == null || deviceId == null) return;
    try {
      final server = await gateway.pushDevices();
      final known = server.devices.any((device) => device.id == deviceId);
      state = state.copyWith(
        pluginAvailable: true,
        serverEncryption: server.encryption,
      );
      // A resposta pode chegar no meio de um registro; só uma leitura feita
      // em repouso decide que o servidor esqueceu o aparelho.
      final stored = _stored;
      if (!known &&
          !state.busy &&
          stored != null &&
          stored.enabled &&
          stored.endpoint != null) {
        await _sync();
      }
    } on PushPluginMissing {
      if (!state.busy) {
        state = state.copyWith(pluginAvailable: false, synced: false);
      }
    } catch (_) {
      // Sem rede ou sem login: o estado anterior continua valendo.
    }
  }

  /// Mostra, apaga ou ignora o aviso conforme a conversa visível.
  Future<void> deliver(PushNotice notice) async {
    final presence = ref.read(appPresenceProvider);
    final viewing =
        presence.resumed &&
        presence.onChat &&
        ref.read(chatControllerProvider).sessionId == notice.sessionId;
    final decision = decideNotice(
      notice,
      persona: ref.read(agentPersonaProvider),
      viewing: viewing,
    );
    try {
      switch (decision) {
        case ShowNotice(:final notice):
          await _notifier.show(notice);
        case CancelNotice(:final id):
          await _notifier.cancel(id);
        case IgnoreNotice():
          break;
      }
    } catch (_) {
      // Permissão revogada ou canal desligado: nada a fazer pelo app.
    }
  }

  Future<void> _onEvent(PushTransportEvent event) async {
    switch (event) {
      case PushEndpointIssued(temporary: true):
        break;
      case PushEndpointIssued():
        await _save(
          endpoint: event.url,
          p256dh: event.p256dh,
          auth: event.auth,
        );
        state = state.copyWith(endpointHost: _host(event.url));
        final waiter = _endpointWaiter;
        if (waiter != null && !waiter.isCompleted) {
          waiter.complete(event);
          return;
        }
        final stored = _stored;
        if (stored != null &&
            stored.enabled &&
            stored.syncedEndpoint != event.url) {
          await _sync();
        }
      case PushRegistrationFailed(:final reason):
        final failure = PushRegistrationFailedException(reason);
        final waiter = _endpointWaiter;
        if (waiter != null && !waiter.isCompleted) {
          waiter.completeError(failure);
          return;
        }
        state = state.copyWith(phase: PushPhase.failed, error: failure.message);
      case PushUnregistered():
        await _save(endpoint: null, syncedEndpoint: null);
        state = state.copyWith(
          phase: PushPhase.failed,
          synced: false,
          endpointHost: null,
          error: 'O distribuidor cancelou o registro deste aparelho.',
        );
      case PushMessageReceived(:final bytes):
        final notice = PushNotice.tryParse(bytes);
        if (notice != null && state.enabled) await deliver(notice);
    }
  }

  Future<void> _sync() async {
    final stored = _stored;
    final endpoint = stored?.endpoint;
    if (stored == null || endpoint == null) return;
    final gateway = _gateway();
    if (gateway == null) {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error: 'Entre no Dashboard para receber avisos com o app fechado.',
      );
      return;
    }
    state = state.copyWith(busy: true, phase: PushPhase.registering);
    try {
      await gateway.registerPushDevice((
        deviceId: stored.deviceId,
        endpoint: endpoint,
        label: 'Hermes Mobile',
        p256dh: stored.p256dh,
        auth: stored.auth,
      ));
      await _save(syncedEndpoint: endpoint);
      state = state.copyWith(
        busy: false,
        phase: PushPhase.active,
        synced: true,
        pluginAvailable: true,
        error: null,
      );
      unawaited(refreshServer());
    } on PushPluginMissing {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        synced: false,
        pluginAvailable: false,
        error: null,
      );
    } on GatewayAuthenticationRequired catch (error) {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error: error.message,
      );
    } on GatewayOperationException catch (error) {
      state = state.copyWith(
        busy: false,
        phase: PushPhase.failed,
        error: error.message,
      );
    }
  }

  Future<void> _save({
    bool? enabled,
    Object? endpoint = _keep,
    Object? p256dh = _keep,
    Object? auth = _keep,
    Object? syncedEndpoint = _keep,
  }) async {
    final current = _stored ??= await _store.read();
    String? pick(Object? value, String? old) =>
        identical(value, _keep) ? old : value as String?;
    final next = (
      deviceId: current.deviceId,
      enabled: enabled ?? current.enabled,
      endpoint: pick(endpoint, current.endpoint),
      p256dh: pick(p256dh, current.p256dh),
      auth: pick(auth, current.auth),
      syncedEndpoint: pick(syncedEndpoint, current.syncedEndpoint),
    );
    _stored = next;
    await _store.save(next);
  }

  GatewayRepository? _gateway() {
    try {
      return ref.read(gatewayRepositoryProvider);
    } catch (_) {
      return null;
    }
  }

  static String? _host(String? url) {
    if (url == null) return null;
    final host = Uri.tryParse(url)?.host;
    return host == null || host.isEmpty ? null : host;
  }
}

const Object _keep = Object();

/// Falha de registro relatada pelo distribuidor, já em português.
class PushRegistrationFailedException implements Exception {
  PushRegistrationFailedException(this.reason);

  final String reason;

  String get message => switch (reason) {
    'network' =>
      'O distribuidor está sem rede. Tente de novo quando a conexão voltar.',
    'actionRequired' =>
      'O app ntfy precisa de atenção (login ou servidor). Abra o ntfy e '
          'tente de novo.',
    'vapidRequired' =>
      'Este distribuidor exige uma chave VAPID, que o Hermes não usa. '
          'Use o app ntfy.',
    _ => 'O distribuidor recusou o registro. Tente de novo.',
  };
}

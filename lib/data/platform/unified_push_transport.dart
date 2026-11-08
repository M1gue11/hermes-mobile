import 'dart:async';
import 'dart:io';

import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';

import '../../domain/repositories/push_transport.dart';

/// [PushTransport] sobre o conector UnifiedPush do Android.
///
/// O app depende só de `unifiedpush_android`, e não do pacote guarda-chuva:
/// este puxa a implementação Linux, que traz BoringSSL e `window_manager` para
/// um app que só roda no celular. A API do guarda-chuva é um repasse fino da
/// interface de plataforma, reproduzido aqui.
///
/// Sem distribuidor no iOS, tudo vira lista vazia ou operação sem efeito.
class UnifiedPushTransport implements PushTransport {
  UnifiedPushTransport({this.instance = 'hermes'});

  final String instance;
  final _events = StreamController<PushTransportEvent>.broadcast();
  bool _initialized = false;

  bool get _supported => Platform.isAndroid;
  UnifiedPushPlatform get _platform => UnifiedPushPlatform.instance;

  @override
  Stream<PushTransportEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (!_supported || _initialized) return;
    _initialized = true;
    await _platform.initializeCallback(
      onNewEndpoint: (PushEndpoint endpoint, String from) {
        if (from != instance) return;
        _events.add(
          PushEndpointIssued(
            url: endpoint.url,
            p256dh: endpoint.pubKeySet?.pubKey,
            auth: endpoint.pubKeySet?.auth,
            temporary: endpoint.temporary,
          ),
        );
      },
      onRegistrationFailed: (FailedReason reason, String from) {
        if (from == instance) _events.add(PushRegistrationFailed(reason.name));
      },
      onUnregistered: (String from) {
        if (from == instance) _events.add(const PushUnregistered());
      },
      onMessage: (PushMessage message, String from) {
        if (from != instance) return;
        _events.add(
          PushMessageReceived(message.content, decrypted: message.decrypted),
        );
      },
    );
  }

  @override
  Future<List<String>> distributors() async =>
      _supported ? await _platform.getDistributors(const []) : const [];

  @override
  Future<String?> currentDistributor() async =>
      _supported ? await _platform.getDistributor() : null;

  @override
  Future<void> useDistributor(String distributor) async {
    if (_supported) await _platform.saveDistributor(distributor);
  }

  @override
  Future<void> register() async {
    if (_supported) await _platform.register(instance, const [], null, null);
  }

  @override
  Future<void> unregister() async {
    if (_supported) await _platform.unregister(instance);
  }
}

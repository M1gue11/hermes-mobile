import 'dart:typed_data';

/// Evento do distribuidor de push (UnifiedPush) instalado no aparelho.
sealed class PushTransportEvent {
  const PushTransportEvent();
}

/// Endereço novo para o servidor publicar. Pode chegar a qualquer momento,
/// também com o app fechado: o distribuidor renova endpoints sozinho.
final class PushEndpointIssued extends PushTransportEvent {
  const PushEndpointIssued({
    required this.url,
    this.p256dh,
    this.auth,
    this.temporary = false,
  });

  final String url;

  /// Chaves WebPush geradas no aparelho; o servidor cifra com elas.
  final String? p256dh;
  final String? auth;

  /// Endpoint provisório: ainda não vale a pena mandar ao servidor.
  final bool temporary;
}

final class PushRegistrationFailed extends PushTransportEvent {
  const PushRegistrationFailed(this.reason);

  /// `network`, `actionRequired`, `vapidRequired` ou `internalError`.
  final String reason;
}

/// O distribuidor cancelou o registro (app ntfy desinstalado, por exemplo).
final class PushUnregistered extends PushTransportEvent {
  const PushUnregistered();
}

final class PushMessageReceived extends PushTransportEvent {
  const PushMessageReceived(this.bytes, {required this.decrypted});

  final Uint8List bytes;
  final bool decrypted;
}

abstract interface class PushTransport {
  /// Eventos do distribuidor. Só começam a fluir depois de [initialize].
  Stream<PushTransportEvent> get events;

  Future<void> initialize();

  /// Ids de pacote dos distribuidores instalados (o app ntfy, por exemplo).
  Future<List<String>> distributors();

  Future<String?> currentDistributor();

  Future<void> useDistributor(String distributor);

  /// Precisa ser chamado a cada abertura do app enquanto o push estiver ativo.
  Future<void> register();

  Future<void> unregister();
}

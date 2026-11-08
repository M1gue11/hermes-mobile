import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_device.freezed.dart';

/// Aparelho registrado no plugin `mobile-push` do servidor. O servidor nunca
/// devolve o endpoint inteiro nem as chaves, só o host.
@freezed
abstract class PushDevice with _$PushDevice {
  const factory PushDevice({
    required String id,
    @Default('') String label,
    @Default('') String endpointHost,
    @Default(false) bool encrypted,
    DateTime? updatedAt,
  }) = _PushDevice;
}

/// [encryption] diz se o servidor consegue cifrar o envelope (WebPush). Sem
/// isso, o envelope mínimo passa legível pelo servidor ntfy.
typedef PushServerState = ({bool encryption, List<PushDevice> devices});

/// O que o app manda ao registrar: o endpoint do distribuidor e as chaves
/// WebPush que o conector gerou no aparelho.
typedef PushRegistration = ({
  String deviceId,
  String endpoint,
  String label,
  String? p256dh,
  String? auth,
});

/// [gone]: o distribuidor descartou o endpoint e o servidor já removeu o
/// aparelho; é preciso registrar de novo.
typedef PushTestResult = ({bool ok, int status, bool encrypted, bool gone});

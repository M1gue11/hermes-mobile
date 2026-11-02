import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_pairing.freezed.dart';

/// Pessoa que mandou mensagem ao agente por uma plataforma (Telegram,
/// WhatsApp…) e espera aprovação, de `GET /api/pairing`.
///
/// O servidor nunca devolve o código enviado à pessoa, só um [requestId] para
/// aprovar. Pedidos antigos, anteriores ao formato com hash, vêm sem id e só
/// podem ser aprovados pelo código, no computador.
@freezed
abstract class PairingRequest with _$PairingRequest {
  const PairingRequest._();

  const factory PairingRequest({
    required String platform,
    @Default('') String requestId,
    @Default('') String userId,
    @Default('') String userName,
    @Default(0) int ageMinutes,
  }) = _PairingRequest;

  bool get canApprove => requestId.isNotEmpty;
}

@freezed
abstract class PairedUser with _$PairedUser {
  const factory PairedUser({
    required String platform,
    required String userId,
    @Default('') String userName,
    DateTime? approvedAt,
  }) = _PairedUser;
}

typedef PairingState = ({
  List<PairingRequest> pending,
  List<PairedUser> approved,
});

/// Nome de exibição da plataforma, como a pessoa a conhece.
String platformLabel(String platform) => switch (platform.toLowerCase()) {
  'telegram' => 'Telegram',
  'whatsapp' => 'WhatsApp',
  'discord' => 'Discord',
  'signal' => 'Signal',
  'slack' => 'Slack',
  'matrix' => 'Matrix',
  'email' => 'E-mail',
  'sms' => 'SMS',
  'imessage' || 'bluebubbles' => 'iMessage',
  'google_chat' => 'Google Chat',
  'mattermost' => 'Mattermost',
  final other when other.isEmpty => 'Plataforma',
  final other => other[0].toUpperCase() + other.substring(1),
};

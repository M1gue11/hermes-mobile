import 'dart:io';

/// Valida o endereço sem fazer DNS e sem alterar a política TLS do sistema.
String? normalizeHttpEndpoint(String raw, {bool allowPath = true}) {
  final uri = Uri.tryParse(raw.trim().replaceFirst(RegExp(r'/+$'), ''));
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (!allowPath && uri.path.isNotEmpty)) {
    return null;
  }
  try {
    if (uri.port < 1 || uri.port > 65535) return null;
  } on FormatException {
    return null;
  }
  return uri.replace(scheme: uri.scheme.toLowerCase()).toString();
}

bool usesCleartext(String raw) =>
    Uri.tryParse(raw.trim())?.scheme.toLowerCase() == 'http';

/// Classificação apenas para graduar o aviso; nunca autoriza uma conexão nem
/// afirma que há VPN. Um nome público pode resolver para IP privado, e um
/// nome ts.net pode usar Funnel em vez do túnel.
bool isPrivateOrTailnetHost(String host) {
  final normalized = host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  if (normalized == 'localhost' ||
      normalized.endsWith('.localhost') ||
      normalized.endsWith('.ts.net') ||
      normalized.endsWith('.local')) {
    return true;
  }
  final ip = InternetAddress.tryParse(normalized);
  if (ip == null) return false;
  final bytes = ip.rawAddress;
  if (ip.type == InternetAddressType.IPv6) {
    if (ip.isLoopback) return true;
    if ((bytes[0] & 0xfe) == 0xfc ||
        (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80)) {
      return true;
    }
    if (bytes.take(10).every((b) => b == 0) &&
        bytes[10] == 255 &&
        bytes[11] == 255) {
      return _privateV4(bytes.sublist(12));
    }
    return false;
  }
  return _privateV4(bytes);
}

bool _privateV4(List<int> bytes) =>
    bytes[0] == 10 ||
    bytes[0] == 127 ||
    (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
    (bytes[0] == 192 && bytes[1] == 168) ||
    (bytes[0] == 169 && bytes[1] == 254) ||
    (bytes[0] == 100 && bytes[1] >= 64 && bytes[1] <= 127);

String? cleartextWarning(String raw) {
  if (!usesCleartext(raw)) return null;
  final host = Uri.tryParse(raw.trim())?.host ?? '';
  final strong = isPrivateOrTailnetHost(host)
      ? ''
      : 'Host público ou rede não verificada: evite enviar credenciais pela internet sem TLS. ';
  return '${strong}Em HTTP, a chave, a senha, o cookie e as mensagens podem ser '
      'lidos por quem estiver na rede, a menos que o trajeto já seja cifrado '
      'por Tailscale ou outra VPN. O nome do host não comprova essa proteção.';
}

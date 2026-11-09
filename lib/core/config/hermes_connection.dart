import 'transport_security.dart';

/// Configuração de acesso do cliente nativo ao Hermes API Server.
///
/// A chave nunca é incluída no APK: ela é informada pelo dono do aparelho e
/// persistida somente no armazenamento seguro da plataforma.
class HermesConnection {
  const HermesConnection({required this.baseUrl, required this.apiKey});

  final String baseUrl;
  final String apiKey;

  String? validate() {
    if (normalizeHttpEndpoint(baseUrl) == null) {
      return 'Use uma URL HTTP ou HTTPS válida para o gateway.';
    }
    if (apiKey.trim().isEmpty) {
      return 'Informe a chave da API do Hermes.';
    }
    return null;
  }

  HermesConnection normalized() => HermesConnection(
    baseUrl: baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
    apiKey: apiKey.trim(),
  );
}

/// Uma credencial salva só vale para a origem (esquema, host e porta) em que
/// foi salva (A81). Trocar só o caminho mantém o servidor; trocar o host
/// mandaria a chave ou a senha para outra máquina.
bool sameCredentialOrigin(String? saved, String typed) {
  Uri? parse(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri == null || !uri.hasAuthority || uri.host.isEmpty ? null : uri;
  }

  final a = parse(saved);
  final b = parse(typed);
  if (a == null || b == null) return false;
  return a.scheme.toLowerCase() == b.scheme.toLowerCase() &&
      a.host.toLowerCase() == b.host.toLowerCase() &&
      a.port == b.port;
}

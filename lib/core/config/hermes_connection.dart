/// Configuração de acesso do cliente nativo ao Hermes API Server.
///
/// A chave nunca é incluída no APK: ela é informada pelo dono do aparelho e
/// persistida somente no armazenamento seguro da plataforma.
class HermesConnection {
  const HermesConnection({required this.baseUrl, required this.apiKey});

  final String baseUrl;
  final String apiKey;

  String? validate() {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
      return 'Use uma URL HTTPS válida para o gateway.';
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

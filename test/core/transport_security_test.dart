import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/config/hermes_connection.dart';
import 'package:hermes_mobile/core/config/transport_security.dart';
import 'package:hermes_mobile/data/gateway/dashboard_gateway_repository.dart';

void main() {
  for (final url in [
    'http://192.168.1.5:8642',
    'http://100.64.0.1:9119',
    'http://public.example:80',
    'http://[::1]:8642',
    'https://public.example',
  ]) {
    test('A92: API e Dashboard aceitam $url', () {
      expect(
        HermesConnection(baseUrl: url, apiKey: 'synthetic').validate(),
        isNull,
      );
      expect(DashboardGatewayRepository.supportsBaseUrl(url), isTrue);
    });
  }
  for (final url in [
    'ftp://public.example',
    'http://',
    'http://user@host',
    'http://host?token=synthetic',
    'http://host#fragment',
    'http://host:70000',
  ]) {
    test('A92: rejeita endereço inválido ou ambíguo $url', () {
      expect(normalizeHttpEndpoint(url), isNull);
    });
  }
  test('API conserva prefixo de caminho; Dashboard continua sendo origem', () {
    expect(
      normalizeHttpEndpoint(' https://host/hermes/ '),
      'https://host/hermes',
    );
    expect(
      normalizeHttpEndpoint('https://host/hermes', allowPath: false),
      isNull,
    );
  });
  test('HTTP avisa mesmo na tailnet ou em rede privada; HTTPS não avisa', () {
    expect(
      cleartextWarning('http://host.example.ts.net'),
      contains('a chave, a senha, o cookie'),
    );
    expect(
      cleartextWarning('http://192.168.1.5'),
      contains('Tailscale ou outra VPN'),
    );
    expect(cleartextWarning('https://public.example'), isNull);
    expect(
      cleartextWarning('http://public.example'),
      startsWith('Host público'),
    );
  });
  test(
    'classificação não confunde IP público com privado nem sufixo malicioso',
    () {
      for (final host in [
        '10.0.0.1',
        '127.0.0.1',
        '172.16.0.1',
        '192.168.1.1',
        '100.64.0.1',
        '100.127.255.255',
        '::1',
        'fd7a:115c:a1e0::1',
        'fe80::1',
        'host.ts.net',
      ]) {
        expect(isPrivateOrTailnetHost(host), isTrue, reason: host);
      }
      for (final host in [
        '8.8.8.8',
        '100.63.0.1',
        '100.128.0.1',
        '172.32.0.1',
        'host.ts.net.evil.example',
        '2001:4860:4860::8888',
      ]) {
        expect(isPrivateOrTailnetHost(host), isFalse, reason: host);
      }
    },
  );
}

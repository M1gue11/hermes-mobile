import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/config/hermes_connection.dart';

void main() {
  test('aceita endpoint HTTPS e chave preenchida', () {
    const connection = HermesConnection(
      baseUrl: 'https://hermes-gateway.example.ts.net/hermes',
      apiKey: 'secret',
    );

    expect(connection.validate(), isNull);
  });

  test('rejeita endpoint HTTP e chave vazia', () {
    const connection = HermesConnection(
      baseUrl: 'http://100.0.0.1:8642',
      apiKey: '',
    );

    expect(connection.validate(), isNotNull);
  });

  test('normaliza barra final e espaços', () {
    const connection = HermesConnection(
      baseUrl: ' https://hermes-gateway.example.ts.net/hermes/ ',
      apiKey: ' token ',
    );

    final normalized = connection.normalized();
    expect(normalized.baseUrl, 'https://hermes-gateway.example.ts.net/hermes');
    expect(normalized.apiKey, 'token');
  });
}

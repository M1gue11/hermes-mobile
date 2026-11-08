import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/config/hermes_connection.dart';

void main() {
  test('A81: credencial salva só vale na mesma origem', () {
    const saved = 'https://api.old.ts.net/hermes';
    expect(sameCredentialOrigin(saved, 'https://api.old.ts.net'), isTrue);
    expect(
      sameCredentialOrigin(saved, ' HTTPS://API.OLD.ts.net:443/x '),
      isTrue,
    );
    expect(
      sameCredentialOrigin(
        'http://dash.old.ts.net:9119',
        'http://dash.old.ts.net:9119/',
      ),
      isTrue,
    );

    expect(
      sameCredentialOrigin(saved, 'https://api.new.ts.net/hermes'),
      isFalse,
    );
    expect(sameCredentialOrigin(saved, 'https://api.old.ts.net:8443'), isFalse);
    expect(sameCredentialOrigin(saved, 'http://api.old.ts.net'), isFalse);
    expect(sameCredentialOrigin(saved, ''), isFalse);
    expect(sameCredentialOrigin(saved, 'api.old.ts.net'), isFalse);
    expect(sameCredentialOrigin(null, 'https://api.old.ts.net'), isFalse);
  });

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

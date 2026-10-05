import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/dashboard_session_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('persiste sessão e credenciais em entradas seguras separadas', () async {
    const store = SecureDashboardSessionStore();

    await store.save((
      baseUrl: 'https://dashboard.example:8443',
      cookies: {'session': 'opaque'},
    ));
    await store.saveCredentials((
      baseUrl: 'https://dashboard.example:8443',
      username: 'operator',
      password: 'segredo-sintetico',
    ));

    final session = await store.read();
    expect(session?.baseUrl, 'https://dashboard.example:8443');
    expect(session?.cookies, {'session': 'opaque'});
    expect(await store.readCredentials(), (
      baseUrl: 'https://dashboard.example:8443',
      username: 'operator',
      password: 'segredo-sintetico',
    ));
  });

  test('limpa credenciais sem apagar a sessão', () async {
    const store = SecureDashboardSessionStore();
    await store.save((
      baseUrl: 'https://dashboard.example:8443',
      cookies: {'session': 'opaque'},
    ));
    await store.saveCredentials((
      baseUrl: 'https://dashboard.example:8443',
      username: 'operator',
      password: 'segredo-sintetico',
    ));

    await store.clearCredentials();

    expect(await store.readCredentials(), isNull);
    expect(await store.read(), isNotNull);
  });
}

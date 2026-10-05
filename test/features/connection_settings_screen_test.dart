import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/config/hermes_connection.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/config/connection_store.dart';
import 'package:hermes_mobile/data/config/dashboard_session_store.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/features/connection/connection_screen.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';

class _MemoryConnectionStore implements ConnectionStore {
  _MemoryConnectionStore(this.value);

  HermesConnection? value;
  int saves = 0;
  int clears = 0;

  @override
  Future<void> clear() async {
    clears++;
    value = null;
  }

  @override
  Future<HermesConnection?> read() async => value;

  @override
  Future<void> save(HermesConnection connection) async {
    saves++;
    value = connection;
  }
}

class _MemoryDashboardStore implements DashboardSessionStore {
  _MemoryDashboardStore({this.session, this.credentials});

  DashboardSession? session;
  DashboardCredentials? credentials;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<void> clearCredentials() async => credentials = null;

  @override
  Future<DashboardSession?> read() async => session;

  @override
  Future<DashboardCredentials?> readCredentials() async => credentials;

  @override
  Future<void> save(DashboardSession value) async => session = value;

  @override
  Future<void> saveCredentials(DashboardCredentials value) async =>
      credentials = value;
}

Widget _screen({
  required _MemoryConnectionStore connectionStore,
  required _MemoryDashboardStore dashboardStore,
  required FakeGatewayRepository gateway,
  required ValueChanged<HermesConnection> onConnected,
}) => MaterialApp(
  theme: AppTheme.build(),
  home: ConnectionScreen(
    editing: true,
    store: connectionStore,
    dashboardStore: dashboardStore,
    dashboard: gateway,
    initialConnection: connectionStore.value,
    onConnected: onConnected,
    repositoryFactory: (_) => FakeHermesRepository(),
  ),
);

void main() {
  const oldConnection = HermesConnection(
    baseUrl: 'https://api.old.ts.net',
    apiKey: 'api-secret-old',
  );
  final oldSession = (
    baseUrl: 'http://dashboard.old.ts.net:9119',
    cookies: <String, String>{'session': 'cookie-secret-old'},
  );
  final oldCredentials = (
    baseUrl: 'http://dashboard.old.ts.net:9119',
    username: 'operator',
    password: 'dashboard-secret-old',
  );

  testWidgets('edição não exibe segredos e vazio mantém os valores atuais', (
    tester,
  ) async {
    final connectionStore = _MemoryConnectionStore(oldConnection);
    final dashboardStore = _MemoryDashboardStore(
      session: oldSession,
      credentials: oldCredentials,
    );
    final gateway = FakeGatewayRepository();
    HermesConnection? connected;

    await tester.pumpWidget(
      _screen(
        connectionStore: connectionStore,
        dashboardStore: dashboardStore,
        gateway: gateway,
        onConnected: (value) => connected = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('api-secret-old'), findsNothing);
    expect(find.text('dashboard-secret-old'), findsNothing);
    final apiField = tester.widget<TextField>(
      find.byKey(const ValueKey('connection-api-key')),
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(const ValueKey('dashboard-connection-password')),
    );
    expect(apiField.controller?.text, isEmpty);
    expect(passwordField.controller?.text, isEmpty);
    expect(apiField.obscureText, isTrue);
    expect(passwordField.obscureText, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('connection-base-url')),
      'https://api.new.ts.net',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-connections')));
    await tester.tap(find.byKey(const ValueKey('save-connections')));
    await tester.pumpAndSettle();

    expect(connectionStore.value?.baseUrl, 'https://api.new.ts.net');
    expect(connectionStore.value?.apiKey, 'api-secret-old');
    expect(gateway.authentications.single.password, 'dashboard-secret-old');
    expect(connected?.baseUrl, 'https://api.new.ts.net');
  });

  testWidgets('segredos digitados substituem os valores protegidos', (
    tester,
  ) async {
    final connectionStore = _MemoryConnectionStore(oldConnection);
    final dashboardStore = _MemoryDashboardStore(
      session: oldSession,
      credentials: oldCredentials,
    );
    final gateway = FakeGatewayRepository();

    await tester.pumpWidget(
      _screen(
        connectionStore: connectionStore,
        dashboardStore: dashboardStore,
        gateway: gateway,
        onConnected: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('connection-api-key')),
      'api-secret-new',
    );
    await tester.enterText(
      find.byKey(const ValueKey('dashboard-connection-password')),
      'dashboard-secret-new',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-connections')));
    await tester.tap(find.byKey(const ValueKey('save-connections')));
    await tester.pumpAndSettle();

    expect(connectionStore.value?.apiKey, 'api-secret-new');
    expect(gateway.authentications.single.password, 'dashboard-secret-new');
  });

  testWidgets('falha restaura integralmente as duas conexões anteriores', (
    tester,
  ) async {
    final connectionStore = _MemoryConnectionStore(oldConnection);
    final dashboardStore = _MemoryDashboardStore(
      session: oldSession,
      credentials: oldCredentials,
    );
    final gateway = FakeGatewayRepository(
      authenticateHandler:
          ({required baseUrl, required username, required password}) async {
            await dashboardStore.save((
              baseUrl: 'http://dashboard.new.ts.net:9119',
              cookies: <String, String>{'session': 'new-cookie'},
            ));
            await dashboardStore.saveCredentials((
              baseUrl: 'http://dashboard.new.ts.net:9119',
              username: username,
              password: password,
            ));
            throw const GatewayOperationException(
              'O Dashboard recusou a nova configuração.',
            );
          },
    );
    HermesConnection? connected;

    await tester.pumpWidget(
      _screen(
        connectionStore: connectionStore,
        dashboardStore: dashboardStore,
        gateway: gateway,
        onConnected: (value) => connected = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('connection-base-url')),
      'https://api.new.ts.net',
    );
    await tester.enterText(
      find.byKey(const ValueKey('dashboard-connection-url')),
      'http://dashboard.new.ts.net:9119',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-connections')));
    await tester.tap(find.byKey(const ValueKey('save-connections')));
    await tester.pumpAndSettle();

    expect(
      find.text('O Dashboard recusou a nova configuração.'),
      findsOneWidget,
    );
    expect(connectionStore.value, oldConnection);
    expect(dashboardStore.session, oldSession);
    expect(dashboardStore.credentials, oldCredentials);
    expect(connected, isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/config/hermes_connection.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/config/connection_store.dart';
import 'package:hermes_mobile/features/chat/widgets/gateway_login_sheet.dart';
import 'package:hermes_mobile/features/connection/connection_screen.dart';

import '../support/fake_gateway_repository.dart';

class _EmptyConnectionStore implements ConnectionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<HermesConnection?> read() async => null;

  @override
  Future<void> save(HermesConnection connection) async {}
}

TextField _field(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key));

void main() {
  testWidgets('pareamento inicial não sugere endpoints embutidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: ConnectionScreen(
          store: _EmptyConnectionStore(),
          dashboard: FakeGatewayRepository(),
          onConnected: (_) {},
        ),
      ),
    );

    expect(
      _field(tester, const ValueKey('connection-base-url')).controller?.text,
      isEmpty,
    );
    expect(
      _field(
        tester,
        const ValueKey('dashboard-connection-url'),
      ).controller?.text,
      isEmpty,
    );
  });

  testWidgets('login de anexos não sugere endpoint embutido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              await showGatewayLoginSheet(
                context,
                authenticate:
                    ({
                      required baseUrl,
                      required username,
                      required password,
                    }) async {},
              );
            },
            child: const Text('Abrir login'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir login'));
    await tester.pumpAndSettle();

    expect(
      _field(tester, const ValueKey('dashboard-url')).controller?.text,
      isEmpty,
    );
  });
}

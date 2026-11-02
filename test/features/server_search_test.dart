import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_list_screen.dart';
import 'package:hermes_mobile/features/chat/server_search_provider.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';

final _agora = DateTime.now();

final _locais = [
  Conversation(id: 'local', title: 'Planejar vault', lastActive: _agora),
];

Widget _harness(FakeGatewayRepository? gateway) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    hermesRepositoryProvider.overrideWithValue(
      FakeHermesRepository(conversations: _locais),
    ),
    activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
    if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
    serverSearchDebounceProvider.overrideWithValue(Duration.zero),
  ],
  child: MaterialApp(theme: AppTheme.build(), home: const ChatListScreen()),
);

Future<void> _buscar(WidgetTester tester, String termo) async {
  await tester.tap(find.byKey(const ValueKey('conversation-discovery-toggle')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('conversation-search-field')),
    termo,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('conteúdo encontrado no servidor aparece sem repetir a lista', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()
      ..resultadosDeBusca = [
        (
          conversation: Conversation(id: 'local', title: 'Planejar vault'),
          snippet: 'já listada',
          role: 'user',
        ),
        (
          conversation: Conversation(
            id: 'antiga',
            title: 'Backup do servidor',
            source: 'telegram',
            lastActive: DateTime(2026, 9, 3),
          ),
          snippet: 'guardar a chave do >>>vault<<< fora da máquina',
          role: 'assistant',
        ),
      ];
    await tester.pumpWidget(_harness(gateway));
    await tester.pumpAndSettle();
    await _buscar(tester, 'vault');

    expect(gateway.buscas, ['vault']);
    expect(find.text('NO CONTEÚDO DAS CONVERSAS'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-search-row-antiga')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('server-search-row-local')), findsNothing);
    expect(
      find.textContaining('guardar a chave do vault', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('telegram · agente'), findsOneWidget);
  });

  testWidgets('nada na lista nem no servidor diz que não achou', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository();
    await tester.pumpWidget(_harness(gateway));
    await tester.pumpAndSettle();
    await _buscar(tester, 'inexistente');

    expect(gateway.buscas, ['inexistente']);
    expect(find.text('Nenhuma conversa encontrada.'), findsOneWidget);
  });

  testWidgets('sem Dashboard a busca local segue sozinha', (tester) async {
    await tester.pumpWidget(_harness(null));
    await tester.pumpAndSettle();
    await _buscar(tester, 'vault');

    expect(find.text('Planejar vault'), findsWidgets);
    expect(find.text('NO CONTEÚDO DAS CONVERSAS'), findsNothing);
  });

  testWidgets('um caractere não consulta o servidor', (tester) async {
    final gateway = FakeGatewayRepository();
    await tester.pumpWidget(_harness(gateway));
    await tester.pumpAndSettle();
    await _buscar(tester, 'v');

    expect(gateway.buscas, isEmpty);
  });
}

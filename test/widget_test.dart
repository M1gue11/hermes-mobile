import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';
import 'package:hermes_mobile/main.dart';

import 'support/fake_hermes_repository.dart';
import 'support/memory_last_conversation_store.dart';

/// A abertura automática de A64 é sempre explícita aqui. Deixá-la depender do
/// armazenamento real tornaria estes testes não determinísticos, e eles são
/// justamente os que descrevem o que a pessoa vê ao abrir o app.
Widget bootApp({String? ultimaConversa}) => ProviderScope(
  overrides: [
    hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
    lastConversationStoreProvider.overrideWithValue(
      MemoryLastConversationStore(
        id: ultimaConversa,
        title: 'Conversa persistida',
      ),
    ),
  ],
  child: const HermesApp(),
);

void main() {
  testWidgets('a lista de sessões persistidas fica atrás do chat', (
    tester,
  ) async {
    await tester.pumpWidget(bootApp(ultimaConversa: 'session-1'));
    await tester.pumpAndSettle();

    // A64: o app abre na conversa, e a lista continua a um gesto de distância.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Conversas'), findsOneWidget);
    expect(find.textContaining('GATEWAY'), findsOneWidget);
    expect(find.text('Conversa persistida'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('nova conversa cria sessão e navega para o chat', (tester) async {
    await tester.pumpWidget(bootApp(ultimaConversa: 'session-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No que estamos trabalhando?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

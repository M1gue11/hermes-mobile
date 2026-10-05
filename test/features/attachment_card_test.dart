import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

import '../support/fake_hermes_repository.dart';

const _caminho =
    '/home/example/.hermes/cache/documents/ab12_99_transactions.csv';

const _nota =
    "[The user sent a text document: 'transactions.csv'. "
    'Its content has been included below. '
    'The file is also saved at: $_caminho]';

/// O turno como o gateway o persiste: nota, conteúdo e legenda.
const _comLegenda =
    '$_nota\n\n'
    '[Content of transactions.csv]:\n'
    'data,valor\n2026-08-01,10.00\n'
    '\n\n'
    'me explica esse extrato';

/// O mesmo turno com uma linha em branco interna e sem o sinal seguro.
const _semSinal =
    '$_nota\n\n'
    '[Content of transactions.csv]:\n'
    'data,valor\n\n2026-08-01,10.00';

Future<void> abrir(WidgetTester tester, String texto) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserBubble(UserMessage(id: 'u1', text: texto, time: '0:37')),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('o envelope e o arquivo saem da bolha', (tester) async {
    await abrir(tester, _comLegenda);

    // Continua sendo turno da pessoa: ela mandou o arquivo mesmo.
    expect(find.text('VOCÊ'), findsOneWidget);
    // Mas nem o texto de máquina nem o CSV aparecem na conversa.
    expect(find.textContaining('The user sent a text document'), findsNothing);
    expect(find.textContaining('2026-08-01,10.00'), findsNothing);

    expect(find.byKey(const ValueKey('anexo')), findsOneWidget);
    expect(find.text('transactions.csv'), findsOneWidget);
    expect(find.text('CSV · 27 B'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('a legenda separável aparece como fala', (tester) async {
    await abrir(tester, _comLegenda);
    expect(find.text('me explica esse extrato'), findsOneWidget);
    await fechar(tester);
  });

  testWidgets('sem o sinal seguro, nenhuma linha vira fala', (tester) async {
    await abrir(tester, _semSinal);

    expect(find.byKey(const ValueKey('anexo')), findsOneWidget);
    // A última linha do arquivo **não** é promovida a fala da pessoa: é esse o
    // erro que o A23 corrigiu e que o A24 não pode reintroduzir.
    expect(find.textContaining('2026-08-01,10.00'), findsNothing);

    await fechar(tester);
  });

  testWidgets('o conteúdo fica a um toque, com o caminho junto', (
    tester,
  ) async {
    await abrir(tester, _comLegenda);

    await tester.tap(find.byKey(const ValueKey('anexo')));
    await tester.pumpAndSettle();

    expect(find.textContaining('data,valor'), findsOneWidget);
    expect(find.text(_caminho), findsOneWidget);
    expect(find.byKey(const ValueKey('copiar-anexo')), findsOneWidget);
    // Com legenda separada não há o que avisar.
    expect(find.byKey(const ValueKey('aviso-da-legenda')), findsNothing);

    await fechar(tester);
  });

  testWidgets('quando a legenda pode estar no conteúdo, a folha diz isso', (
    tester,
  ) async {
    await abrir(tester, _semSinal);

    await tester.tap(find.byKey(const ValueKey('anexo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('aviso-da-legenda')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('mensagem sem anexo continua sendo bolha comum', (tester) async {
    await abrir(tester, 'bom dia!');

    expect(find.byKey(const ValueKey('anexo')), findsNothing);
    expect(find.text('bom dia!'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('PDF sem conteúdo embutido ainda vira card com o caminho', (
    tester,
  ) async {
    const turno =
        "[The user sent a document: 'contrato.pdf'. It is saved at: "
        '/root/.hermes/cache/x_1_contrato.pdf. '
        "Its text is not inlined here (it's a binary format such as PDF or "
        'DOCX).]\n\nresume pra mim';

    await abrir(tester, turno);

    expect(find.text('contrato.pdf'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('resume pra mim'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('anexo')));
    await tester.pumpAndSettle();
    expect(find.text('/root/.hermes/cache/x_1_contrato.pdf'), findsOneWidget);

    await fechar(tester);
  });
}

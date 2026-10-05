import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/widgets/unicode_spinner.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';

import '../support/fake_hermes_repository.dart';

/// A13: enquanto o Hermes responde havia três animações concorrentes na tela,
/// e o usuário decidiu que a marca braille ocupa o lugar do cursor, que deixa
/// de existir. Estes testes fixam a decisão.
const _marca = ValueKey('streaming-brand');
const _cauda = ValueKey('conversation-tail-spinner');

ChatState _emResposta(ChatPhase phase, {String text = ''}) => ChatState(
  sessionId: 'sessao-viva',
  streaming: true,
  messages: [
    const UserMessage(id: 'u1', text: 'Pergunta', time: '09:30'),
    AssistantMessage(id: 'a1', phase: phase, text: text, time: '09:30'),
  ],
);

Future<void> _abrir(WidgetTester tester, ChatState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatControllerProvider.overrideWithValue(state),
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
      child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('escrevendo: a marca fica no ponto de escrita, sem cursor', (
    tester,
  ) async {
    await _abrir(
      tester,
      _emResposta(ChatPhase.writing, text: 'Resposta parcial'),
    );

    final marca = find.byKey(_marca);
    expect(
      marca,
      findsOneWidget,
      reason: 'a marca tem de estar dentro da bolha',
    );
    expect(tester.widget<UnicodeSpinner>(marca).active, isTrue);

    // A marca está dentro da linha de texto, não abaixo dela: à direita do
    // início do parágrafo e dentro da caixa que o parágrafo ocupa.
    final texto = tester.getRect(
      find.textContaining('Resposta parcial', findRichText: true),
    );
    final pontoDeEscrita = tester.getRect(marca);
    expect(pontoDeEscrita.left, greaterThan(texto.left));
    expect(pontoDeEscrita.bottom, lessThanOrEqualTo(texto.bottom + 1));

    await _fechar(tester);
  });

  testWidgets('raciocinando sem texto ainda mostra a marca', (tester) async {
    await _abrir(tester, _emResposta(ChatPhase.reasoning));
    expect(find.byKey(_marca), findsOneWidget);
    expect(find.byKey(const ValueKey('response-status')), findsOneWidget);
    expect(find.text('RESPONDENDO'), findsNothing);
    await _fechar(tester);
  });

  testWidgets('a cauda some enquanto a marca está no ponto de escrita', (
    tester,
  ) async {
    await _abrir(tester, _emResposta(ChatPhase.writing, text: 'Parcial'));
    expect(find.byKey(_cauda), findsNothing);
    expect(find.byKey(const ValueKey('response-status')), findsNothing);
    await _fechar(tester);
  });

  testWidgets('turno concluído: cauda volta a animar e a marca sai do texto', (
    tester,
  ) async {
    await _abrir(tester, _emResposta(ChatPhase.done, text: 'Resposta final'));
    expect(find.byKey(_marca), findsNothing);
    expect(tester.widget<UnicodeSpinner>(find.byKey(_cauda)).active, isTrue);
    await _fechar(tester);
  });

  testWidgets('não há barra de progresso no topo durante a resposta', (
    tester,
  ) async {
    await _abrir(tester, _emResposta(ChatPhase.writing, text: 'Parcial'));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await _fechar(tester);
  });
}

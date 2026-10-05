import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/widgets/hermes_chip.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';

import '../support/fake_hermes_repository.dart';

/// Pedido do usuário em 2026-08-08: a barra de mensagem tinha tamanhos de botão
/// e alinhamentos inconsistentes. Estes testes fixam a grade que resolveu isso,
/// medida na árvore e não no olho.
///
/// Antes havia **cinco** geometrias no mesmo canto da tela (`IconButton`
/// compacto, círculo de 36, `TextButton` do Material, `IconButton` padrão e
/// `IconButton` de 32), nenhuma delas atingindo o mínimo de toque de 48 do
/// Android, e o texto do campo caía 13px acima do centro dos botões.
const _anexar = ValueKey('composer-attach');
const _gravar = ValueKey('composer-record');
const _enviar = ValueKey('composer-send');

/// O mínimo do Android, que cobre os 44 do iOS.
const _alvo = 48.0;

Future<void> _abrir(WidgetTester tester, {ChatState? state}) async {
  tester.view.physicalSize = const Size(1344, 2992);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatControllerProvider.overrideWithValue(
          state ??
              const ChatState(
                messages: [UserMessage(id: 'u1', text: 'oi', time: '09:30')],
              ),
        ),
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
      child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
    ),
  );
  await tester.pump();
}

/// A marca braille da cauda roda num `Timer`. O arnês confere timer pendente
/// **antes** dos teardowns, então cada caso desmonta a árvore no próprio corpo.
Future<void> _fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

Color? _fundoDe(WidgetTester tester, Key chave) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byKey(chave),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration as BoxDecoration?)?.color;
}

void main() {
  testWidgets('todo controle da barra tem a mesma caixa de 48', (tester) async {
    await _abrir(tester);
    for (final chave in [_anexar, _gravar, _enviar]) {
      expect(
        tester.getSize(find.byKey(chave)),
        const Size(_alvo, _alvo),
        reason: 'controle $chave fora da grade',
      );
    }
    await _fechar(tester);
  });

  testWidgets('as pastilhas também alcançam o mínimo de toque', (tester) async {
    await _abrir(tester);
    expect(find.text('Atividade'), findsNothing);
    expect(find.text('Máquina'), findsOneWidget);
    for (final chip in tester.widgetList<HermesChip>(find.byType(HermesChip))) {
      expect(chip.minTapHeight, _alvo, reason: 'pastilha "${chip.label}"');
    }
    expect(
      tester.getSize(find.byType(HermesChip).first).height,
      greaterThanOrEqualTo(_alvo),
    );
    await _fechar(tester);
  });

  testWidgets('os botões compartilham o mesmo centro', (tester) async {
    await _abrir(tester);
    final centro = tester.getRect(find.byKey(_anexar)).center.dy;
    for (final chave in [_gravar, _enviar]) {
      expect(tester.getRect(find.byKey(chave)).center.dy, centro);
    }
    await _fechar(tester);
  });

  testWidgets('a linha de texto pousa junto com os botões', (tester) async {
    await _abrir(tester);
    final centro = tester.getRect(find.byKey(_anexar)).center.dy;
    final caixa = tester.getRect(find.text('Fale com Hermes…'));

    // **A caixa do texto não é o texto.** Ela tem a altura da linha e inclui o
    // espaço do descendente, que as letras quase não ocupam, então a tinta fica
    // uns 4px acima do centro dela. Igualar os dois centros parece certo na
    // árvore e sai visivelmente alto no aparelho: foi o defeito que o usuário
    // apontou em 2026-08-08, depois de eu ter "corrigido" por este caminho.
    //
    // O número abaixo veio da tinta, medida na captura do emulador a 3x com o
    // fundo da pílula como referência: `+` em 2797, microfone em 2795,5, enviar
    // em 2797 e o texto em 2803. Ou seja, dois pixels lógicos, que é o mesmo
    // que alinhado. Na árvore isso aparece como a caixa 6px abaixo do centro
    // dos botões, e é isso que este teste guarda.
    expect(
      caixa.center.dy - centro,
      closeTo(6, 1),
      reason:
          'a caixa do texto fica 6px abaixo do centro dos botões, o que põe a '
          'tinta em cima deles; zerar esta diferença sobe o texto',
    );
    await _fechar(tester);
  });

  testWidgets('a linha tem os 52px do desenho', (tester) async {
    await _abrir(tester);
    // `padding:8px` em volta de uma marca de 36. Aqui a folga é de 2 em volta de
    // caixas de 48, que dá exatamente o mesmo.
    final linha = tester.getSize(
      find.ancestor(of: find.byKey(_anexar), matching: find.byType(Row)).first,
    );
    expect(linha.height, _alvo);
    await _fechar(tester);
  });

  testWidgets('campo crescendo mantém os botões na base', (tester) async {
    await _abrir(tester);
    final baseAntes = tester.getRect(find.byKey(_enviar)).bottom;

    await tester.enterText(
      find.byType(TextField).last,
      List.filled(9, 'palavra comprida').join(' '),
    );
    await tester.pumpAndSettle();

    final enviar = tester.getRect(find.byKey(_enviar));
    expect(
      enviar.bottom,
      baseAntes,
      reason: 'o campo cresce para cima; os botões ficam onde o dedo os deixou',
    );
    final linha = tester.getSize(
      find.ancestor(of: find.byKey(_anexar), matching: find.byType(Row)).first,
    );
    expect(linha.height, greaterThan(_alvo));
    expect(
      tester.getRect(find.byKey(_anexar)).bottom,
      enviar.bottom,
      reason: 'os dois extremos da linha continuam na mesma base',
    );
    await _fechar(tester);
  });

  testWidgets('só a ação primária usa círculo preenchido', (tester) async {
    await _abrir(tester);
    // A queixa original: com a barra vazia, microfone e enviar eram dois
    // círculos idênticos lado a lado e nada dizia qual era a ação da vez.
    expect(_fundoDe(tester, _anexar), isNull);
    expect(_fundoDe(tester, _gravar), isNull);
    expect(_fundoDe(tester, _enviar), isNotNull);
    await _fechar(tester);
  });

  testWidgets('o microfone sai quando há o que enviar', (tester) async {
    await _abrir(tester);
    expect(find.byKey(_gravar), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'oi');
    await tester.pumpAndSettle();

    expect(
      find.byKey(_gravar),
      findsNothing,
      reason:
          'com texto, a ação da vez é enviar, e duas ofertas disputam o dedo',
    );
    expect(tester.getSize(find.byKey(_enviar)), const Size(_alvo, _alvo));
    await _fechar(tester);
  });
}

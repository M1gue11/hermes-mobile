import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/features/skills/skills_screen.dart';

import '../support/fake_hermes_repository.dart';

Widget _screen(FakeHermesRepository repository) => ProviderScope(
  retry: (_, _) => null,
  overrides: [hermesRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(theme: AppTheme.build(), home: const SkillsScreen()),
);

void main() {
  testWidgets('lista ordena, busca metadados e explica o limite da API', (
    tester,
  ) async {
    final repository = FakeHermesRepository(
      skills: const [
        HermesSkill(
          name: 'vision-analyse',
          description: 'Analisa imagens e capturas.',
          category: 'mídia',
        ),
        HermesSkill(
          name: 'automation-kit',
          description: 'Automação de rotinas locais.',
          category: 'operação',
        ),
        HermesSkill(
          name: 'read-file',
          description: 'Consulta arquivos do projeto.',
          category: 'filesystem',
        ),
      ],
    );

    await tester.pumpWidget(_screen(repository));
    await tester.pumpAndSettle();

    expect(find.text('API SERVER · SOMENTE LEITURA'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('automation-kit')).dy,
      lessThan(tester.getTopLeft(find.text('read-file')).dy),
    );

    await tester.enterText(
      find.byKey(const ValueKey('skills-search')),
      'automacao',
    );
    await tester.pump();

    expect(find.text('automation-kit'), findsOneWidget);
    expect(find.text('vision-analyse'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('skill-row-automation-kit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('skill-details-automation-kit')),
      findsOneWidget,
    );
    expect(find.text('Disponível para o agente'), findsOneWidget);
    expect(
      find.textContaining('não expõe o conteúdo integral'),
      findsOneWidget,
    );
    expect(
      find.textContaining('sem oferecer edição ou ativação'),
      findsOneWidget,
    );
  });

  testWidgets('distingue gateway vazio de busca sem resultado', (tester) async {
    await tester.pumpWidget(_screen(FakeHermesRepository(skills: const [])));
    await tester.pumpAndSettle();

    expect(find.text('O gateway não anunciou nenhuma Skill.'), findsOneWidget);

    await tester.pumpWidget(
      _screen(
        FakeHermesRepository(
          skills: const [
            HermesSkill(name: 'read-file', description: 'Lê arquivos.'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('skills-search')),
      'inexistente',
    );
    await tester.pump();

    expect(find.text('Nenhuma Skill corresponde à busca.'), findsOneWidget);
    await tester.tap(find.text('Limpar busca'));
    await tester.pump();
    expect(find.text('read-file'), findsOneWidget);
  });

  testWidgets('preserva a geometria no loading e permite retry após falha', (
    tester,
  ) async {
    final repository = _ControlledSkillsRepository();
    await tester.pumpWidget(_screen(repository));
    await tester.pump();

    expect(find.byKey(const ValueKey('skills-loading')), findsOneWidget);

    repository.completeFailure();
    await tester.pumpAndSettle();

    expect(find.text('O gateway não pôde atender'), findsOneWidget);
    expect(find.byKey(const ValueKey('skills-falha-retry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('skills-falha-retry')));
    await tester.pump();
    repository.completeSuccess();
    await tester.pumpAndSettle();

    expect(find.text('recovered-skill'), findsOneWidget);
  });

  testWidgets('ação da conversa empilha a tela inteira de Skills', (
    tester,
  ) async {
    final router = buildAppRouter(initialLocation: '/chat');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Skills'), findsOneWidget);
    expect(find.byTooltip('Contexto da conversa'), findsNothing);

    await tester.tap(find.byTooltip('Skills'));
    await tester.pumpAndSettle();

    expect(find.byType(SkillsScreen), findsOneWidget);
    expect(find.text('hermes-agent'), findsOneWidget);
  });

  testWidgets('texto ampliado preserva catálogo e detalhe sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          hermesRepositoryProvider.overrideWithValue(
            FakeHermesRepository(
              skills: const [
                HermesSkill(
                  name: 'skill-with-a-very-long-operational-name',
                  description:
                      'Descrição extensa para conferir quebra de linha e leitura.',
                  category: 'categoria extensa',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: SkillsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(
        const ValueKey('skill-row-skill-with-a-very-long-operational-name'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('não expõe o conteúdo integral'),
      findsOneWidget,
    );
  });
}

class _ControlledSkillsRepository extends FakeHermesRepository {
  Completer<List<HermesSkill>> _request = Completer<List<HermesSkill>>();

  @override
  Future<List<HermesSkill>> skills() => _request.future;

  void completeFailure() {
    _request.completeError(
      const HermesFailure(
        HermesFailureKind.gatewayIndisponivel,
        statusCode: 503,
      ),
    );
    _request = Completer<List<HermesSkill>>();
  }

  void completeSuccess() {
    _request.complete(const [
      HermesSkill(name: 'recovered-skill', description: 'Catálogo recuperado.'),
    ]);
  }
}

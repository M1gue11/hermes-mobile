import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/features/skills/skill_detail_screen.dart';
import 'package:hermes_mobile/features/skills/skill_editor_screen.dart';
import 'package:hermes_mobile/features/skills/skills_screen.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';

Widget _app(
  FakeHermesRepository api, {
  FakeGatewayRepository? gateway,
  String location = '/skills',
  TextScaler? textScaler,
}) {
  final router = buildAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  return ProviderScope(
    key: UniqueKey(),
    retry: (_, _) => null,
    overrides: [
      hermesRepositoryProvider.overrideWithValue(api),
      if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
    ],
    child: MaterialApp.router(
      theme: AppTheme.build(),
      routerConfig: router,
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
    ),
  );
}

const _skillMd =
    '---\nname: read-file\ndescription: Lê arquivos.\n---\n\nUse com cuidado.\n';

FakeGatewayRepository _dashboard() => FakeGatewayRepository()
  ..catalogo = const [
    HermesSkill(
      name: 'read-file',
      description: 'Lê arquivos.',
      category: 'filesystem',
      enabled: true,
    ),
    HermesSkill(name: 'old-skill', description: 'Antiga.', enabled: false),
  ]
  ..conteudos['read-file'] = _skillMd;

String _shownContent(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const ValueKey('skill-content')))
    .data!;

Future<void> _openEditor(
  WidgetTester tester,
  FakeGatewayRepository gateway,
) async {
  await tester.pumpWidget(
    _app(
      FakeHermesRepository(),
      gateway: gateway,
      location: skillDetailLocation('read-file'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('skill-edit')));
  await tester.pumpAndSettle();
}

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

    await tester.pumpWidget(_app(repository));
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
    expect(find.byKey(const ValueKey('skill-edit')), findsNothing);
    expect(find.byKey(const ValueKey('skill-enabled-switch')), findsNothing);
  });

  testWidgets('distingue gateway vazio de busca sem resultado', (tester) async {
    await tester.pumpWidget(_app(FakeHermesRepository(skills: const [])));
    await tester.pumpAndSettle();

    expect(find.text('O gateway não anunciou nenhuma Skill.'), findsOneWidget);

    await tester.pumpWidget(
      _app(
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
    await tester.pumpWidget(_app(repository));
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
    await tester.pumpWidget(_app(FakeHermesRepository(), location: '/chat'));
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
      _app(
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
        textScaler: const TextScaler.linear(1.8),
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
    await tester.scrollUntilVisible(
      find.textContaining('não expõe o conteúdo integral'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(
              const ValueKey(
                'skill-details-skill-with-a-very-long-operational-name',
              ),
            ),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
  });

  group('com o Dashboard', () {
    testWidgets('lista desativadas, lê o SKILL.md e alterna a ativação', (
      tester,
    ) async {
      final gateway = _dashboard();
      await tester.pumpWidget(_app(FakeHermesRepository(), gateway: gateway));
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD · LEITURA E EDIÇÃO'), findsOneWidget);
      expect(find.text('DESATIVADA · SEM CATEGORIA'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('skill-row-read-file')));
      await tester.pumpAndSettle();

      expect(_shownContent(tester), _skillMd);
      expect(find.text('Ativa para o agente'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('skill-enabled-switch')));
      await tester.pumpAndSettle();

      expect(gateway.alternancias, [(name: 'read-file', enabled: false)]);
      expect(find.text('Desativada'), findsOneWidget);
    });

    testWidgets('editor grava e volta ao detalhe com o texto novo', (
      tester,
    ) async {
      final gateway = _dashboard();
      await _openEditor(tester, gateway);

      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('skill-save')))
            .onPressed,
        isNull,
      );

      const novo = '$_skillMd\nPasso extra.\n';
      await tester.enterText(find.byKey(const ValueKey('skill-editor')), novo);
      await tester.pump();
      expect(find.text('SKILL.MD · NÃO SALVO'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('skill-save')));
      await tester.pumpAndSettle();

      expect(gateway.gravacoes, [(name: 'read-file', content: novo)]);
      expect(find.byType(SkillEditorScreen), findsNothing);
      expect(_shownContent(tester), novo);
    });

    testWidgets('sair com alterações pede confirmação antes de descartar', (
      tester,
    ) async {
      final gateway = _dashboard();
      await _openEditor(tester, gateway);
      await tester.enterText(
        find.byKey(const ValueKey('skill-editor')),
        'rascunho',
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Fechar editor'));
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);

      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(find.byType(SkillEditorScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Fechar editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skill-discard')));
      await tester.pumpAndSettle();

      expect(find.byType(SkillEditorScreen), findsNothing);
      expect(gateway.gravacoes, isEmpty);
      expect(_shownContent(tester), _skillMd);
    });

    testWidgets('mudança no servidor durante a edição pede para substituir', (
      tester,
    ) async {
      final gateway = _dashboard();
      await _openEditor(tester, gateway);
      gateway.conteudos['read-file'] = '$_skillMd\nEditado pelo agente.\n';

      await tester.enterText(
        find.byKey(const ValueKey('skill-editor')),
        'minha versão',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('skill-save')));
      await tester.pumpAndSettle();

      expect(find.text('O SKILL.md mudou no servidor'), findsOneWidget);
      expect(gateway.gravacoes, isEmpty);

      await tester.tap(find.byKey(const ValueKey('skill-overwrite')));
      await tester.pumpAndSettle();

      expect(gateway.gravacoes, [(name: 'read-file', content: 'minha versão')]);
    });

    testWidgets('recusa do Dashboard mantém o editor aberto com a causa', (
      tester,
    ) async {
      final gateway = _dashboard()
        ..falhaAoGravar = const GatewayOperationException(
          "Frontmatter must include 'name' field.",
        );
      await _openEditor(tester, gateway);
      await tester.enterText(
        find.byKey(const ValueKey('skill-editor')),
        'sem frontmatter',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('skill-save')));
      await tester.pumpAndSettle();

      expect(find.byType(SkillEditorScreen), findsOneWidget);
      expect(
        find.textContaining("Frontmatter must include 'name' field."),
        findsOneWidget,
      );
    });
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

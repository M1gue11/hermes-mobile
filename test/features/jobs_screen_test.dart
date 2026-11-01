import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/cron_job.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/features/jobs/job_editor_screen.dart';
import 'package:hermes_mobile/features/jobs/job_labels.dart';

import '../support/fake_hermes_repository.dart';

Widget _app(FakeHermesRepository api, {String location = '/jobs'}) {
  final router = buildAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [hermesRepositoryProvider.overrideWithValue(api)],
    child: MaterialApp.router(theme: AppTheme.build(), routerConfig: router),
  );
}

FakeHermesRepository _withJobs() => FakeHermesRepository()
  ..rotinas = [
    const CronJob(
      id: 'aaa000aaa000',
      name: 'Resumo da manhã',
      schedule: '0 9 * * *',
      prompt: 'Resuma meus e-mails.',
    ),
    const CronJob(
      id: 'bbb000bbb000',
      name: 'Varredura antiga',
      schedule: 'every 30m',
      enabled: false,
      state: 'paused',
    ),
  ];

void main() {
  group('rótulos', () {
    final now = DateTime(2026, 11, 1, 8);

    test('momento curto relativo ao dia', () {
      expect(jobMomentLabel(DateTime(2026, 11, 1, 9), now), 'hoje 09:00');
      expect(jobMomentLabel(DateTime(2026, 11, 2, 7, 5), now), 'amanhã 07:05');
      expect(jobMomentLabel(DateTime(2026, 10, 31, 18), now), 'ontem 18:00');
      expect(jobMomentLabel(DateTime(2026, 11, 9, 9), now), '9 nov 09:00');
      expect(jobMomentLabel(DateTime(2027, 1, 3, 9), now), '3 jan 2027 09:00');
    });

    test('pausada não oferece executar agora', () {
      const paused = CronJob(
        id: 'x',
        name: 'x',
        enabled: false,
        state: 'paused',
      );
      expect(paused.canRunNow, isFalse);
      expect(paused.canResume, isTrue);
      expect(const CronJob(id: 'y', name: 'y').canRunNow, isTrue);
      expect(
        const CronJob(id: 'z', name: 'z', state: 'completed').canPause,
        isFalse,
      );
    });
  });

  testWidgets('lista ativas antes das pausadas e pausa pela folha', (
    tester,
  ) async {
    final api = _withJobs();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Resumo da manhã')).dy,
      lessThan(tester.getTopLeft(find.text('Varredura antiga')).dy),
    );
    expect(find.text('Pausada'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('job-row-aaa000aaa000')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('job-run')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('job-pause')));
    await tester.pumpAndSettle();

    expect(api.acoesEmRotinas, ['pause:aaa000aaa000']);
    expect(find.byKey(const ValueKey('job-resume')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-run')), findsNothing);
  });

  testWidgets('excluir pede confirmação', (tester) async {
    final api = _withJobs();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-row-bbb000bbb000')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Excluir rotina?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.acoesEmRotinas, isEmpty);

    await tester.tap(find.byKey(const ValueKey('job-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-delete-confirm')));
    await tester.pumpAndSettle();

    expect(api.acoesEmRotinas, ['delete:bbb000bbb000']);
    expect(find.text('Varredura antiga'), findsNothing);
  });

  testWidgets('servidor sem cron mostra indisponível, sem botão de criar', (
    tester,
  ) async {
    final api = FakeHermesRepository()
      ..falhaEmRotinas = const HermesFailure(
        HermesFailureKind.servidorFalhou,
        statusCode: 501,
      );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jobs-unavailable')), findsOneWidget);
    expect(find.byKey(const ValueKey('jobs-new')), findsNothing);
  });

  testWidgets('cria rotina e volta para a lista', (tester) async {
    final api = FakeHermesRepository();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jobs-empty')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('jobs-new')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('job-save')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const ValueKey('job-name')), 'Diário');
    await tester.enterText(
      find.byKey(const ValueKey('job-schedule')),
      'every day at 9am',
    );
    await tester.enterText(
      find.byKey(const ValueKey('job-prompt')),
      'Resuma o dia.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('job-save')));
    await tester.pumpAndSettle();

    expect(api.acoesEmRotinas, ['create:Diário']);
    expect(find.byType(JobEditorScreen), findsNothing);
    expect(find.text('Diário'), findsOneWidget);
  });

  testWidgets('recusa do servidor mantém o formulário com a causa', (
    tester,
  ) async {
    final api = FakeHermesRepository();
    await tester.pumpWidget(_app(api, location: '/jobs/new'));
    await tester.pumpAndSettle();
    api.falhaEmRotinas = const HermesFailure(
      HermesFailureKind.respostaInesperada,
      statusCode: 400,
      serverMessage: "Invalid duration: 'xyz'.",
    );

    await tester.enterText(find.byKey(const ValueKey('job-name')), 'x');
    await tester.enterText(
      find.byKey(const ValueKey('job-schedule')),
      'every xyz',
    );
    await tester.enterText(find.byKey(const ValueKey('job-prompt')), 'y');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('job-save')));
    await tester.pumpAndSettle();

    expect(find.byType(JobEditorScreen), findsOneWidget);
    expect(find.textContaining("Invalid duration: 'xyz'."), findsOneWidget);
  });

  testWidgets('sair com campos preenchidos pede confirmação', (tester) async {
    await tester.pumpWidget(_app(FakeHermesRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('jobs-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('job-name')), 'Rascunho');
    await tester.pump();

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar rotina?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('job-discard')));
    await tester.pumpAndSettle();

    expect(find.byType(JobEditorScreen), findsNothing);
  });
}

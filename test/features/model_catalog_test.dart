import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/domain/models/hermes_provider.dart';
import 'package:hermes_mobile/domain/models/model_options.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/widgets/sheets.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';

/// A21.4: o seletor passou a mostrar o que o inventário já trazia e a permitir
/// buscar o catálogo ao vivo.
///
/// O `refresh` importa porque, medido em `hermes_cli/inventory.py`, sem ele o
/// servidor responde pelo cache de disco e a maioria dos providers aparece com
/// `0 modelos`.
class CatalogoFake extends FakeHermesRepository {
  static const emCache = ModelOptions(
    model: 'hermes-4-70b',
    provider: 'nous',
    providers: [
      HermesProvider(
        id: 'nous',
        name: 'Nous Portal',
        models: ['hermes-4-70b', 'hermes-4-405b'],
        totalModels: 2,
        isCurrent: true,
        authenticated: true,
        freeTier: true,
        unavailableModels: ['hermes-4-405b'],
        pricing: {
          'hermes-4-70b': ModelPricing(free: true),
          'hermes-4-405b': ModelPricing(input: r'$3.00', output: r'$15.00'),
        },
        capabilities: {
          'hermes-4-70b': ModelCapabilities(fast: true, reasoning: false),
          'hermes-4-405b': ModelCapabilities(reasoning: true),
        },
      ),
      HermesProvider(
        id: 'anthropic',
        name: 'Anthropic',
        models: [],
        totalModels: 0,
        authenticated: false,
        authType: 'api_key',
        keyEnv: 'ANTHROPIC_API_KEY',
        warning: 'paste ANTHROPIC_API_KEY to activate',
      ),
    ],
  );

  static const aoVivo = ModelOptions(
    model: 'hermes-5-preview',
    provider: 'nous',
    providers: [
      HermesProvider(
        id: 'nous',
        name: 'Nous Portal',
        models: ['hermes-4-70b', 'hermes-4-405b', 'hermes-5-preview'],
        totalModels: 3,
        isCurrent: true,
        authenticated: true,
      ),
    ],
  );

  CatalogoFake() {
    inventarioAtualizado = aoVivo;
  }

  @override
  Future<ModelOptions> modelOptions({bool refresh = false}) async {
    inventarios.add(refresh);
    if (refresh) {
      final falha = falhaAoAtualizar;
      if (falha != null) {
        falhaAoAtualizar = null;
        throw falha;
      }
      return inventarioAtualizado ?? aoVivo;
    }
    return emCache;
  }
}

Future<CatalogoFake> abrirSheet(WidgetTester tester) async {
  final repo = CatalogoFake();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(repo),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModelSheet(context, ref),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final element = tester.element(find.text('abrir'));
  final container = ProviderScope.containerOf(element);
  await container
      .read(chatControllerProvider.notifier)
      .openConversation((await repo.listConversations()).first);
  await tester.pumpAndSettle();

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('a abertura usa o cache, e só o gesto busca ao vivo', (
    tester,
  ) async {
    final repo = await abrirSheet(tester);

    expect(repo.inventarios, [
      false,
    ], reason: 'abrir não pode pagar a busca ao vivo');

    await tester.tap(find.byKey(const ValueKey('atualizar-catalogo')));
    await tester.pumpAndSettle();

    expect(repo.inventarios, [false, true]);
    expect(
      find.byKey(const ValueKey('modelo-nous-hermes-5-preview')),
      findsOneWidget,
      reason: 'o catálogo ao vivo traz o que o cache não tinha',
    );
  });

  testWidgets('cada modelo mostra preço e o que aceita', (tester) async {
    await abrirSheet(tester);

    expect(find.textContaining('grátis'), findsWidgets);
    expect(find.textContaining(r'in $3.00'), findsOneWidget);
    expect(find.textContaining('rápido'), findsOneWidget);
    expect(find.textContaining('raciocínio'), findsWidgets);
  });

  testWidgets('modelo que a conta não pode escolher não vira toque', (
    tester,
  ) async {
    final repo = await abrirSheet(tester);

    expect(
      find.textContaining('indisponível no plano gratuito'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('modelo-nous-hermes-4-405b')));
    await tester.pumpAndSettle();

    expect(
      repo.travas,
      isEmpty,
      reason:
          'oferecer um botão que o backend recusaria é pior que não oferecer',
    );
  });

  testWidgets('provider não configurado diz o que falta', (tester) async {
    await abrirSheet(tester);

    await tester.ensureVisible(find.text('Anthropic').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anthropic').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('provider-falta-anthropic')),
      findsOneWidget,
    );
    expect(find.textContaining('ANTHROPIC_API_KEY'), findsWidgets);
  });

  testWidgets('atualização que falha não apaga o catálogo que já estava bom', (
    tester,
  ) async {
    final repo = await abrirSheet(tester);
    repo.falhaAoAtualizar = const HermesFailure(HermesFailureKind.semRede);

    await tester.tap(find.byKey(const ValueKey('atualizar-catalogo')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('inventario-falha-atualizar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('modelo-nous-hermes-4-70b')),
      findsOneWidget,
      reason:
          'perder a lista inteira por causa de uma tentativa de melhorá-la seria pior',
    );
  });
}

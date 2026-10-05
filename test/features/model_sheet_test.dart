import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/hermes_provider.dart';
import 'package:hermes_mobile/domain/models/model_options.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/widgets/sheets.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';

/// A21.2: escolher modelo passou a falar com o servidor
/// (`POST /api/sessions/{id}/model`). O caso que importa é a recusa: o Hermes
/// devolve `409 model_lock_unavailable` em vez de cair no modelo global, e essa
/// recusa tem de chegar à tela em vez de virar troca silenciosa.
class InventarioFake extends FakeHermesRepository {
  InventarioFake();

  @override
  Future<ModelOptions> modelOptions({bool refresh = false}) async =>
      const ModelOptions(
        model: 'gpt-5.6-terra',
        provider: 'openai-codex',
        providers: [
          HermesProvider(
            id: 'openai-codex',
            name: 'OpenAI Codex',
            models: ['gpt-5.6-terra', 'gpt-5.5'],
            totalModels: 2,
            isCurrent: true,
            authenticated: true,
          ),
          HermesProvider(
            id: 'anthropic',
            name: 'Anthropic',
            models: ['claude-opus-5'],
            totalModels: 1,
            authenticated: false,
          ),
        ],
      );
}

/// Abre o sheet com uma conversa de verdade aberta no controller: escolher
/// modelo só faz sentido com sessão, porque é a sessão que recebe a trava.
Future<InventarioFake> abrirSheet(WidgetTester tester) async {
  final repo = InventarioFake();
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
  testWidgets('oferece os modelos dos providers conectados', (tester) async {
    await abrirSheet(tester);

    // O provider atual está conectado, então seus modelos viram linha
    // escolhível, com chave própria.
    expect(
      find.byKey(const ValueKey('modelo-openai-codex-gpt-5.6-terra')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('modelo-openai-codex-gpt-5.5')),
      findsOneWidget,
    );
    // O alias de compatibilidade não é oferecido como se fosse um LLM.
    expect(find.text('hermes-agent'), findsNothing);
  });

  testWidgets('provider não conectado não vira opção escolhível', (
    tester,
  ) async {
    await abrirSheet(tester);

    // Aparece no inventário informativo, mas não como linha selecionável: uma
    // escolha que falharia no envio é pior que uma escolha ausente.
    expect(
      find.byKey(const ValueKey('modelo-anthropic-claude-opus-5')),
      findsNothing,
    );
  });

  testWidgets('escolha aceita fecha o sheet e trava a sessão', (tester) async {
    final repo = await abrirSheet(tester);

    await tester.tap(find.byKey(const ValueKey('modelo-openai-codex-gpt-5.5')));
    await tester.pumpAndSettle();

    expect(repo.travas.single.model, 'gpt-5.5');
    expect(repo.travas.single.provider, 'openai-codex');
    expect(
      find.byKey(const ValueKey('modelo-openai-codex-gpt-5.5')),
      findsNothing,
      reason: 'o sheet fecha ao aceitar',
    );
  });

  testWidgets('recusa mantém o sheet aberto e diz o motivo', (tester) async {
    final repo = await abrirSheet(tester);
    repo.recusa.add('openai-codex/gpt-5.5');

    await tester.tap(find.byKey(const ValueKey('modelo-openai-codex-gpt-5.5')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('recusou'),
      findsOneWidget,
      reason:
          'a recusa do servidor tem de aparecer, não virar troca silenciosa',
    );
    expect(
      find.byKey(const ValueKey('modelo-openai-codex-gpt-5.5')),
      findsOneWidget,
      reason:
          'fechar esconderia a recusa: o usuário sairia achando que escolheu',
    );
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/features/chat/chat_drafts_provider.dart';

void main() {
  test('mantém rascunhos independentes por sessionId', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final drafts = container.read(chatDraftsProvider.notifier);

    drafts.update('session-1', 'Primeiro rascunho');
    drafts.update('session-2', 'Segundo rascunho');

    expect(drafts.draftFor('session-1'), 'Primeiro rascunho');
    expect(drafts.draftFor('session-2'), 'Segundo rascunho');
    expect(drafts.draftFor('session-3'), isEmpty);
  });

  test('apagar o texto ou limpar remove somente a conversa escolhida', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final drafts = container.read(chatDraftsProvider.notifier);

    drafts.update('session-1', 'Descartar');
    drafts.update('session-2', 'Preservar');
    drafts.update('session-1', '');

    expect(drafts.draftFor('session-1'), isEmpty);
    expect(drafts.draftFor('session-2'), 'Preservar');

    drafts.clear('session-2');
    expect(container.read(chatDraftsProvider), isEmpty);
  });
}

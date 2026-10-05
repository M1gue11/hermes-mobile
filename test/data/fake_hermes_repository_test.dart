import 'package:flutter_test/flutter_test.dart';

import '../support/fake_hermes_repository.dart';

void main() {
  test('fake de teste cria sessão persistida', () async {
    final repository = FakeHermesRepository();
    final conversation = await repository.createConversation(model: 'hermes-agent');

    expect(conversation.id, isNotEmpty);
    expect(conversation.model, 'hermes-agent');
    expect(await repository.conversationMessages(conversation.id), isEmpty);
  });
}

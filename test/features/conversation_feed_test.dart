import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/features/chat/conversations_provider.dart';

import '../support/fake_hermes_repository.dart';

void main() {
  group('ConversationFeed', () {
    test('pagina sessões reais e reaplica a origem no repositório', () async {
      final conversations = List<Conversation>.generate(
        51,
        (index) => Conversation(
          id: 'session-$index',
          title: 'Conversa $index',
          source: index.isEven ? 'telegram' : 'api_server',
          lastActive: DateTime.utc(2026, 7, 15, 9, index % 60),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          hermesRepositoryProvider.overrideWithValue(
            FakeHermesRepository(conversations: conversations),
          ),
        ],
      );
      addTearDown(container.dispose);

      final firstPage = await container.read(conversationFeedProvider.future);
      expect(firstPage.items, hasLength(50));
      expect(firstPage.hasMore, isTrue);
      expect(firstPage.knownSources, containsAll(['telegram', 'api_server']));

      await container.read(conversationFeedProvider.notifier).loadMore();
      final loaded = _feed(container);
      expect(loaded.items, hasLength(51));
      expect(loaded.hasMore, isFalse);

      await container
          .read(conversationFeedProvider.notifier)
          .selectSource('telegram');
      final filtered = _feed(container);
      expect(filtered.selectedSource, 'telegram');
      expect(filtered.items, isNotEmpty);
      expect(filtered.items.every((item) => item.source == 'telegram'), isTrue);
    });
  });
}

ConversationFeedState _feed(ProviderContainer container) {
  return container
      .read(conversationFeedProvider)
      .maybeWhen(
        data: (state) => state,
        orElse: () => throw StateError('Feed não ficou disponível.'),
      );
}

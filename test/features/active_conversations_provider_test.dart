import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/active_run_store.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';

void main() {
  test(
    'limpeza durante restore não deixa indicador obsoleto reaparecer',
    () async {
      final store = _DelayedActiveRunStore();
      final container = ProviderContainer(
        overrides: [activeRunStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(container.read(activeConversationIdsProvider), isEmpty);
      container
          .read(activeConversationIdsProvider.notifier)
          .markInactive('session-1');
      store.restored.complete({'session-1'});
      await Future<void>.delayed(Duration.zero);

      expect(container.read(activeConversationIdsProvider), isEmpty);
    },
  );
}

class _DelayedActiveRunStore implements ActiveRunStore {
  final Completer<Set<String>> restored = Completer<Set<String>>();

  @override
  Future<Set<String>> activeSessionIds() => restored.future;

  @override
  Future<void> clear(String sessionId) async {}

  @override
  Future<ActiveRunRecord?> read(String sessionId) async => null;

  @override
  Future<void> save(ActiveRunRecord record) async {}
}

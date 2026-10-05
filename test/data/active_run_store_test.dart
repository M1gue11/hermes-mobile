import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/active_run_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('persiste, restaura e limpa a run por sessão', () async {
    const store = SecureActiveRunStore();
    final record = ActiveRunRecord(
      sessionId: 'session-1',
      runId: 'run-7',
      assistantMessageId: 'assistant-local',
      startedAt: DateTime.utc(2026, 8, 9, 12, 34),
      model: 'hermes-agent',
    );

    await store.save(record);

    expect(await store.activeSessionIds(), {'session-1'});

    final restored = await store.read('session-1');
    expect(restored?.runId, 'run-7');
    expect(restored?.assistantMessageId, 'assistant-local');
    expect(restored?.startedAt, DateTime.utc(2026, 8, 9, 12, 34));
    expect(restored?.model, 'hermes-agent');
    expect(restored?.transport, ActiveTurnTransport.runs);

    await store.clear('session-1');
    expect(await store.read('session-1'), isNull);
  });

  test(
    'persiste transporte Dashboard e mantém registros v1 como Runs',
    () async {
      const store = SecureActiveRunStore();
      await store.save(
        ActiveRunRecord(
          sessionId: 'dashboard-session',
          runId: 'gateway:live-1',
          assistantMessageId: 'assistant-live',
          startedAt: DateTime.utc(2026, 8, 10),
          transport: ActiveTurnTransport.dashboard,
        ),
      );
      expect(
        (await store.read('dashboard-session'))?.transport,
        ActiveTurnTransport.dashboard,
      );

      FlutterSecureStorage.setMockInitialValues({
        'hermes.active_run.legacy': jsonEncode({
          'version': 1,
          'session_id': 'legacy',
          'run_id': 'run-1',
          'assistant_message_id': 'assistant-1',
          'started_at': '2026-08-09T00:00:00.000Z',
        }),
      });
      expect((await store.read('legacy'))?.transport, ActiveTurnTransport.runs);
    },
  );

  test('registro inválido não derruba a inicialização', () async {
    FlutterSecureStorage.setMockInitialValues({
      'hermes.active_run.session-1': '{incompleto',
    });

    expect(await const SecureActiveRunStore().read('session-1'), isNull);
    expect(await const SecureActiveRunStore().activeSessionIds(), isEmpty);
  });
}

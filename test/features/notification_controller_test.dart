import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/operational_notice.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/notifications/notification_inbox.dart';
import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import '../support/notice_clock.dart';

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 2000; i++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condição não atingida');
}

void main() {
  late NoticeClock clock;
  late NotificationInbox inbox;
  late ProviderContainer container;
  ProviderContainer setup(
    FakeHermesRepository repository, {
    FakeGatewayRepository? gateway,
  }) {
    clock = NoticeClock();
    inbox = NotificationInbox(now: clock.now, timer: clock.timer);
    container = ProviderContainer(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(repository),
        gatewayRepositoryProvider.overrideWithValue(
          gateway ?? FakeGatewayRepository(paired: false),
        ),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        notificationInboxProvider.overrideWithValue(inbox),
        runReconciliationDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(() {
      container.dispose();
      inbox.dispose();
    });
    return container;
  }

  test(
    'show/clear isolados da fala; status/tool/thinking/reasoning não vazam',
    () async {
      final stream = ControlledRunStream();
      setup(FakeHermesRepository(controlledStreams: [stream]));
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      final durable = container.read(chatControllerProvider).sessionId!;
      await controller.send('Prompt neutro');
      await until(() => stream.hasListener);
      stream.add(
        const RunEvent.operational(
          NoticeShow(
            id: 'real',
            key: 'key',
            kind: 'custom',
            level: NoticeLevel.info,
            text: 'Aviso neutro',
          ),
        ),
      );
      stream.add(const RunEvent.thinkingState('privado neutro'));
      stream.add(const RunEvent.reasoningDelta('privado neutro'));
      stream.add(const RunEvent.activityPreview('privado neutro'));
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(name: 'read_file', arg: 'privado neutro'),
        ),
      );
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries.every((e) => e.sessionId == durable), isTrue);
      expect(
        inbox.entries.any((e) => e.text == 'Ferramentas em andamento.'),
        isTrue,
      );
      stream.add(const RunEvent.status(RunStatus.running));
      clock.advance(NotificationInbox.progressDelay);
      expect(
        inbox.entries.where((e) => e.origin == 'Execução').single.text,
        'Execução em andamento.',
      );
      // Within one window the latest generic signal wins.
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(name: 'read_file', arg: 'privado neutro'),
        ),
      );
      stream.add(const RunEvent.status(RunStatus.running));
      expect(clock.activeTimers, 0);
      clock.advance(NotificationInbox.progressDelay);
      expect(
        inbox.entries.where((e) => e.origin == 'Execução').single.text,
        'Execução em andamento.',
      );
      expect(
        inbox.entries.map((e) => e.text).join(),
        isNot(contains('privado neutro')),
      );
      expect(
        container.read(chatControllerProvider).messages.last.toString(),
        isNot(contains('Aviso neutro')),
      );
      stream.add(const RunEvent.operational(NoticeClear(key: 'key')));
      stream.add(const RunEvent.operational(NoticeClear(key: 'key')));
      expect(
        inbox.entries.where((e) => e.category == NoticeCategory.custom),
        isEmpty,
      );
      stream.add(const RunEvent.completed(output: 'Resposta neutra'));
      expect(
        inbox.entries.where((e) => e.origin == 'Execução').single.text,
        'Execução concluída.',
      );
    },
  );

  for (final terminal in [
    const RunEvent.completed(output: 'Resposta neutra'),
    const RunEvent.failed(error: 'privado neutro'),
    const RunEvent.status(RunStatus.cancelled),
  ]) {
    test(
      'terminal ${terminal.runtimeType} cancela throttle sem corpo privado',
      () async {
        final stream = ControlledRunStream();
        setup(FakeHermesRepository(controlledStreams: [stream]));
        final controller = container.read(chatControllerProvider.notifier);
        await controller.newChat();
        await controller.send('Prompt neutro');
        stream.add(terminal);
        clock.advance(NotificationInbox.progressDelay);
        expect(inbox.entries, hasLength(1));
        expect(
          inbox.entries.single.category,
          terminal is RunFailed
              ? NoticeCategory.error
              : NoticeCategory.completion,
        );
        expect(inbox.entries.single.text, isNot(contains('privado neutro')));
        expect(clock.activeTimers, 0);
      },
    );
  }

  test(
    'cancel local aceito é genérico e final posterior não duplica',
    () async {
      final stream = ControlledRunStream();
      setup(FakeHermesRepository(controlledStreams: [stream]));
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      await controller.send('Prompt neutro');
      await controller.stop();
      expect(inbox.entries.single.text, 'Interrupção solicitada.');
      stream.add(const RunEvent.status(RunStatus.cancelled));
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries, hasLength(1));
      expect(inbox.entries.single.text, 'Execução interrompida.');
    },
  );

  test(
    'five observation failures retain active run and completed resume replaces error',
    () async {
      final stream = ControlledRunStream();
      setup(
        FakeHermesRepository(
          controlledStreams: [stream],
          runSnapshotResults: [
            for (var i = 0; i < 5; i++) Exception('private snapshot error'),
            const Run(
              runId: 'run-1',
              status: RunStatus.completed,
              output: 'Resposta',
            ),
          ],
        ),
      );
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      await controller.send('Prompt neutro');
      stream.close();
      await until(() => !container.read(chatControllerProvider).streaming);
      expect(
        inbox.entries.single.text,
        'Não foi possível acompanhar a execução.',
      );
      await controller.setLiveUpdatesVisible(false);
      await controller.setLiveUpdatesVisible(true);
      expect(inbox.entries.single.text, 'Execução concluída.');
      expect(stream.listenCount, 1);
    },
  );
  test('snapshot terminal após queda cancela progress e não reenvia', () async {
    final stream = ControlledRunStream();
    setup(
      FakeHermesRepository(
        controlledStreams: [stream],
        runSnapshots: [
          const Run(
            runId: 'run-1',
            status: RunStatus.failed,
            error: 'privado neutro',
          ),
        ],
      ),
    );
    final controller = container.read(chatControllerProvider.notifier);
    await controller.newChat();
    await controller.send('Prompt neutro');
    stream.close();
    await until(() => !container.read(chatControllerProvider).streaming);
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.single.text, 'A execução falhou.');
    expect(stream.listenCount, 1);
  });

  for (final status in [RunStatus.completed, RunStatus.cancelled]) {
    test('snapshot $status após queda mapeia conclusão/interrupção', () async {
      final stream = ControlledRunStream();
      setup(
        FakeHermesRepository(
          controlledStreams: [stream],
          runSnapshots: [
            Run(runId: 'run-1', status: status, output: 'Resposta neutra'),
          ],
        ),
      );
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      await controller.send('Prompt neutro');
      stream.close();
      await until(() => !container.read(chatControllerProvider).streaming);
      clock.advance(NotificationInbox.progressDelay);
      expect(
        inbox.entries.single.text,
        status == RunStatus.cancelled
            ? 'Execução interrompida.'
            : 'Execução concluída.',
      );
    });
  }

  test(
    'troca de sessão e epoch bloqueiam callbacks atrasados e pending',
    () async {
      final stream = ControlledRunStream();
      setup(FakeHermesRepository(controlledStreams: [stream]));
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      await controller.send('Prompt neutro');
      stream.add(
        const RunEvent.operational(
          NoticeSignal(type: 'subagent.progress', taskId: 'a'),
        ),
      );
      await controller.openConversation(
        const Conversation(id: 'other', title: 'Neutra'),
      );
      stream.add(
        const RunEvent.operational(
          NoticeShow(
            key: 'key',
            kind: 'custom',
            level: NoticeLevel.info,
            text: 'Atrasado',
          ),
        ),
      );
      stream.add(const RunEvent.failed(error: 'Atrasado'));
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries, isEmpty);
      expect(container.read(chatControllerProvider).sessionId, 'other');
    },
  );

  test(
    'ocultar, retomar snapshot e dispose respeitam listenerGeneration',
    () async {
      final stream = ControlledRunStream();
      setup(
        FakeHermesRepository(
          controlledStreams: [stream],
          runSnapshots: [
            const Run(
              runId: 'run-1',
              status: RunStatus.completed,
              output: 'Resposta neutra',
            ),
          ],
        ),
      );
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      await controller.send('Prompt neutro');
      await controller.setLiveUpdatesVisible(false);
      stream.add(
        const RunEvent.operational(
          NoticeShow(
            key: 'key',
            kind: 'custom',
            level: NoticeLevel.info,
            text: 'Atrasado',
          ),
        ),
      );
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries, isEmpty);
      await controller.setLiveUpdatesVisible(true);
      expect(inbox.entries.single.text, 'Execução concluída.');
      expect(stream.listenCount, 1);
      // O dispose do controller cancela pending mesmo com a inbox viva no escopo.
      inbox.run('other', 'r', NoticeCategory.progress);
      container.invalidate(chatControllerProvider);
      stream.add(
        const RunEvent.operational(
          NoticeShow(
            key: 'late',
            kind: 'custom',
            level: NoticeLevel.info,
            text: 'Callback depois de dispose',
          ),
        ),
      );
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries, hasLength(1));
    },
  );

  test(
    'mute no controller bloqueia custom e subagent pending imediatamente',
    () async {
      final stream = ControlledRunStream();
      setup(FakeHermesRepository(controlledStreams: [stream]));
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      await controller.send('Prompt neutro');
      stream.add(
        const RunEvent.operational(
          NoticeSignal(type: 'subagent.start', taskId: 'a'),
        ),
      );
      inbox.setEnabled(NoticeCategory.progress, false);
      inbox.setEnabled(NoticeCategory.custom, false);
      stream.add(
        const RunEvent.operational(
          NoticeShow(
            key: 'k',
            kind: 'custom',
            level: NoticeLevel.info,
            text: 'Aviso silenciado',
          ),
        ),
      );
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries, isEmpty);
      stream.add(
        const RunEvent.operational(
          NoticeSignal(type: 'subagent.complete', taskId: 'a'),
        ),
      );
      expect(inbox.entries.single.text, 'Delegação encerrada.');
    },
  );

  test(
    'reconnect TUI preserva dedupe e contexto durável sem novo submit',
    () async {
      final first = FakeGatewayLiveTurn(
        storedSessionId: 'session-2',
        liveSessionId: 'live-1',
      );
      final second = FakeGatewayLiveTurn(
        storedSessionId: 'session-2',
        liveSessionId: 'live-2',
      );
      final gateway = FakeGatewayRepository(turns: [first, second]);
      setup(FakeHermesRepository(), gateway: gateway);
      final controller = container.read(chatControllerProvider.notifier);
      await controller.newChat();
      final durable = container.read(chatControllerProvider).sessionId!;
      await controller.send('Prompt neutro');
      const notice = RunEvent.operational(
        NoticeShow(
          id: 'real',
          seq: 1,
          key: 'key',
          kind: 'custom',
          level: NoticeLevel.info,
          text: 'Aviso neutro',
        ),
      );
      first.add(notice);
      inbox.markRead(inbox.entries.single.localId);
      first.addError(StateError('queda neutra'));
      await until(
        () =>
            gateway.openedSessionIds.length == 2 &&
            container.read(chatControllerProvider).runId == second.turnId,
      );
      await Future<void>.delayed(Duration.zero);
      second.add(notice);
      expect(inbox.entries.single.read, isTrue);
      expect(inbox.entries.single.sessionId, durable);
      expect(second.submitted, isEmpty);
      second.add(const RunEvent.completed(output: 'Resposta neutra'));
      expect(inbox.entries.where((e) => e.origin == 'Execução'), hasLength(1));
    },
  );
}

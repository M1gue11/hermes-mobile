import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/operational_notice.dart';
import 'package:hermes_mobile/features/notifications/notification_inbox.dart';
import '../support/notice_clock.dart';

NoticeShow show({
  String? id,
  String? key = 'key',
  int? seq,
  int? ttl,
  String text = 'Aviso neutro',
  NoticeSeqScope? scope,
}) => NoticeShow(
  id: id,
  key: key,
  seq: seq,
  seqScope: scope,
  kind: 'custom',
  level: NoticeLevel.info,
  text: text,
  ttlMs: ttl,
);

void main() {
  late NoticeClock clock;
  late NotificationInbox inbox;
  setUp(() {
    clock = NoticeClock();
    inbox = NotificationInbox(now: clock.now, timer: clock.timer);
  });
  tearDown(() => inbox.dispose());
  test(
    'seq scopes separate live sessions, epochs and local reconnects; show ID is reusable',
    () {
      NoticeSeqScope scope(String live, int epoch) =>
          (sessionId: live, replayEpoch: epoch, localConnection: null);
      NoticeShow scoped(String id, NoticeSeqScope identity) => NoticeShow(
        id: id,
        key: id,
        seq: 1,
        seqScope: identity,
        kind: 'agent',
        level: NoticeLevel.info,
        text: 'Aviso',
      );
      inbox.accept('s', 'same-message', scoped('a', scope('live1', 1)));
      inbox.accept('s', 'same-message', scoped('b', scope('live2', 1)));
      inbox.accept('s', 'same-message', scoped('c', scope('live2', 2)));
      inbox.accept('s', 'same-message', scoped('duplicate', scope('live2', 2)));
      inbox.accept('s', 'same-message', scoped('a', scope('live3', 3)));
      expect(inbox.entries, hasLength(3));
      inbox.accept(
        's',
        'same-message',
        NoticeClear(key: 'a', seq: 1, seqScope: scope('live4', 2)),
      );
      expect(inbox.entries, hasLength(2));
      for (final token in [Object(), Object()]) {
        inbox.accept(
          's',
          'same-message',
          NoticeShow(
            seq: 1,
            seqScope: (
              sessionId: null,
              replayEpoch: null,
              localConnection: token,
            ),
            kind: 'agent',
            level: NoticeLevel.info,
            text: 'Local',
          ),
        );
      }
      expect(inbox.entries, hasLength(4));
    },
  );
  test(
    'keyless slots use real ID or separate local identity; clear only real key',
    () {
      const anonymous = NoticeShow(
        kind: 'agent',
        level: NoticeLevel.info,
        text: 'Aviso',
      );
      inbox.accept('s', 'r', anonymous);
      inbox.accept('s', 'r', anonymous);
      inbox.accept(
        's',
        'r',
        const NoticeShow(
          id: 'id',
          kind: 'agent',
          level: NoticeLevel.info,
          text: 'ID',
        ),
      );
      inbox.accept('s', 'r', show(key: 'id'));
      inbox.accept('s', 'r', const NoticeClear(key: 'id'));
      expect(inbox.entries, hasLength(3));
      expect(inbox.entries.every((e) => e.key == null), isTrue);
    },
  );
  test(
    'observer error is provisional; useful progress preserves read and terminal replaces it',
    () {
      inbox.run('s', 'r', NoticeCategory.error, observerError: true);
      expect(
        inbox.entries.single.text,
        'Não foi possível acompanhar a execução.',
      );
      inbox.run('s', 'r', NoticeCategory.progress, toolsInProgress: true);
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries.single.text, 'Ferramentas em andamento.');
      inbox.markRead(inbox.entries.single.localId);
      for (var i = 0; i < 10; i++) {
        inbox.run('s', 'r', NoticeCategory.progress, toolsInProgress: true);
      }
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.unread, 0);
      inbox.run('s', 'r', NoticeCategory.completion);
      expect(inbox.entries.single.text, 'Execução concluída.');
      expect(clock.activeTimers, 0);
    },
  );
  test('show ID reutilizável: updates, clear idempotente e replay seq', () {
    inbox.accept('s', 'r', show(id: 'real', seq: 1));
    inbox.accept('s', 'r', show(id: 'real', seq: 2, text: 'Atualizado'));
    expect(inbox.entries.single.text, 'Atualizado');
    inbox.accept('s', 'r', const NoticeClear(key: 'key'));
    inbox.accept('s', 'r', const NoticeClear(key: 'key'));
    expect(inbox.entries, isEmpty);
    inbox.accept('s', 'r', show(id: 'real', seq: 2, text: 'Atualizado'));
    expect(inbox.entries, isEmpty);
    inbox.accept('s', 'r', show(id: 'real', seq: 3));
    expect(inbox.entries.single.serverId, 'real');
    inbox.accept('s', 'r', const NoticeClear(key: 'key'));
    expect(inbox.entries, isEmpty);
    inbox.accept('s2', 'r', show(id: 'real', seq: 3));
    expect(inbox.entries.single.sessionId, 's2');
  });
  test('TTL e remoção permitem reemissão; seq antigo continua deduped', () {
    inbox.accept('s', 'r', show(id: 'real', seq: 1, ttl: 100));
    clock.advance(const Duration(milliseconds: 100));
    inbox.accept('s', 'r', show(id: 'real', seq: 1, ttl: 100));
    expect(inbox.entries, isEmpty);
    inbox.accept('s', 'r', show(id: 'real', seq: 2, ttl: 100));
    expect(inbox.entries, hasLength(1));
    inbox.remove(inbox.entries.single.localId);
    inbox.accept('s', 'r', show(id: 'real', seq: 3));
    expect(inbox.entries, hasLength(1));
  });
  for (final key in ['key', null]) {
    test('sem seq dedupe ativo por payload e reemissão key=$key', () {
      inbox.accept('s', 'r', show(id: 'real', key: key, ttl: 100));
      final localId = inbox.entries.single.localId;
      inbox.markRead(localId);
      inbox.accept('s', 'r', show(id: 'real', key: key, ttl: 100));
      expect(inbox.entries.single.localId, localId);
      expect(inbox.unread, 0);
      inbox.accept(
        's',
        'r',
        show(id: 'real', key: key, ttl: 100, text: 'Novo'),
      );
      expect(inbox.entries.single.text, 'Novo');
      expect(inbox.entries.single.serverId, 'real');
      expect(inbox.unread, 1);
      clock.advance(const Duration(milliseconds: 100));
      inbox.accept('s', 'r', show(id: 'real', key: key, ttl: 100));
      expect(inbox.entries, hasLength(1));
      if (key != null) {
        inbox.accept('s', 'r', NoticeClear(key: key));
        inbox.accept('s', 'r', show(id: 'real', key: key, ttl: 100));
        expect(inbox.entries, hasLength(1));
      }
    });
  }
  for (final read in [false, true]) {
    test('último publicado cancela pending e preserva read=$read/localId', () {
      inbox.run('s', 'r', NoticeCategory.progress, toolsInProgress: true);
      clock.advance(NotificationInbox.progressDelay);
      final id = inbox.entries.single.localId;
      if (read) inbox.markRead(id);
      inbox.run('s', 'r', NoticeCategory.progress, inProgress: true);
      inbox.run('s', 'r', NoticeCategory.progress, toolsInProgress: true);
      expect(clock.activeTimers, 0);
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries.single.localId, id);
      expect(inbox.entries.single.text, 'Ferramentas em andamento.');
      expect(inbox.unread, read ? 0 : 1);
    });
  }
  test('A B C mantém janela original e final cancela pending', () {
    inbox.run('s', 'r', NoticeCategory.progress);
    clock.advance(const Duration(milliseconds: 250));
    inbox.run('s', 'r', NoticeCategory.progress, toolsInProgress: true);
    clock.advance(const Duration(milliseconds: 250));
    inbox.run('s', 'r', NoticeCategory.progress, inProgress: true);
    expect(clock.activeTimers, 1);
    clock.advance(const Duration(milliseconds: 250));
    expect(inbox.entries.single.text, 'Execução em andamento.');
    inbox.run('s', 'r', NoticeCategory.progress, toolsInProgress: true);
    inbox.run('s', 'r', NoticeCategory.completion);
    expect(clock.activeTimers, 0);
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.single.text, 'Execução concluída.');
  });
  test('sem id não fabrica serverId; key mantém espaços e caixa', () {
    inbox.accept('s', 'r', show(key: ' X '));
    inbox.accept('s', 'r', show(key: 'x'));
    expect(inbox.entries, hasLength(2));
    expect(
      inbox.entries.every((e) => e.serverId == null && e.seq == null),
      isTrue,
    );
    inbox.accept('s', 'r', const NoticeClear(key: 'X'));
    expect(inbox.entries, hasLength(2));
  });
  test('TTL expira e substituição cancela timer anterior', () {
    inbox.accept('s', 'r', show(ttl: 100));
    clock.advance(const Duration(milliseconds: 50));
    inbox.accept('s', 'r', show(ttl: 200));
    expect(clock.activeTimers, 1);
    clock.advance(const Duration(milliseconds: 50));
    expect(inbox.entries, hasLength(1));
    clock.advance(const Duration(milliseconds: 150));
    expect(inbox.entries, isEmpty);
    expect(clock.activeTimers, 0);
    inbox.accept('s', 'r', show(ttl: 0));
    expect(inbox.entries, isEmpty);
    for (final ttl in [-1, 604800001, 9007199254740991]) {
      inbox.accept('s', 'r', show(ttl: ttl));
    }
    expect(inbox.entries, isEmpty);
  });
  test('TTL no limite de DateTime não causa overflow', () {
    clock.value = DateTime.fromMillisecondsSinceEpoch(
      8640000000000000,
      isUtc: true,
    );
    inbox.accept('s', 'r', show(ttl: 1));
    expect(inbox.entries, isEmpty);
  });
  test('flush agregado, corrida com final e conclusão idempotente', () {
    inbox.run('s', 'r', NoticeCategory.progress);
    inbox.run('s', 'r', NoticeCategory.progress);
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.single.text, 'Execução iniciada.');
    inbox.run('s', 'r', NoticeCategory.progress);
    inbox.run('s', 'r', NoticeCategory.completion);
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.single.text, 'Execução concluída.');
    inbox.run('s', 'r', NoticeCategory.progress);
    inbox.run('s', 'r', NoticeCategory.error);
    expect(clock.activeTimers, 0);
    expect(inbox.entries, hasLength(1));
  });
  test('final antes do throttle, erro e cancelamento genéricos', () {
    inbox.run('s', 'r', NoticeCategory.progress);
    inbox.run('s', 'r', NoticeCategory.error);
    inbox.run('s', 'r2', NoticeCategory.completion, cancelled: true);
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.map((e) => e.text), [
      'Execução interrompida.',
      'A execução falhou.',
    ]);
    expect(inbox.entries.first.level, NoticeLevel.info);
  });
  test(
    'pedido local de interrupção não inventa terminal nem vence final real',
    () {
      inbox.run('s', 'r', NoticeCategory.progress);
      inbox.run('s', 'r', NoticeCategory.completion, cancelRequested: true);
      expect(inbox.entries.single.text, 'Interrupção solicitada.');
      inbox.markRead(inbox.entries.single.localId);
      inbox.run('s', 'r', NoticeCategory.completion, cancelRequested: true);
      expect(inbox.unread, 0);
      inbox.run('s', 'r', NoticeCategory.progress);
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries.single.text, 'Interrupção solicitada.');
      inbox.run('s', 'r', NoticeCategory.completion);
      expect(inbox.entries.single.text, 'Execução concluída.');
      expect(inbox.unread, 1);
    },
  );
  test(
    'mute cancela pending imediatamente e não libera depois de reativar',
    () {
      inbox.run('s', 'r', NoticeCategory.progress);
      inbox.setEnabled(NoticeCategory.progress, false);
      inbox.setEnabled(NoticeCategory.progress, true);
      clock.advance(NotificationInbox.progressDelay);
      expect(inbox.entries, isEmpty);
      for (final category in NoticeCategory.values) {
        inbox.setEnabled(category, false);
      }
      inbox.accept('s', 'r', show());
      inbox.run('s', 'r', NoticeCategory.error);
      inbox.accept('s', 'r', const NoticeSignal(type: 'background.complete'));
      expect(inbox.entries, isEmpty);
      inbox.setEnabled(NoticeCategory.custom, true);
      inbox.accept('s', 'r', show());
      inbox.setEnabled(NoticeCategory.custom, false);
      inbox.accept('s', 'r', const NoticeClear(key: 'key'));
      expect(inbox.entries, isEmpty);
    },
  );
  test('subagents paralelos por IDs reais; sem id usa agregado separado', () {
    for (final id in ['a', 'b', null, null]) {
      inbox.accept(
        's',
        'r',
        NoticeSignal(type: 'subagent.progress', taskId: id),
      );
    }
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries, hasLength(3));
    inbox.accept(
      's',
      'r',
      const NoticeSignal(type: 'subagent.complete', taskId: 'a'),
    );
    inbox.accept(
      's',
      'r',
      const NoticeSignal(type: 'subagent.thinking', taskId: 'a'),
    );
    inbox.accept(
      's',
      'r',
      const NoticeSignal(type: 'subagent.tool', taskId: 'b'),
    );
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries, hasLength(3));
    expect(
      inbox.entries.where((e) => e.text == 'Delegação encerrada.'),
      hasLength(1),
    );
    inbox.run('s', 'r', NoticeCategory.completion);
    inbox.accept('s', 'r', const NoticeSignal(type: 'background.complete'));
    expect(inbox.entries.first.text, 'Trabalho em segundo plano concluído.');
  });
  test('terminal de subagent cancela progresso e erro não vira sucesso', () {
    inbox.accept(
      's',
      'r',
      const NoticeSignal(type: 'subagent.start', taskId: 'a'),
    );
    inbox.accept(
      's',
      'r',
      const NoticeSignal(
        type: 'subagent.complete',
        taskId: 'a',
        outcome: NoticeOutcome.failed,
      ),
    );
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.single.category, NoticeCategory.error);
    expect(inbox.entries.single.text, 'A delegação falhou.');
  });
  test('troca/ocultação descarta pending; dispose cancela todos timers', () {
    inbox.run('s1', 'r', NoticeCategory.progress);
    inbox.cancelPending();
    inbox.run('s2', 'r', NoticeCategory.progress);
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.single.sessionId, 's2');
    inbox.accept('s2', 'r', show(ttl: 100));
    inbox.run('s2', 'other', NoticeCategory.progress);
    inbox.dispose();
    expect(clock.activeTimers, 0);
    clock.advance(const Duration(seconds: 1));
    // Outra instância representa reabertura: inbox e preferências não persistem.
    inbox = NotificationInbox(now: clock.now, timer: clock.timer);
    expect(inbox.entries, isEmpty);
    expect(inbox.enabled(NoticeCategory.progress), isTrue);
  });
  test('entradas, pending e caches têm limites e evicção cancela TTL', () {
    for (var i = 0; i < 600; i++) {
      inbox.accept('s', 'r', show(id: '$i', key: '$i', seq: i, ttl: 10000));
      inbox.accept(
        's',
        'r',
        NoticeSignal(type: 'subagent.progress', taskId: '$i'),
      );
    }
    expect(inbox.entries.length, NotificationInbox.maxEntries);
    expect(
      clock.activeTimers,
      NotificationInbox.maxEntries + NotificationInbox.maxPending,
    );
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries.length, NotificationInbox.maxEntries);
    // Dedupe antigo evicto: cache não cresce para sempre.
    inbox.accept('s', 'r', show(id: '0', key: '0', seq: 0));
    expect(inbox.entries.first.serverId, '0');
  });
  test('deep link só usa sessão capturada com encodeComponent', () {
    inbox.accept('real /?#% sessão', 'r', show(key: '/ação-remota'));
    expect(
      inbox.entries.single.location,
      '/chat/${Uri.encodeComponent('real /?#% sessão')}',
    );
    expect(inbox.entries.single.location, isNot(contains('ação-remota')));
  });
  test('seq reinicia com live session e epoch reais distintos', () {
    inbox.accept(
      's',
      'r1',
      show(
        id: 'first',
        key: 'a',
        seq: 1,
        scope: (sessionId: 'live1', replayEpoch: 1, localConnection: null),
      ),
    );
    inbox.accept(
      's',
      'r2',
      show(
        id: 'second',
        key: 'b',
        seq: 1,
        scope: (sessionId: 'live2', replayEpoch: 2, localConnection: null),
      ),
    );
    expect(inbox.entries, hasLength(2));
  });
  test('turno local distinto sem metadata mantém mesmo ingress scope', () {
    inbox.accept('s', 'r1', show(id: 'first', key: 'a', seq: 1));
    inbox.accept('s', 'r2', show(id: 'second', key: 'b', seq: 1));
    expect(inbox.entries, hasLength(1));
  });
  test('signal desconhecido não produz aviso genérico', () {
    inbox.accept('s', 'r', const NoticeSignal(type: 'subagent.future'));
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.entries, isEmpty);
    expect(clock.activeTimers, 0);
  });
}

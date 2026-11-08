import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/push_notice.dart';

List<int> _bytes(Object value) => utf8.encode(jsonEncode(value));

void main() {
  group('PushNotice.tryParse', () {
    test('lê o envelope do plugin mobile-push', () {
      final notice = PushNotice.tryParse(
        _bytes({
          'v': 1,
          'id': 'abc',
          'kind': 'turn.completed',
          'session_id': ' sess-1 ',
          'title': 'Refatorar backup',
          'ts': 1762560000,
        }),
      )!;

      expect(notice.kind, PushNoticeKind.turnCompleted);
      expect(notice.sessionId, 'sess-1');
      expect(notice.title, 'Refatorar backup');
      expect(notice.sentAt, DateTime.utc(2025, 11, 8));
      expect(notice.slot, 'turn:sess-1');
    });

    test('pedido de entrada exige tipo e id; resolvido exige id', () {
      final request = PushNotice.tryParse(
        _bytes({
          'v': 1,
          'kind': 'input.requested',
          'session_id': 's',
          'input': 'sudo',
          'request_id': 'r1',
        }),
      )!;
      expect(request.input, PushInputKind.sudo);
      expect(request.slot, 'input:r1');
      expect(request.needsAttention, isTrue);

      expect(
        PushNotice.tryParse(
          _bytes({
            'v': 1,
            'kind': 'input.requested',
            'session_id': 's',
            'input': 'telepatia',
            'request_id': 'r1',
          }),
        ),
        isNull,
      );
      expect(
        PushNotice.tryParse(
          _bytes({'v': 1, 'kind': 'input.resolved', 'session_id': 's'}),
        ),
        isNull,
      );
      final resolved = PushNotice.tryParse(
        _bytes({
          'v': 1,
          'kind': 'input.resolved',
          'session_id': 's',
          'request_id': 'r1',
        }),
      )!;
      expect(resolved.clearsSlot, isTrue);
      expect(resolved.slot, request.slot);
    });

    test('teste não precisa de sessão', () {
      final notice = PushNotice.tryParse(_bytes({'v': 1, 'kind': 'test'}))!;
      expect(notice.kind, PushNoticeKind.test);
      expect(notice.slot, 'test');
    });

    test('recusa o que não entende em vez de inventar aviso', () {
      for (final body in [
        utf8.encode('não é json'),
        _bytes([1, 2]),
        _bytes({'v': 2, 'kind': 'turn.completed', 'session_id': 's'}),
        _bytes({'v': 1, 'kind': 'turn.exploded', 'session_id': 's'}),
        _bytes({'v': 1, 'kind': 'turn.failed'}),
        _bytes({'v': 1, 'kind': 'turn.failed', 'session_id': '  '}),
      ]) {
        expect(PushNotice.tryParse(body), isNull, reason: utf8.decode(body));
      }
    });
  });

  test('noticeSlotId é estável, positivo e cabe em 31 bits', () {
    expect(noticeSlotId('turn:sess-1'), noticeSlotId('turn:sess-1'));
    expect(noticeSlotId('turn:sess-1'), isNot(noticeSlotId('turn:sess-2')));
    // Valor fixo: muda só se o hash mudar, o que quebraria a substituição
    // entre o aviso do app aberto e o do isolate de background.
    expect(noticeSlotId(''), 0x811c9dc5 & 0x7fffffff);
    for (final slot in ['test', 'input:r1', 'turn:çãõ']) {
      expect(noticeSlotId(slot), inInclusiveRange(0, 0x7fffffff));
    }
  });
}

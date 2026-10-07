import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/operational_notice.dart';
import 'package:hermes_mobile/domain/models/gateway_rpc.dart';

void main() {
  Map<String, dynamic> show() => {
    'id': ' id real ',
    'key': ' chave real ',
    'kind': 'custom',
    'level': 'info',
    'text': 'Aviso neutro',
  };
  test('show preserva ids reais e ausência de campos opcionais', () {
    final notice =
        OperationalNotice.parse('notification.show', show()) as NoticeShow;
    expect(notice.id, ' id real ');
    expect(notice.key, ' chave real ');
    expect(notice.seq, isNull);
    expect(notice.ttlMs, isNull);
    final withoutId = show()..remove('id');
    expect(OperationalNotice.parse('notification.show', withoutId)!.id, isNull);
    final long = show()..['text'] = List.filled(1100, '🌿').join();
    expect(
      (OperationalNotice.parse('notification.show', long) as NoticeShow)
          .text
          .runes
          .length,
      1000,
    );
  });
  test('malformados, TTL inválido e tipo desconhecido são ignorados', () {
    for (final ttl in [-1, 1.5, '100', 604800001, 9007199254740991]) {
      expect(
        OperationalNotice.parse('notification.show', show()..['ttl_ms'] = ttl),
        isNull,
      );
    }
    for (final field in ['id', 'key', 'kind', 'level', 'text']) {
      expect(
        OperationalNotice.parse('notification.show', show()..[field] = 42),
        isNull,
      );
    }
    expect(
      OperationalNotice.parse(
        'notification.show',
        show()..['level'] = 'unknown',
      ),
      isNull,
    );
    expect(OperationalNotice.parse('notification.future', show()), isNull);
    expect(OperationalNotice.parse('notification.clear', {'key': 7}), isNull);
    expect(
      OperationalNotice.parse('notification.clear', {'key': ' x '})
          is NoticeClear,
      isTrue,
    );
    expect(
      OperationalNotice.parse('notification.show', show(), seq: -1),
      isNull,
    );
    expect(
      OperationalNotice.parse('notification.show', show()..['ttl_ms'] = 0),
      isA<NoticeShow>(),
    );
  });
  test(
    'subagent e background retêm somente identificadores e outcome seguro',
    () {
      for (final type in [
        'subagent.spawn_requested',
        'subagent.start',
        'subagent.thinking',
        'subagent.tool',
        'subagent.progress',
        'subagent.complete',
        'background.complete',
      ]) {
        final notice =
            OperationalNotice.parse(type, {
                  'subagent_id': ' real ',
                  'task_id': ' task ',
                  'status': 'error',
                  'goal': 'conteúdo privado neutro',
                  'text': 'conteúdo privado neutro',
                  'summary': 'conteúdo privado neutro',
                  'tool_preview': 'conteúdo privado neutro',
                })
                as NoticeSignal;
        expect(
          notice.taskId,
          type == 'background.complete' ? ' task ' : ' real ',
        );
        expect(
          notice.outcome,
          type == 'subagent.complete' ? NoticeOutcome.failed : isNull,
        );
        expect(notice.id, isNull);
        expect(notice.toString(), isNot(contains('conteúdo privado neutro')));
      }
      expect(
        (OperationalNotice.parse('subagent.progress', {}) as NoticeSignal)
            .taskId,
        isNull,
      );
      expect(
        OperationalNotice.parse('subagent.start', {'subagent_id': 1}),
        isNull,
      );
    },
  );
  test('producer nulls, warn, keyless and timeout', () {
    final notice =
        OperationalNotice.parse('notification.show', {
              'id': null,
              'key': null,
              'ttl_ms': null,
              'kind': 'agent',
              'level': 'warn',
              'text': 'Aviso',
            })
            as NoticeShow;
    expect(notice.key, isNull);
    expect(notice.level, NoticeLevel.warning);
    expect(
      (OperationalNotice.parse('subagent.complete', {
                'subagent_id': null,
                'status': 'timeout',
              })
              as NoticeSignal)
          .outcome,
      NoticeOutcome.failed,
    );
  });
  test('seq do envelope é opcional, nunca sintetizado', () {
    final frame =
        decodeGatewayFrame(
              '{"jsonrpc":"2.0","method":"event",'
              '"params":{"type":"notification.clear","seq":9,"payload":{"key":"k"}}}',
            )
            as GatewayEventFrame;
    expect(frame.seq, 9);
    expect(
      decodeGatewayFrame(
            '{"jsonrpc":"2.0","method":"event",'
            '"params":{"type":"notification.clear","payload":{"key":"k"}}}',
          )
          is GatewayEventFrame,
      isTrue,
    );
  });
}

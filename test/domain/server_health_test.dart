import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/server_health.dart';

void main() {
  test('linha de log separa carimbo, nível, origem e mensagem', () {
    final line = parseLogLine(
      '2026-11-02 10:00:01,123 WARNING [abc123] gateway.run: Fila cheia\n',
    );

    expect(line.at, DateTime(2026, 11, 2, 10, 0, 1, 123));
    expect(line.level, 'WARNING');
    expect(line.source, 'gateway.run');
    expect(line.message, 'Fila cheia');
    expect(line.continuation, isFalse);
  });

  test('traceback fica colado ao registro que o originou', () {
    final entries = logEntriesFrom([
      '2026-11-02 10:00:00,000 INFO agent: começou\n',
      '2026-11-02 10:00:01,000 ERROR tools.web: falhou\n',
      'Traceback (most recent call last):\n',
      '  File "x.py", line 1\n',
    ]);

    expect(entries, hasLength(2));
    expect(entries.last.level, 'ERROR');
    expect(
      entries.last.message,
      'falhou\nTraceback (most recent call last):\n  File "x.py", line 1',
    );
  });

  test('voltou do reinício compara instantes do servidor', () {
    final before = GatewayRuntime(
      running: true,
      state: 'running',
      updatedAt: DateTime.utc(2026, 11, 2, 10),
    );
    final same = before;
    final later = before.copyWith(updatedAt: DateTime.utc(2026, 11, 2, 10, 1));
    final starting = later.copyWith(state: 'starting');

    expect(same.settledSince(before, sawDown: true), isFalse);
    expect(starting.settledSince(before, sawDown: true), isFalse);
    expect(later.settledSince(before, sawDown: false), isTrue);

    const semCarimbo = GatewayRuntime(running: true, state: 'running');
    expect(semCarimbo.settledSince(semCarimbo, sawDown: false), isFalse);
    expect(semCarimbo.settledSince(semCarimbo, sawDown: true), isTrue);
  });

  test('startup_failed é falha, estado ausente cai no running', () {
    expect(
      const GatewayRuntime(state: 'startup_failed').phase,
      GatewayPhase.failed,
    );
    expect(const GatewayRuntime(running: true).phase, GatewayPhase.running);
    expect(const GatewayRuntime().phase, GatewayPhase.unknown);
  });
}

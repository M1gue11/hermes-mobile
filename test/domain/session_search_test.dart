import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/session_search.dart';

void main() {
  test('trecho separa os termos que casaram', () {
    expect(snippetRuns('...falar do >>>backup<<< do\nvault e >>>backup<<<'), [
      (text: '...falar do ', match: false),
      (text: 'backup', match: true),
      (text: ' do vault e ', match: false),
      (text: 'backup', match: true),
    ]);
  });

  test('marca sem fechamento vira texto comum', () {
    expect(snippetRuns('sem >>>fim'), [(text: 'sem >>>fim', match: false)]);
    expect(snippetRuns('Session ID: abc'), [
      (text: 'Session ID: abc', match: false),
    ]);
  });
}

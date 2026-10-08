// Dependency-free executable regression suite, runnable when pub resolution
// or Flutter's local test server is unavailable. Failure throws, never asserts.
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_relative_lib_imports
import '../../../lib/domain/notifications/push_notice.dart';

Uint8List envelope([Map<String, dynamic> overrides = const {}]) =>
    Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': 1,
          'event_id': 'event_1',
          'category': 'completion',
          'summary': 'Trabalho concluído',
          ...overrides,
        }),
      ),
    );

void check(bool condition, String label) {
  if (!condition) throw StateError(label);
}

void main() {
  check(PushNotice.parse(envelope(), decrypted: true) != null, 'valid');
  check(PushNotice.parse(envelope(), decrypted: false) == null, 'undecrypted');
  check(
    PushNotice.parse(Uint8List.fromList([255]), decrypted: true) == null,
    'utf8',
  );
  check(PushNotice.parse(Uint8List(1025), decrypted: true) == null, 'bytes');
  check(
    PushNotice.parse(
          Uint8List.fromList(utf8.encode(' ' * 513)),
          decrypted: true,
        ) ==
        null,
    'codepoints',
  );
  for (final field in [
    'prompt',
    'result',
    'reasoning',
    'url',
    'action',
    'raw_payload',
    'route',
    'unknown',
  ]) {
    check(
      PushNotice.parse(
            envelope({field: 'https://example.com'}),
            decrypted: true,
          ) ==
          null,
      field,
    );
  }
  for (final fields in <Map<String, dynamic>>[
    {'version': 2},
    {'version': 1.0},
    {'event_id': ''},
    {'event_id': 'a' * 65},
    {'event_id': 'https://example.com'},
    {'category': 'custom'},
    {'summary': 'https://example.com'},
    {'summary': 'Private arbitrary text'},
  ]) {
    check(
      PushNotice.parse(envelope(fields), decrypted: true) == null,
      'invalid field',
    );
  }
  for (final raw in ['[]', '{}', 'null', '{', '"text"']) {
    check(
      PushNotice.parse(Uint8List.fromList(utf8.encode(raw)), decrypted: true) ==
          null,
      'shape',
    );
  }
  final receiver = PushNoticeReceiver();
  check(receiver.receive('scope_1', envelope(), decrypted: true), 'first');
  check(!receiver.receive('scope_1', envelope(), decrypted: true), 'duplicate');
  check(
    receiver.receive('scope_2', envelope(), decrypted: true),
    'separate scope',
  );
  for (var i = 0; i < 257; i++) {
    check(
      receiver.receive(
        'scope_3',
        envelope({'event_id': 'event_$i'}),
        decrypted: true,
      ),
      'bounded',
    );
  }
  // ignore: avoid_print
  print('Closed parser and scoped dedupe checks passed');
}

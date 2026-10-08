import 'package:flutter_test/flutter_test.dart';
import 'push_notice_check.dart' as checks;
import 'package:hermes_mobile/domain/notifications/push_notice.dart';

class RecordingNotifier implements GenericPushNotifier {
  final calls = <String>[];
  @override
  void show({required String title, required String body}) {
    calls.add('$title: $body');
  }
}

void main() {
  test('notifier receives generic local text only', () {
    final notifier = RecordingNotifier();
    final receiver = PushNoticeReceiver(notifier: notifier);
    receiver.receive('scope', checks.envelope(), decrypted: true);
    receiver.receive('scope', checks.envelope(), decrypted: true);
    expect(notifier.calls, ['Hermes: Novo aviso operacional']);
  });
  test(
    'strict payload validation and bounded scoped event_id dedupe',
    checks.main,
  );
}

import 'package:flutter/foundation.dart';
import 'push_controller.dart';
import 'push_store.dart';
import 'unifiedpush_adapter.dart';

final pushRuntime = PushController(
  adapter: OfficialPushAdapter(),
  store: const SecurePushStore(),
  android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

final _foregroundStarts = Expando<Future<void>>();
final _foregroundStartFailed = Expando<bool>();

/// App startup and controls share initialization, without requesting consent.
/// A failed startup is not cached, so reopening can retry transient plugin/storage
/// failures without requiring a process restart.
Future<void> startPushForeground(PushController controller) {
  if (!controller.android) return Future.value();
  final cached = _foregroundStarts[controller];
  if (cached != null && _foregroundStartFailed[controller] != true) {
    return cached;
  }
  _foregroundStartFailed[controller] = false;
  final attempt = controller.start();
  _foregroundStarts[controller] = attempt;
  return attempt.whenComplete(() {
    if (!controller.startupHealthy) _foregroundStartFailed[controller] = true;
  });
}

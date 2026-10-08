import 'package:flutter/foundation.dart';
import 'push_controller.dart';
import 'push_store.dart';
import 'unifiedpush_adapter.dart';

final pushRuntime = PushController(
  adapter: OfficialPushAdapter(),
  store: const SecurePushStore(),
  android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

/// Normal startup can only restore explicit consent; headless never registers.
Future<void> bootstrapPush(
  List<String> args,
  PushController controller,
  Future<void> Function() normalApp,
) async {
  final background = args.contains('--unifiedpush-bg');
  await controller.start(background: background);
  if (!background) await normalApp();
}

final _foregroundStarts = Expando<Future<void>>();
final _foregroundStartFailed = Expando<bool>();

/// Opening controls initializes the receiver once, without requesting consent.
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

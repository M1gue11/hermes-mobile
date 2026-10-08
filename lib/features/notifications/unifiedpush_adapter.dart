import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';

class PushCallbacks {
  const PushCallbacks({
    required this.endpoint,
    required this.failed,
    required this.unregistered,
    required this.message,
    required this.unavailable,
  });
  final void Function(PushEndpoint, String) endpoint;
  final void Function(FailedReason, String) failed;
  final void Function(String) unregistered;
  final void Function(PushMessage, String) message;
  final void Function(String) unavailable;
}

abstract interface class PushAdapter {
  Future<bool> initialize(PushCallbacks callbacks);
  Future<List<String>> distributors();
  Future<String?> distributor();
  Future<bool> useDefault();
  Future<void> select(String distributor);
  Future<void> register();
  Future<void> unregister();
}

/// All package calls live here, never in widgets.
class OfficialPushAdapter implements PushAdapter {
  static const instance = 'hermes-operational-v1';
  UnifiedPushPlatform get _platform => UnifiedPushPlatform.instance;

  bool _callbacksInstalled = false;

  // Keep callbacks synchronous and nonthrowing at the native channel boundary.
  void _guard(void Function() callback) {
    try {
      callback();
    } catch (_) {
      /* Never log callback data. */
    }
  }

  @override
  Future<bool> initialize(PushCallbacks callbacks) async {
    if (!_callbacksInstalled) {
      await _platform.initializeCallback(
        onNewEndpoint: (e, i) => _guard(() => callbacks.endpoint(e, i)),
        onRegistrationFailed: (r, i) => _guard(() => callbacks.failed(r, i)),
        onUnregistered: (i) => _guard(() => callbacks.unregistered(i)),
        onMessage: (m, i) => _guard(() => callbacks.message(m, i)),
      );
      await _platform.initializeOnTempUnavailable(
        (i) => _guard(() => callbacks.unavailable(i)),
      );
      _callbacksInstalled = true;
    }
    return await _platform.getDistributor() != null;
  }

  @override
  Future<List<String>> distributors() => _platform.getDistributors(const []);
  @override
  Future<String?> distributor() => _platform.getDistributor();
  @override
  Future<bool> useDefault() => _platform.tryUseCurrentOrDefaultDistributor();
  @override
  Future<void> select(String distributor) =>
      _platform.saveDistributor(distributor);
  @override
  Future<void> register() => _platform.register(instance, const [], null, null);
  @override
  Future<void> unregister() => _platform.unregister(instance);
}

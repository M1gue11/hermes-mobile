import 'package:flutter_test/flutter_test.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'push_notice_check.dart' show envelope;
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:hermes_mobile/features/notifications/unifiedpush_adapter.dart';

/// Fake at the official platform boundary; no top-level Linux dependency.
class RecordingPlatform extends DefaultUnifiedPush {
  void Function(PushMessage, String)? message;
  void Function(PushEndpoint, String)? endpoint;
  void Function(FailedReason, String)? failed;
  void Function(String)? unregistered;
  void Function(String)? unavailable;
  @override
  Future<void> initializeCallback({
    void Function(PushEndpoint, String)? onNewEndpoint,
    void Function(FailedReason, String)? onRegistrationFailed,
    void Function(String)? onUnregistered,
    void Function(PushMessage, String)? onMessage,
  }) async {
    endpoint = onNewEndpoint;
    failed = onRegistrationFailed;
    unregistered = onUnregistered;
    message = onMessage;
  }

  @override
  Future<void> initializeOnTempUnavailable(
    void Function(String)? callback,
  ) async {
    unavailable = callback;
  }

  String? saved;
  String? registeredInstance;
  String? unregisteredInstance;
  List<String>? features;
  String? distributorMessage;
  String? vapidKey;
  @override
  Future<List<String>> getDistributors(List<String> features) async => [
    'com.example.distributor',
  ];
  @override
  Future<String?> getDistributor() async => saved;
  @override
  Future<void> saveDistributor(String distributor) async {
    saved = distributor;
  }

  @override
  Future<bool> tryUseCurrentOrDefaultDistributor() async {
    saved = 'com.example.distributor';
    return true;
  }

  @override
  Future<void> register(
    String instance,
    List<String> features,
    String? messageForDistributor,
    String? vapid,
  ) async {
    registeredInstance = instance;
    this.features = features;
    distributorMessage = messageForDistributor;
    vapidKey = vapid;
  }

  @override
  Future<void> unregister(String instance) async {
    unregisteredInstance = instance;
  }
}

void main() {
  test('initialize false/true and every callback is nonthrowing', () async {
    final previous = UnifiedPushPlatform.instance;
    final platform = RecordingPlatform();
    UnifiedPushPlatform.instance = platform;
    addTearDown(() => UnifiedPushPlatform.instance = previous);
    var calls = 0;
    void failure() {
      calls++;
      throw StateError('neutral');
    }

    final callbacks = PushCallbacks(
      endpoint: (_, _) => failure(),
      failed: (_, _) => failure(),
      unregistered: (_) => failure(),
      message: (_, _) => failure(),
      unavailable: (_) => failure(),
    );
    final adapter = OfficialPushAdapter();
    expect(await adapter.initialize(callbacks), false);
    platform.saved = 'com.example.distributor';
    expect(await adapter.initialize(callbacks), true);
    expect(
      () => platform.message!(
        PushMessage(envelope(), true),
        OfficialPushAdapter.instance,
      ),
      returnsNormally,
    );
    expect(
      () => platform.endpoint!(
        PushEndpoint('https://example.com', null, temporary: true),
        OfficialPushAdapter.instance,
      ),
      returnsNormally,
    );
    expect(
      () => platform.failed!(
        FailedReason.actionRequired,
        OfficialPushAdapter.instance,
      ),
      returnsNormally,
    );
    expect(
      () => platform.unregistered!(OfficialPushAdapter.instance),
      returnsNormally,
    );
    expect(
      () => platform.unavailable!(OfficialPushAdapter.instance),
      returnsNormally,
    );
    expect(calls, 5);
  });
  test(
    'official adapter passes named register defaults and same revoke instance',
    () async {
      final previous = UnifiedPushPlatform.instance;
      final platform = RecordingPlatform();
      UnifiedPushPlatform.instance = platform;
      addTearDown(() {
        UnifiedPushPlatform.instance = previous;
      });
      final adapter = OfficialPushAdapter();
      expect(await adapter.distributors(), ['com.example.distributor']);
      await adapter.select('com.example.distributor');
      expect(await adapter.distributor(), 'com.example.distributor');
      expect(await adapter.useDefault(), true);
      await adapter.register();
      expect(platform.registeredInstance, OfficialPushAdapter.instance);
      expect(platform.features, isEmpty);
      expect(platform.distributorMessage, null);
      expect(platform.vapidKey, null);
      await adapter.unregister();
      expect(platform.unregisteredInstance, OfficialPushAdapter.instance);
    },
  );
}

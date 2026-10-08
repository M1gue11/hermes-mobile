import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidFlutterLocalNotificationsPlugin;
// Use the official transitive interface to preserve plugin registration state.
// ignore: depend_on_referenced_packages
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/features/notifications/android_push_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  String? failAt;
  bool enabled = true;
  bool initialized = true;
  bool missing = false;
  late FlutterLocalNotificationsPlatform previousPlatform;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    previousPlatform = FlutterLocalNotificationsPlatform.instance;
    calls.clear();
    failAt = null;
    enabled = initialized = true;
    missing = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (missing) throw MissingPluginException('private native detail');
          if (call.method == failAt) {
            throw PlatformException(code: 'denied', message: 'private detail');
          }
          if (call.method == 'initialize') return initialized;
          if (call.method == 'areNotificationsEnabled') return enabled;
          return null;
        });
  });
  tearDown(() {
    FlutterLocalNotificationsPlatform.instance = previousPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'official initialize/channel/show use fixed values and no payload',
    () async {
      final sink = AndroidPushNotifier(platform: TargetPlatform.android);
      sink.show(
        title: 'private arbitrary title',
        body: 'https://private.example',
      );
      await sink.pending;
      expect(calls.map((c) => c.method), [
        'initialize',
        'createNotificationChannel',
        'areNotificationsEnabled',
        'show',
      ]);
      expect(calls.first.arguments, {'defaultIcon': 'ic_stat_hermes'});
      final setup = calls[1].arguments as Map;
      expect(setup['id'], 'hermes_operational_v1');
      final show = calls.last.arguments as Map;
      expect(show['id'], 1);
      expect(show['title'], 'Hermes');
      expect(show['body'], 'Novo aviso operacional');
      // Official Android implementation serializes absent payload as empty string.
      expect(show['payload'], '');
      expect(show.toString(), isNot(contains('private')));
      expect((show['platformSpecifics'] as Map)['channelId'], setup['id']);
      await sink.display();
      expect(calls.where((c) => c.method == 'initialize'), hasLength(1));
    },
  );

  test('permission denied never requests permission or displays', () async {
    enabled = false;
    await AndroidPushNotifier(platform: TargetPlatform.android).display();
    expect(calls.map((c) => c.method), [
      'initialize',
      'createNotificationChannel',
      'areNotificationsEnabled',
    ]);
  });
  test('unsupported platforms never call plugin', () async {
    for (final platform in TargetPlatform.values) {
      if (platform == TargetPlatform.android) continue;
      debugDefaultTargetPlatformOverride = platform;
      await AndroidPushNotifier(platform: platform).display();
    }
    expect(calls, isEmpty);
  });
  test('false initialization prevents display', () async {
    initialized = false;
    await AndroidPushNotifier(platform: TargetPlatform.android).display();
    expect(calls.map((c) => c.method), ['initialize']);
  });
  test(
    'missing plugin is swallowed including synchronous receiver path',
    () async {
      missing = true;
      final sink = AndroidPushNotifier(platform: TargetPlatform.android);
      sink.show(title: 'secret', body: 'secret');
      await sink.pending;
      expect(calls.map((c) => c.method), ['initialize']);
    },
  );
  for (final method in [
    'initialize',
    'createNotificationChannel',
    'areNotificationsEnabled',
    'show',
  ]) {
    test('$method failure is redacted and a later call can retry', () async {
      failAt = method;
      final sink = AndroidPushNotifier(platform: TargetPlatform.android);
      await sink.display();
      expect(calls.last.method, method);
      failAt = null;
      await sink.display();
      expect(calls.last.method, 'show');
    });
  }
}

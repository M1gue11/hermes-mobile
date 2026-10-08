import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/notifications/push_notice.dart';

/// Engine-attached official plugin APIs only; no Activity or permission request.
/// The controller must enforce consent and server enrollment before receiving.
class AndroidPushNotifier implements GenericPushNotifier {
  AndroidPushNotifier({this.platform});

  @visibleForTesting
  final TargetPlatform? platform;
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _initialization;
  Future<void> _pending = Future.value();

  static const _channel = AndroidNotificationChannel(
    'hermes_operational_v1',
    'Hermes',
    importance: Importance.high,
  );

  Future<bool> _initialize() async {
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_hermes'),
      ),
    );
    if (initialized != true) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    await android.createNotificationChannel(_channel);
    return true;
  }

  /// Exposed Future also lets callers/tests await the safe display boundary.
  /// Parameters from the domain interface are deliberately never forwarded.
  Future<void> display() async {
    if (kIsWeb ||
        (platform ?? defaultTargetPlatform) != TargetPlatform.android) {
      return;
    }
    try {
      if (!await (_initialization ??= _initialize())) {
        _initialization = null;
        return;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (await android?.areNotificationsEnabled() != true) return;
      await _plugin.show(
        id: 1,
        title: 'Hermes',
        body: 'Novo aviso operacional',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'hermes_operational_v1',
            'Hermes',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
          ),
        ),
      );
    } catch (_) {
      // Includes missing plugin, denied permissions and channel/display errors.
      // Never log exception text, payloads or native error details.
      _initialization = null;
    }
  }

  @override
  void show({required String title, required String body}) {
    _pending = _pending.then((_) => display());
    unawaited(_pending);
  }

  @visibleForTesting
  Future<void> get pending => _pending;
}

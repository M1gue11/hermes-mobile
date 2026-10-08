import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show DartPluginRegistrant, RootIsolateToken;
import 'push_runtime.dart';

/// Called by the default app main before any widget or connection bootstrap.
@pragma('vm:entry-point')
Future<void> bootstrapPushHeadless() async {
  _HeadlessBinding();
  // A service-created FlutterEngine runs a root isolate: its generated Dart
  // registrant is invoked by the engine. The official API forbids calling
  // ensureInitialized on that root; use it only on a secondary isolate.
  if (RootIsolateToken.instance == null) {
    DartPluginRegistrant.ensureInitialized();
  }
  await pushRuntime.start(background: true);
}

class _HeadlessBinding extends BindingBase
    with SchedulerBinding, ServicesBinding {}

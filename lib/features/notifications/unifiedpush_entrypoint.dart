import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show DartPluginRegistrant;
import 'push_runtime.dart';

/// Headless-only experimental build target. Native service currently launches
/// the compiled default main, so this is NOT selected by the normal app build.
@pragma('vm:entry-point')
Future<void> main(List<String> args) async {
  _HeadlessBinding();
  DartPluginRegistrant.ensureInitialized();
  await pushRuntime.start(background: true);
}

class _HeadlessBinding extends BindingBase
    with SchedulerBinding, ServicesBinding {}
